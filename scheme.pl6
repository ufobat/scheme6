use v6;

use Scheme;

multi sub MAIN(Str $file) {
    my $program = $file.IO.slurp;
    my $match = parse($program);
    evaluate($match);
}

#`(REPL)
multi sub MAIN() {
    my $env = environment();
    loop {
        my $program = prompt ">>> ";
        try {
            my $match = parse $program;
            say evaluate $match, :$env;
            CATCH { default { .note } }
        }
    }
}

multi sub MAIN(Str:D :$e!, Bool :$parse-only = False) {
    my $match = parse($e);

    if $parse-only {
        say $match;
        say $match.ast;
        return;
    }

    evaluate($match);
}
