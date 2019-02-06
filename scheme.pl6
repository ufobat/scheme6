use v6;

use Scheme;

multi sub MAIN(IO::Path $file) {
    my $program = $file.slurp;
    my $match = parse($program);
    evaluate($match);
}

#`(REPL)
multi sub MAIN() {
    loop {
        my $program = prompt ">>> ";
        try {
            say evaluate parse $program;
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
