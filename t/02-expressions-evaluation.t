use v6;
use Test;

use Scheme;

my ($scheme-code, $ast);

sub test-parse($code) {
    my ($ast, $list, %context);
    lives-ok { ($list, %context) = parse $scheme-code }, 'parsed';
    ok $list, 'scheme understood';
    ok %context.elems > 0, 'with context';
    lives-ok { $ast = compileX $list, :%context }, 'compiled';
    return $ast;
}

subtest {
    $scheme-code = Q{
        (define x 10)
        (define (fun) (
                (set! x 1)
                (set! x 2)
                (set! x 3)
            ))
        (fun)
        x
    };
    $ast = test-parse($scheme-code);
    is evaluate($ast), 3
}, 'set! to 3';

done-testing;

