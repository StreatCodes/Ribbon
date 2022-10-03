const Identifier = struct {
    start: usize,
    end: usize,
    type: []u8, //TODO
    name: []u8,
};

const VariableDecleration = struct {
    start: usize,
    end: usize,
    id: Identifier,
};

const FunctionDecleration = struct {
    start: usize,
    end: usize,
    name: []u8,
};

const Module = struct {
    start: usize,
    end: usize,
    children: union {
        VariableDecleration: VariableDecleration,
        FunctionDecleration: FunctionDecleration,
    },
};

pub fn generateAST(tokens: []Token) !Module {}
