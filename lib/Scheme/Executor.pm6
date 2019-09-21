use v6.c;

unit class Scheme::Executor;

use Scheme::AST;
use Scheme::Environment;

# Thunks must not use $executor.execute()
# since they would break the trampoline
# and build a chain of trampolines
role Thunk  {};
role Lambda {};

has Scheme::Environment $.env is required;

method execute($ast, $env = $.env) {
    my $v = execute-ast(self, $ast, $env);
    # say $v.WHAT , ' is ', $v;
    while $v.does(Thunk) {
        # say $v.WHAT , ' is ', $v;
        $v = $v.();
    }
    return $v;
}

multi sub execute-ast($executor, Scheme::AST::Expressions $ast, $env) {
    if $ast.expressions.elems == 1 {
        #say $ast.expressions[0].WHAT;
        return sub { execute-ast($executor, $ast.expressions[0], $env) } but Thunk;
        # return execute-ast($executor, $ast.expressions[0], $env);
    }
    else {
        my $first_ast       = $ast.expressions[0];
        my $expressions_ast = Scheme::AST::Expressions.new(
            context => $ast.context,
            expressions => $ast.expressions[1..*],
        );
        #execute-ast $executor, $first_ast, $env;
        $executor.execute( $first_ast, $env );
        return sub { execute-ast($executor, $expressions_ast, $env) } but Thunk;
    }
}

multi sub execute-ast($executor, Scheme::AST::ProcCall $ast where so $ast.identifier, $env) {
    my &proc = $env.lookup($ast.identifier);

    my @param = $ast.expressions.map: {
        $executor.execute: $_, $env;
    };
    # scheme lambdas get trampolined
    #say $ast.identifier, ' -> ', @param.perl;

    if &proc ~~ Lambda {
        my &thunk = sub {
            #Backtrace.new.Str.say;
            return proc |@param
        } but Thunk;
        return &thunk;
    }
    if &proc ~~ Thunk { warn "WTF?" }
    # build-ins get executed
    return proc |@param;
}
multi sub execute-ast($executor, Scheme::AST::ProcCall $ast where not so $ast.identifier, $env) {
    #say "proc call without identifier";
    #say $ast.perl;
    my &proc = execute-ast($executor, $ast.lambda, $env);
    proc |$ast.expressions.map: {
        execute-ast $executor, $_, $env;
    };
}

multi sub execute-ast($executor, Scheme::AST::Set $ast, $env) {
    my $val = $executor.execute($ast.expression, $env);
    $env.update: $ast.identifier => $val;
}
multi sub execute-ast($executor, Scheme::AST::Definition $ast, $env) {
    my $val = $executor.execute($ast.expression, $env);
    $env.set: $ast.identifier => $val;
}
multi sub execute-ast($executor, Scheme::AST::Symbol $ast, $env) {
    my $var = $env.lookup($ast.identifier);
    if $var ~~ Positional {
        return eager flat $var;
    }
    return $var;
}
multi sub execute-ast($executor, Scheme::AST::Lambda $ast, $env) {
    sub (*@a) {
        my $scope = $env.make-new-scope();
        for |$ast.params -> $name {
            $scope.set: $name => shift @a
        }

        # TODO Lambda schould have Scheme::AST::Expressions instead of list of $expressions.
        # return sub { $executor.execute($ast.expressions, $scope) } but Thunk;
        return sub { execute-ast($executor, $ast.expressions, $scope) } but Thunk;
        # return sub {
        # for $ast.expressions {
        #     my $x = $executor.execute($_, $scope);
        #     LAST { return $x }
        # }
        # } but Thunk;
    } but Lambda;
}
multi sub execute-ast($executor, Scheme::AST::Conditional $ast, $env) {
    my $val = $executor.execute($ast.expression, $env);
    return sub { execute-ast($executor, $val ?? $ast.conseq !! $ast.alt, $env) } but Thunk;
}
multi sub execute-ast($executor, Scheme::AST::Quote $ast, $env) {
    return $ast.datum;
}
multi sub execute-ast($executor, Scheme::AST::Macro $ast, $env) {
    # macro AST definitions are processed at parsing
    # they wont be executed
}

multi sub execute-ast($executor, $any where { not .does: Scheme::AST }, $env) {
    return $any;
}
multi sub execute-ast($executor, $any where { .does: Scheme::AST }, $env) {
    die "execution of { $any.^name } not yet implemented";
}


