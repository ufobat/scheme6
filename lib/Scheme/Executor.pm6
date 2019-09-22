use v6.c;

unit class Scheme::Executor;

use Scheme::AST;
use Scheme::Environment;

has Scheme::Environment $.env is required;

multi method execute(Scheme::AST::Expressions $ast, $env = $.env) {
    for $ast.expressions {
        my $x = self.execute: $_, $env;
        LAST { return $x }
    }
}

multi method execute(Scheme::AST::ProcCall $ast, $env = $.env) {
    my &proc = $ast.identifier
    ?? $env.lookup($ast.identifier)
    !! self.execute($ast.lambda, $env);
    proc |$ast.expressions.map: {
        self.execute: $_, $env;
    };
}

multi method execute(Scheme::AST::Set $ast, $env = $.env) {
    my $val = self.execute($ast.expression, $env);
    $env.update: $ast.identifier => $val;
}
multi method execute(Scheme::AST::Definition $ast, $env = $.env) {
    my $val = self.execute($ast.expression, $env);
    $env.set: $ast.identifier => $val;
}
multi method execute(Scheme::AST::Symbol $ast, $env = $.env) {
    my $var = $env.lookup($ast.identifier);
    if $var ~~ Positional {
        return eager flat $var;
    }
    return $var;
}
multi method execute(Scheme::AST::Lambda $ast, $env = $.env) {
    sub (*@a) {
        my $scope = $env.make-new-scope();
        for |$ast.params -> $name {
            $scope.set: $name => shift @a
        }

        for $ast.expressions {
            my $x = self.execute: $_, $scope;
            LAST { return $x }
        }
    }
}
multi method execute(Scheme::AST::Conditional $ast, $env = $.env) {
    my $val = self.execute($ast.expression, $env);
    self.execute($val ?? $ast.conseq !! $ast.alt, $env);
}
multi method execute(Scheme::AST::Quote $ast, $env = $.env) {
    return $ast.datum;
}
multi method execute(Scheme::AST::Macro $ast, $env) {
    # macro AST definitions are processed at parsing
    # they wont be executed
}

multi method execute($any where { not .does: Scheme::AST }, $env = $.env) {
    return $any;
}
multi method execute($any where { .does: Scheme::AST }, $env = $.env) {
    die "execution of { $any.^name } not yet implemented";
}


