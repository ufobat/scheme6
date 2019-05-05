#!/usr/bin/env perl6

use v6;

use Scheme;
use Scheme::AST::Dumper;

multi sub MAIN(Str $file, Bool :$parse-only = False, Bool :$compile-only = False) {
    my $program = $file.IO.slurp;
    run-code($program, $parse-only, $compile-only);
}

#`(REPL)
multi sub MAIN() {
    my $env = environment();
    loop {
        my $program = prompt ">>> ";
        try {
            my ($list, %context) = parse $program;
            my $ast = compileX $list, :%context;
            execute $ast, $env;
            CATCH { default { .note } }
        }
    }
}

multi sub MAIN(Str:D :$e!, Bool :$parse-only = False, Bool :$compile-only = False) {
    run-code($e, $parse-only, $compile-only);
}

sub run-code($program, $parse-only, $compile-only) {
    my ($list, %context) = parse($program);
    if $parse-only {
        say $list.perl;
        say %context.perl;
        return;
    }

    my $ast = compileX $list, :%context;
    if $compile-only {
        dump-ast($ast, :skip-context);
        return;
    }

    my $env = environment;
    execute $ast, $env;
}
