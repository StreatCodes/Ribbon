const std = @import("std");

pub const TokenKind = enum {
    Start,
    KeyWord,
    BuiltInType,
    Identifier,
    String,
    Number,
    Assignment,
    OpenParentheses,
    CloseParenthese,
    OpenBrace,
    CloseBrace,
    Colon,
    WhiteSpace,
    Add,
    Subtract,
    Unknown,
};

const keywords = [_][]const u8{ "let", "fn" };
const builtInTypes = [_][]const u8{ "void", "string", "i32", "i64", "f32", "f64" };

fn isKeyword(phrase: []u8) bool {
    for (keywords) |keyword| {
        if (std.mem.eql(u8, phrase, keyword[0..])) {
            return true;
        }
    }
    return false;
}

fn isBuiltInType(phrase: []u8) bool {
    for (builtInTypes) |builtIn| {
        if (std.mem.eql(u8, phrase, builtIn[0..])) {
            return true;
        }
    }
    return false;
}

fn isWhiteSpace(c: u8) bool {
    if (c == ' ' or c == '\t' or c == '\r' or c == '\n') return true;
    return false;
}

pub const Token = struct {
    kind: TokenKind,
    start: usize,
    end: usize,

    pub fn value(self: *const Token, text: []u8) []u8 {
        return text[self.start .. self.end + 1];
    }
};

fn nextToken(text: []u8, start: usize) Token {
    var current = TokenKind.Start;
    var i = start;

    while (i < text.len) {
        const c = text[i];

        switch (current) {
            TokenKind.Start => blk: {
                if (std.ascii.isAlpha(c)) {
                    current = TokenKind.Identifier;
                    break :blk;
                }
                if (isWhiteSpace(c)) {
                    current = TokenKind.WhiteSpace;
                    break :blk;
                }
                if (c == '"') {
                    current = TokenKind.String;
                    break :blk;
                }
                if (c == ':') {
                    return Token{ .kind = TokenKind.Colon, .start = start, .end = i };
                }
                if (c == '+') {
                    return Token{ .kind = TokenKind.Add, .start = start, .end = i };
                }
                if (c == '-') {
                    return Token{ .kind = TokenKind.Subtract, .start = start, .end = i };
                }
                if (c == '(') {
                    return Token{ .kind = TokenKind.OpenParentheses, .start = start, .end = i };
                }
                if (c == ')') {
                    return Token{ .kind = TokenKind.CloseParenthese, .start = start, .end = i };
                }
                if (c == '{') {
                    return Token{ .kind = TokenKind.OpenBrace, .start = start, .end = i };
                }
                if (c == '}') {
                    return Token{ .kind = TokenKind.CloseBrace, .start = start, .end = i };
                }
                if (c == '=') {
                    return Token{ .kind = TokenKind.Assignment, .start = start, .end = i };
                }
                return Token{ .kind = TokenKind.Unknown, .start = start, .end = i };
            },
            TokenKind.Identifier => blk: {
                if (std.ascii.isAlpha(c)) {
                    if (isKeyword(text[start .. i + 1])) {
                        current = TokenKind.KeyWord;
                    }
                    if (isBuiltInType(text[start .. i + 1])) {
                        current = TokenKind.BuiltInType;
                    }
                    break :blk;
                }
                return Token{ .kind = TokenKind.Identifier, .start = start, .end = i - 1 };
            },
            TokenKind.KeyWord => blk: {
                if (std.ascii.isAlpha(c)) {
                    if (isBuiltInType(text[start .. i + 1])) {
                        current = TokenKind.BuiltInType;
                        break :blk;
                    }
                    if (!isKeyword(text[start .. i + 1])) {
                        current = TokenKind.Identifier;
                        break :blk;
                    }
                    break :blk;
                }
                return Token{ .kind = TokenKind.KeyWord, .start = start, .end = i - 1 };
            },
            TokenKind.BuiltInType => blk: {
                if (std.ascii.isAlpha(c)) {
                    if (isKeyword(text[start .. i + 1])) {
                        current = TokenKind.KeyWord;
                        break :blk;
                    }
                    if (!isBuiltInType(text[start .. i + 1])) {
                        current = TokenKind.Identifier;
                        break :blk;
                    }
                    break :blk;
                }
                return Token{ .kind = TokenKind.BuiltInType, .start = start, .end = i - 1 };
            },
            TokenKind.String => {
                //TODO handle escaping quotes and backslashes
                if (c == '"') {
                    return Token{ .kind = TokenKind.String, .start = start, .end = i };
                }
            },
            TokenKind.WhiteSpace => {
                if (!isWhiteSpace(c)) {
                    return Token{ .kind = TokenKind.WhiteSpace, .start = start, .end = i - 1 };
                }
            },
            else => {
                unreachable;
            },
        }

        i += 1;
    }

    return Token{ .kind = current, .start = start, .end = i };
}

const ParseError = error{
    UnexpectedToken,
};

pub const TokenIterator = struct {
    tokens: []Token,
    index: usize = 0,

    pub fn deinit(self: *TokenIterator, allocator: std.mem.Allocator) void {
        allocator.free(self.tokens);
    }

    pub fn reset(self: *TokenIterator) void {
        self.index = 0;
    }

    pub fn current(self: *TokenIterator) Token {
        return self.tokens[self.index];
    }

    pub fn next(self: *TokenIterator) ?Token {
        const nextIndex = self.index + 1;
        if (nextIndex < self.tokens.len) {
            self.index = nextIndex;
            return self.tokens[nextIndex];
        }
        return null;
    }

    pub fn peek(self: *TokenIterator) ?Token {
        const nextIndex = self.index + 1;
        if (nextIndex < self.tokens.len) {
            return self.tokens[nextIndex];
        }
        return null;
    }
    
    pub fn peekAt(self: *TokenIterator, count: usize) ?Token {
        const peekIndex = self.index + count;
        if (peekIndex < self.tokens.len) {
            return self.tokens[peekIndex];
        }
        return null;
    }

    pub fn consume(self: *TokenIterator, kind: TokenKind) !void {
        const nextT = self.peek() orelse return ParseError.UnexpectedToken;

        if (nextT.kind != kind) {
            return ParseError.UnexpectedToken;
        }
        self.index += 1;
    }
};

pub fn parse(allocator: std.mem.Allocator, text: []u8) !TokenIterator {
    var start: usize = 0;

    var tokens = std.ArrayList(Token).init(allocator);

    while (start < text.len) {
        var token = nextToken(text, start);

        //ignore whitespace tokens
        if (token.kind != TokenKind.WhiteSpace) {
            try tokens.append(token);
        }
        start = token.end + 1;
    }

    return .{ .tokens = tokens.toOwnedSlice() };
}
