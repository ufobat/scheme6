role Scheme::AST { }

class Scheme::AST::Expressions does Scheme::AST {
    has @.expressions is required;

    method clone {
        $?CLASS.new: expressions => @!expressions>>.clone;
    }
}

class Scheme::AST::ProcCall does Scheme::AST {
    has Str $.identifier;
    has $.lambda;
    has @.expressions is required;

    submethod TWEAK {
        die '$.identifier or $.lambda is required' unless $!identifier or $!lambda;
    }

    method clone {
        $?CLASS.new:
        identifier => $!identifier.clone,
        lambda => $!lambda.clone,
        expressions => @!expressions>>.clone;
    }
}

class Scheme::AST::Conditional does Scheme::AST {
    has $.expression is required;
    has $.conseq is required;
    has $.alt is required;

    method clone {
        $?CLASS.new:
        expression => $!expression.clone,
        conseq => $!conseq.clone,
        alt => $!alt.clone;
    }
}

class Scheme::AST::Definition does Scheme::AST {
    has $.identifier is required;
    has $.expression is required;

    method clone {
        $?CLASS.new:
        identifier => $!identifier.clone,
        expression => $!expression.clone;
    }
}

class Scheme::AST::Variable does Scheme::AST {
    has $.identifier is required;

    method clone {
        # creates a failure if dynamic variable is not known
        %*AST-REPLACE{ $!identifier } //
        $?CLASS.new:
        identifier => $!identifier.clone,
    }
}

class Scheme::AST::Lambda does Scheme::AST {
    has @.params is required;
    has @.expressions is required;

    method clone {
        $?CLASS.new:
        params => @!params>>.clone,
        expressions => @!expressions>>.clone;
    }
}

class Scheme::AST::Quote does Scheme::AST {
    has $.datum is required;
    method clone {
        $?CLASS.new:
        datum => $!datum.clone;
    }
}

class Scheme::AST::Macro does Scheme::AST {
    has $.name is required;
    has @.transformer-spec is required;
    method clone {
        $?CLASS.new:
        name => $!name.clone,
        transformer-spec => @!transformer-spec>>.clone;
    }
}

class Scheme::AST::TransformerSpec does Scheme::AST {
    has @.literals is required;
    has @.source is required;
    has $.destination is required;

    method clone {
        $?CLASS.new:
        literals => @!literals>>.clone,
        source => @!source>>.clone,
        destination => $!destination.clone,
    }
}
