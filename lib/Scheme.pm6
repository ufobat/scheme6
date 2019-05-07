use v6.c;

unit module Scheme:ver<0.0.1>:auth<cpan:ufobat>;

use Scheme::AST;
use Scheme::Grammar;
use Scheme::Action;
use Scheme::Environment;
use Scheme::Compiler;

sub parse(Str $program) is export {
    my $actions = Scheme::Action.new;
    my $match   = Scheme::Grammar.parse($program, :$actions);
    die 'compile error' unless $match;
    return ($match.ast, $actions.context);
}

sub environment() is export {
    return Scheme::Environment.get-global-environment();
}

sub compileX($list, :%context) is export {
    return Scheme::Compiler::to-ast($list, :%context);
}

proto execute($ast, $env) is export {
    {*}
}

sub evaluate ($ast, $env = environment()) is export {
    execute $ast, $env;
}

multi sub execute(Scheme::AST::Expressions $ast, $env) {
    for $ast.expressions {
        my $x = execute $_, $env;
        LAST { return $x }
    }
}

multi sub execute(Scheme::AST::ProcCall $ast, $env) {
    my &proc = $ast.identifier
    ?? $env.lookup($ast.identifier)
    !! execute($ast.lambda, $env);
    proc |$ast.expressions.map: {
        execute $_, $env;
    };
}
multi sub execute(Scheme::AST::Definition $ast, $env) {
    my $val = execute($ast.expression, $env);
    $env.set: $ast.identifier => $val;
}
multi sub execute(Scheme::AST::Variable $ast, $env) {
    my $var = $env.lookup($ast.identifier);
    if $var ~~ Positional {
        return eager flat $var;
    }
    return $var;
}
multi sub execute(Scheme::AST::Lambda $ast, $env) {
    sub (*@a) {
        my $scope = $env.make-new-scope();
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
multi sub execute(Scheme::AST::Macro $ast, $env) {
    # macro AST definitions are processed at parsing
    # they wont be executed
}

multi sub execute($any where { not .does: Scheme::AST }, $env) {
    return $any;
}
multi sub execute($any where { .does: Scheme::AST }, $env) {
    die "execution of { $any.^name } not yet implemented";
}

=begin pod

=head1 NAME

Scheme - blah blah blah

=head1 SYNOPSIS

=begin code :lang<perl6>

use Scheme;

=end code

=head1 DESCRIPTION

Scheme is ...

=head1 AUTHOR

Martin Barth <martin@senfdax.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Martin Barth

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
