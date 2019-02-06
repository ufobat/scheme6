use Scheme::AST;
use Scheme::Grammar;
use Scheme::Action;

unit module Scheme;

class Scheme::Environment {
    has %.map;

    method load-build-ins {
        %.map<+>       = sub (*@a) { [+] @a };
        %.map<->       = sub (*@a) { [-] @a };
        %.map<*>       = sub (*@a) { [*] @a };
        %.map</>       = sub (*@a) { [/] @a };
        %.map<sqrt>    = sub ($a)  { sqrt($a) };
        %.map<display> = sub ($a)  { say $a };
    }
    method lookup(Str $key) {
        die "'$key' not found" unless %.map{$key}:exists;
        return %.map{$key};
    }
    method set(Pair $p) {
        %.map{$p.key} = $p.value;
    }
}

sub parse(Str $program) is export {
    my $match = Scheme::Grammar.parse($program, actions => Scheme::Action);
    die unless $match;
    return $match
}

multi sub evaluate($ast) is export {
    my $env = Scheme::Environment.new;
    $env.load-build-ins;

    execute($ast, $env);
}
multi sub evaluate(Match $m) is export {
    evaluate($m.made);
}

multi sub execute(Scheme::AST::Expressions $ast, $env) {
    for $ast.expressions {
        my $x = execute($_, $env);
        LAST { return $x }
    }
}

multi sub execute(Scheme::AST::ProcCall $ast, $env) {
    my &proc = $env.lookup($ast.identifier);
    proc |$ast.expressions.map: {
        execute($_, $env)
    };
}
multi sub execute(Scheme::AST::Definition $ast, $env) {
    my $val = execute($ast.expression, $env);
    say "adding {$ast.identifier} -> $val";
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
