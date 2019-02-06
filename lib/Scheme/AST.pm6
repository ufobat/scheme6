role Scheme::AST { }

class Scheme::AST::Expressions does Scheme::AST {
    has @.expressions is required;
}

class Scheme::AST::ProcCall does Scheme::AST {
    has Str $.identifier is required;
    has @.expressions is required;
}

class Scheme::AST::Conditional does Scheme::AST {
    has $.expression is required;
    has $.conseq is required;
    has $.alt is required;
}

class Scheme::AST::Definition does Scheme::AST {
    has $.identifier is required;
    has $.expression is required;
}

class Scheme::AST::Variable does Scheme::AST {
    has $.identifier is required;
}
