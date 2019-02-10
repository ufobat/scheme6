use v6;
use Test;

use Scheme;

my ($scheme-code, $ast);

sub test-parse($code) {
    my $ast;
    lives-ok { $ast = parse $scheme-code }, 'parsed';
    ok $ast, 'scheme understood';
    return $ast;
}

subtest {
    $scheme-code = Q{
        (define circle-area (lambda (r) (* pi (* r r))))
        (circle-area 3)
    };
    $ast = test-parse($scheme-code);
    is evaluate($ast), 3 * 3 * pi, 'circle area';
}, 'circle';

subtest {
    $scheme-code = Q{
        (define fact
         (lambda (n) (if (<= n 1) 1 (* n (fact (- n 1))))))
        (fact 10)
    };
    $ast = test-parse($scheme-code);
    is evaluate($ast), 3628800, 'fact 10';
}, 'fact 10';

subtest {
    $scheme-code = Q{
        (quote (1 2 3))
    };
    $ast = test-parse($scheme-code);
    is-deeply evaluate($ast), [1, 2, 3], 'same list';
}, 'quote list';

done-testing;

