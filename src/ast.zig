const std = @import("std");
const parser = @import("parser.zig");
const TokenKind = parser.TokenKind;

const Literal = struct {
    start: usize,
    end: usize,
    value: []u8,
};

const Identifier = struct {
    start: usize,
    end: usize,
    type: []u8, //TODO
    name: []u8,
};

const Assignable = union(enum) {
    literal: Literal,
    identifier: Identifier,
};

const VariableDecleration = struct {
    start: usize,
    end: usize,
    id: Identifier,
    init: Assignable,
};

const CallExpression = struct {
    start: usize,
    end: usize,
    callee: Identifier,
    arguments: []Identifier,
};

const LogicalExpression = struct {
    start: usize,
    end: usize,
    left: Assignable,
    right: Assignable,
    operator: []u8, //TODO list
};

const Expressions = union(enum) {
    callExpression: CallExpression,
    logicalExpression: LogicalExpression,
};

const ReturnStatement = struct {
    start: usize,
    end: usize,
    argument: Assignable,
};

const BlockChildren = union(enum) {
    variableDecleration: VariableDecleration,
    expression: Expressions,
    returnStatement: ReturnStatement,
};

const Block = struct {
    start: usize,
    end: usize,
    body: []BlockChildren,
};

const FunctionDecleration = struct {
    start: usize,
    end: usize,
    id: Identifier,
    params: []Identifier,
    body: Block,
};

const ModuleChildren = union(enum) {
    // variableDecleration: VariableDecleration,
    functionDecleration: FunctionDecleration,
};

const Module = struct {
    start: usize,
    end: usize,
    children: []ModuleChildren,
};

const ASTError = error{
    ExpectedToken,
    UnexpectedToken,
    NotImplemented,
};

