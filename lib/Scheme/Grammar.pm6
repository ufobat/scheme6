use v6;

# no precompilation;
# use Grammar::Tracer;
use Grammar::ErrorReporting;

grammar Scheme::Grammar does Grammar::ErrorReporting {
    rule TOP {
        <.ws>? <expression>+
    }

    regex ws {
        <!ww> [
            | \s*
            | <comment>
        ]
    }

    regex comment { ';' \N* }

    proto rule expression {*}
    rule expression:sym<atom> { <atom> }
    rule expression:sym<list> { '(' ~ ')' <expression>* }

    proto token atom {*}
    token atom:sym<identifier> { <.initial> <.subsequent>* }
    token atom:sym<build-in>   { <[- + * /]> }
    token atom:sym<number>     { <[- +]>? \d+ [ '.' \d+ ]? }
    token atom:sym<string>     { '"' <string-char>*  '"' }
    token atom:sym<boolean>    { '#f' | '#t' }
    token atom:sym<character>  {
        | [ '#\\' \w ]
        | '#\\newline'
        | '#\\space'
    }

    # helper tokens
    token initial    { <alpha> | <[! $ % & : < = > ? ~ _ ^ ]> }  # ! | $ | % | & | * | / | : | < | = | > | ? | ~ | _ | ^
    token subsequent { <initial> | \d | <[- + .]> }
    token backspace  { \\ }

    token string-char {
        | \w | \s
        | <[- + * / $ . : _ ^ < = > ? ~]>  # fixme: there are others as well
        | <.backspace><.backspace> # literally \\
        | <.backspace> '"'  # literally \"
    }
}
