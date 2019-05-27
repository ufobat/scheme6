role Scheme::AST {
    has $.context is required;
}
class Scheme::AST::Expressions does Scheme::AST {
    has @.expressions is required;
}

class Scheme::AST::ProcCall does Scheme::AST {
    has Str $.identifier;
    has $.lambda;
    has @.expressions is required;

    submethod TWEAK {
        die '$.identifier or $.lambda is required' unless $!identifier or $!lambda;
    }
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

class Scheme::AST::Lambda does Scheme::AST {
    has @.params is required;
    has @.expressions is required;
}

class Scheme::AST::Quote does Scheme::AST {
    has $.datum is required;
}

class Scheme::AST::Macro does Scheme::AST {
    has $.identifier is required;
    has @.transformer-spec is required;
}

class Scheme::AST::TransformerSpec does Scheme::AST {
    has @.literals is required;
    has @.source is required;
    has $.destination is required;
}
