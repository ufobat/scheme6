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
        (define number 20)
        (define depth 0)
        (define went-deeper #f)
        (define (check-depth new-depth)
         (
             (if (= depth 0)
              (set! depth new-depth)
              (if (= depth new-depth)
               1
               (set! went-deeper #t)
              )
             )
         )
        )
        (define (count-to-one n)
         (
             (check-depth (s6:depth))
             (if (<= n 1)
              1
              (count-to-one (- n 1))
             )
         ))
        (count-to-one number)
        went-deeper
    };
    $ast = test-parse($scheme-code);
    is evaluate($ast), False
}, 'simple tail recursion';

subtest {
    $scheme-code = Q{
        (define number 20)
        (define depth 0)
        (define went-deeper #f)
        (define (check-depth new-depth)
         (
             (if (= depth 0)
              (set! depth new-depth)
              (if (= depth new-depth)
               1
               (set! went-deeper #t)
              )
             )
         )
        )
        (define (count-to-one-one-less n)
         (
             (count-to-one (- n 1))
         )
        )
        (define (count-to-one n)
         (
             (check-depth (s6:depth))
             (if (<= n 1)
              1
              (count-to-one-one-less n)
             )
         ))
        (count-to-one number)
        went-deeper
    };
    $ast = test-parse($scheme-code);
    is evaluate($ast), False
}, 'double tail recursion';


done-testing;

