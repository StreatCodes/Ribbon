const std = @import("std");
const parser = @import("parser.zig");
const TokenKind = parser.TokenKind;
const sliceIterator = @import("sliceIterator.zig");

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
};

pub const AST = struct {
    arena: std.heap.ArenaAllocator,

    text: []u8,
    tokens: []parser.Token,

    pub fn init(allocator: std.mem.Allocator, text: []u8, tokens: []parser.Token) AST {
        return AST{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .text = text,
            .tokens = tokens,
        };
    }

    pub fn deinit(self: *AST) void {
        self.arena.deinit();
    }

    pub fn generateModule(self: *AST) !Module {
        const allocator = self.arena.allocator();
        var children = std.ArrayList(ModuleChildren).init(allocator);

        var tokenIter = sliceIterator.Iterator(parser.Token){ .data = self.tokens };

        while (tokenIter.next()) |token| {
            const value = self.text[token.start .. token.end + 1];
            switch (token.kind) {
                TokenKind.KeyWord => {
                    if (std.mem.eql(u8, value, "fn")) {
                        std.debug.print("Found fn\n", .{});
                        var func = try self.generateFunction(&tokenIter);
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

    fn generateFunction(self: *AST, tokenIter: *sliceIterator.Iterator(parser.Token)) !FunctionDecleration {
        var token = tokenIter.next() orelse return ASTError.ExpectedToken;
        // switch(token.kind) {
        //     TokenKind.
        // }
        const value = self.text[token.start .. token.end + 1];
        std.debug.print("{s}\n", .{value});

        return FunctionDecleration{
            .start = 0,
            .end = 0,
            .id = Identifier{
                .start = 0,
                .end = 0,
                .type = "", //TODO
                .name = "",
            },
            .params = &[_]Identifier{},
            .body = Block{
                .start = 0,
                .end = 0,
                .body = &[_]BlockChildren{},
            },
        };
    }
};
