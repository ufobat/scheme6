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
        return self.execute-ast($ast.expressions[0], $env);
    }
    else {
        my $first_ast       = $ast.expressions[0];
        my $expressions_ast = Scheme::AST::Expressions.new(
            context => $ast.context,
            expressions => $ast.expressions[1..*],
        );
        self.execute-ast: $first_ast, $env;
        return sub { self.execute-ast: $expressions_ast, $env} but Thunk;
    }
}

multi method execute-ast(Scheme::AST::ProcCall $ast where so $ast.identifier, $env) {
    my &proc = $env.lookup($ast.identifier);

    my @param = $ast.expressions.map: {
        self.execute: $_, $env;
    };
    # scheme lambdas get trampolined
    #say $ast.identifier, ' -> ', @param.perl;

    if &proc ~~ Thunk {
        my &thunk = sub {
            #Backtrace.new.Str.say;
            return proc |@param } but Thunk;
        return &thunk;
    }
    # build-ins get executed
    return proc |@param;
}
multi method execute-ast(Scheme::AST::ProcCall $ast where not so $ast.identifier, $env) {
    #say "proc call without identifier";
    #say $ast.perl;
    my &proc = self.execute-ast($ast.lambda, $env);
    proc |$ast.expressions.map: {
        self.execute-ast: $_, $env;
    };
}

multi method execute-ast(Scheme::AST::Definition $ast, $env) {
    my $val = self.execute-ast($ast.expression, $env);
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
            my $x = self.execute-ast: $_, $scope;
            LAST { return $x }
        }
    } but Thunk;
}
multi method execute-ast(Scheme::AST::Conditional $ast, $env) {
    my $val = self.execute-ast($ast.expression, $env);
    self.execute-ast($val ?? $ast.conseq !! $ast.alt, $env);
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


