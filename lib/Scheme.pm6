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

multi sub evaluate($ast) is export {
    my $env = Scheme::Environment.get-global-environment();

    execute $ast, $env;
}
multi sub evaluate(Match $m) is export {
    evaluate $m.made;
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

multi sub execute($any where { not .does: Scheme::AST }, $env) {
    return $any;
}
multi sub execute($any where { .does: Scheme::AST }, $env) {
    die "execution of { $any.^name } not yet implemented";
}
