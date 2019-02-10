use Scheme::AST;
use Scheme::Grammar;
use Scheme::Action;
use Scheme::Environment;

unit module Scheme;


sub parse(Str $program) is export {
    my $match = Scheme::Grammar.parse($program, actions => Scheme::Action);
    die unless $match;
    return $match
}

sub environment() is export {
    return Scheme::Environment.get-global-environment();
}

multi sub evaluate($ast, :$env = environment() ) is export {
    execute $ast, $env;
}
multi sub evaluate(Match $m, :$env = environment() ) is export {
    evaluate $m.made, :$env;
}

multi sub execute(Scheme::AST::Expressions $ast, $env) {
    for $ast.expressions {
        my $x = execute $_, $env;
        LAST { return $x }
    }
}

multi sub execute(Scheme::AST::ProcCall $ast, $env) {
    my &proc = $env.lookup($ast.identifier);
    proc |$ast.expressions.map: {
        execute $_, $env;
    };
}
multi sub execute(Scheme::AST::Definition $ast, $env) {
    my $val = execute($ast.expression, $env);
    $env.set: $ast.identifier => $val;
}
multi sub execute(Scheme::AST::Variable $ast, $env) {
    return $env.lookup($ast.identifier);
}
multi sub execute(Scheme::AST::Lambda $ast, $env) {
    my $scope = $env.make-new-scope();
    sub (*@a) {
        for |$ast.params -> $name {
            $scope.set: $name => shift @a
        }

        for $ast.expressions {
            my $x = execute $_, $scope;
            LAST { return $x }
        }
    }
}
multi sub execute(Scheme::AST::Conditional $ast, $env) {
    my $val = execute($ast.expression, $env);
    execute($val ?? $ast.conseq !! $ast.alt, $env);
}
multi sub execute(Scheme::AST::Quote $ast, $env) {
    return $ast.datum;
}

multi sub execute($any where { not .does: Scheme::AST }, $env) {
    return $any;
}
multi sub execute($any where { .does: Scheme::AST }, $env) {
    die "execution of { $any.^name } not yet implemented";
}