pub const AST = struct {
    arena: std.heap.ArenaAllocator,

    text: []u8,
    tokenIter: *parser.TokenIterator,

    pub fn init(allocator: std.mem.Allocator, text: []u8, tokenIter: *parser.TokenIterator) AST {
        return AST{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .text = text,
            .tokenIter = tokenIter,
        };
    }

    pub fn deinit(self: *AST) void {
        self.arena.deinit();
    }

    pub fn generateModule(self: *AST) !Module {
        const allocator = self.arena.allocator();
        var children = std.ArrayList(ModuleChildren).init(allocator);

        while (self.tokenIter.next()) |token| {
            switch (token.kind) {
                TokenKind.KeyWord => {
                    if (std.mem.eql(u8, token.value(self.text), "fn")) {
                        var func = try self.generateFunction();
                        try children.append(ModuleChildren{ .functionDecleration = func });
                    }
                },
                else => {
                    std.debug.print("Unexpected token: {any}\n", .{token});
                },
            }
        }

        return Module{
            .start = 0,
            .end = self.text.len, //TODO +1 ??
            .children = children.toOwnedSlice(),
        };
    }

    fn generateFunction(self: *AST) !FunctionDecleration {
        var identifier = self.tokenIter.next() orelse return ASTError.ExpectedToken;
        if (identifier.kind != TokenKind.Identifier) return ASTError.UnexpectedToken;
        var params = std.ArrayList(Identifier).init(self.arena.allocator());

        //Loop through params
        try self.tokenIter.consume(TokenKind.OpenParentheses);
        while (true) {
            if (self.tokenIter.peek()) |next| {
                if (next.kind == TokenKind.CloseParenthese) {
                    break;
                }
            } else {
                return ASTError.ExpectedToken;
            }

            var paramIdentifier = try self.generateIdentifier();
            try params.append(paramIdentifier);
        }
        try self.tokenIter.consume(TokenKind.CloseParenthese);

        //TODO store return type
        try self.tokenIter.consume(TokenKind.Colon);
        try self.tokenIter.consume(TokenKind.BuiltInType); //TODO could be userType

        var body = try self.generateBlock();

        return FunctionDecleration{
            .start = 0,
            .end = 0,
            .id = Identifier{
                .start = identifier.start,
                .end = identifier.end,
                .type = "", //TODO fn?
                .name = identifier.value(self.text),
            },
            .params = params.toOwnedSlice(),
            .body = body,
        };
    }

    fn generateIdentifier(self: *AST) !Identifier {
        var identifier = self.tokenIter.next() orelse return ASTError.ExpectedToken;
        if (identifier.kind != TokenKind.Identifier) {
            return ASTError.UnexpectedToken;
        }
        var result = Identifier{
            .start = identifier.start,
            .end = identifier.end,
            .type = "", //TODO
            .name = identifier.value(self.text),
        };

        var next = self.tokenIter.peek() orelse return result;
        if (next.kind == TokenKind.Colon) {
            try self.tokenIter.consume(TokenKind.Colon);
            var identifierType = self.tokenIter.next() orelse return ASTError.ExpectedToken;
            result.type = identifierType.value(self.text);
            identifier.end = identifierType.end; //TODO not sure if this is advised
        }

        return result;
    }

    fn generateBlock(self: *AST) !Block {
        var children = std.ArrayList(BlockChildren).init(self.arena.allocator());
        const start = self.tokenIter.index;
        try self.tokenIter.consume(TokenKind.OpenBrace);

        //Parse all statements until closing brace
        while (self.tokenIter.peek()) |next| {
            switch (next.kind) {
                TokenKind.CloseBrace => break,
                TokenKind.KeyWord => {
                    if (std.mem.eql(u8, next.value(self.text), "let")) {
                        try children.append(BlockChildren{
                            .variableDecleration = try self.generateVariableDecleration(),
                        });
                    }
                },
                TokenKind.Identifier => {
                    var after = self.tokenIter.peekAt(2) orelse return ASTError.ExpectedToken;
                    switch (after.kind) {
                        TokenKind.OpenParentheses => {
                            try children.append(BlockChildren{
                                .expression = Expressions{
                                    .callExpression = try self.generateCallExpression(),
                                },
                            });
                        },
                        else => return ASTError.NotImplemented,
                    }
                },
                else => {
                    std.debug.print("~~~~~~~~~~~~~{any}\n", .{next.kind});
                    return ASTError.UnexpectedToken;
                },
            }
        }
        try self.tokenIter.consume(TokenKind.CloseBrace);

        return Block{
            .start = start,
            .end = self.tokenIter.index,
            .body = children.toOwnedSlice(),
        };
    }

    fn generateVariableDecleration(self: *AST) !VariableDecleration {
        // consume 'let' for now
        const start = self.tokenIter.index;
        try self.tokenIter.consume(TokenKind.KeyWord);

        var identifier = try self.generateIdentifier();

        try self.tokenIter.consume(TokenKind.Assignment);

        //extract right hand side of assignment
        var next = self.tokenIter.next() orelse return ASTError.ExpectedToken;
        var assignable: Assignable = undefined;
        switch (next.kind) {
            TokenKind.Identifier => return ASTError.NotImplemented,
            TokenKind.Number => return ASTError.NotImplemented,
            TokenKind.String => {
                assignable = Assignable{
                    .literal = Literal{
                        .start = next.start,
                        .end = next.end,
                        .value = next.value(self.text),
                    },
                };
            },
            else => return ASTError.UnexpectedToken,
        }

        return VariableDecleration{
            .start = start,
            .end = self.tokenIter.index,
            .id = identifier,
            .init = assignable,
        };
    }

    fn generateCallExpression(self: *AST) !CallExpression {
        var start = self.tokenIter.index;
        var callee = try self.generateIdentifier();
        try self.tokenIter.consume(TokenKind.OpenParentheses);

        var arguments = std.ArrayList(Identifier).init(self.arena.allocator());

        while (self.tokenIter.peek()) |next| {
            if (next.kind == TokenKind.CloseParenthese) break;

            var arg = try self.generateIdentifier();
            try arguments.append(arg);

            //TODO handle ',' between args
        }

        try self.tokenIter.consume(TokenKind.CloseParenthese);

        return CallExpression{
            .start = start,
            .end = self.tokenIter.index,
            .callee = callee,
            .arguments = arguments.toOwnedSlice(),
        };
    }
};
