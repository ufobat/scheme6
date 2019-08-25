use v6.c;

unit class Scheme::Executor;

use Scheme::AST;
use Scheme::Environment;

role Thunk {};

has Scheme::Environment $.env is required;

method execute($ast, $env = $.env) {
    my $v = self.execute-ast($ast, $env);
    # say $v.WHAT , ' is ', $v;
    while $v.does(Thunk) {
        # say $v.WHAT , ' is ', $v;
        $v = $v.();
    }
    return $v;
}

multi method execute-ast(Scheme::AST::Expressions $ast, $env) {
    if $ast.expressions.elems == 1 {
        return self.execute($ast.expressions[0], $env);
    }
    else {
        my $first_ast       = $ast.expressions[0];
        my $expressions_ast = Scheme::AST::Expressions.new(
            context => $ast.context,
            expressions => $ast.expressions[1..*],
        );
        self.execute: $first_ast, $env;
        return sub { self.execute: $expressions_ast, $env} but Thunk;
    }
    for $ast.expressions {
        my $x = self.execute: $_, $env;
        LAST { return $x }
    }
}

multi method execute-ast(Scheme::AST::ProcCall $ast, $env) {
    my &proc = $ast.identifier
    ?? $env.lookup($ast.identifier)
    !! self.execute($ast.lambda, $env);
    my $x =  proc |$ast.expressions.map: {
        self.execute: $_, $env;
    };
    return $x;
}

multi method execute-ast(Scheme::AST::Set $ast, $env) {
    my $val = self.execute($ast.expression, $env);
    $env.update: $ast.identifier => $val;
}
multi method execute-ast(Scheme::AST::Definition $ast, $env) {
    my $val = self.execute($ast.expression, $env);
    $env.set: $ast.identifier => $val;
}
multi method execute-ast(Scheme::AST::Symbol $ast, $env) {
    my $var = $env.lookup($ast.identifier);
    if $var ~~ Positional {
        return eager flat $var;
    }
    return $var;
}
multi method execute-ast(Scheme::AST::Lambda $ast, $env) {
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
multi method execute-ast(Scheme::AST::Conditional $ast, $env) {
    my $val = self.execute($ast.expression, $env);
    self.execute($val ?? $ast.conseq !! $ast.alt, $env);
}
multi method execute-ast(Scheme::AST::Quote $ast, $env) {
    return $ast.datum;
}
multi method execute-ast(Scheme::AST::Macro $ast, $env) {
    # macro AST definitions are processed at parsing
    # they wont be executed
}

multi method execute-ast($any where { not .does: Scheme::AST }, $env) {
    return $any;
}
multi method execute-ast($any where { .does: Scheme::AST }, $env) {
    die "execution of { $any.^name } not yet implemented";
}


