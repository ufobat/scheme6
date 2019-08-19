use v6.c;

unit module Scheme:ver<0.0.1>:auth<cpan:ufobat>;

use Scheme::AST;
use Scheme::AST::Dumper;
use Scheme::Grammar;
use Scheme::Action;
use Scheme::Environment;
use Scheme::Executor;
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
    my $compiler = Scheme::Compiler.new;
    return $compiler.to-ast($list, :%context);
}

sub execute($ast, $env) is export {
    my $executor = Scheme::Executor.new(:$env);
    $executor.execute($ast);
}

sub evaluate ($ast, $env = environment()) is export {
    execute $ast, $env;
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
