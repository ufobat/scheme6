use v6;
# no precompilation;
# use Grammar::Tracer;

grammar Scheme::Grammar {
    rule TOP {
        <.ws>?
        [
            | <expression>
            | <.comment>
        ]+
    }

    regex comment {
        ';' \N*
    }

    rule expression {
        | <atom>
        | <list-expression>
    }

    token atom {
        | <variable>
        | <constant>
    }
    token variable {
        <identifier>
    }
    token identifier {
        <.initial> <.subsequent>*
    }

    token constant {
        | <number>
        | <string>
        | <character>
        | <boolean>
    }

    # helper tokens
    token initial    { <alpha> | <[! $ % & : < = > ? ~ _ ^ ]> }  # ! | $ | % | & | * | / | : | < | = | > | ? | ~ | _ | ^
    token subsequent { <initial> | \d | <[- + .]> }
    token backspace  { \\ }

    # numbers
    token number    { <[- +]>? \d+ [ '.' \d+ ]? }
    token string    { '"' <string-char>*  '"' }
    token string-char {
        | \w
        | <.backspace><.backspace> # literally \\
        | <.backspace> '"'  # literally \"
    }
    token character {
        | [ '#\\' \w ]
        | '#\\newline'
        | '#\\space'
    }
    token boolean   { '#f' | '#t' }

    rule list-expression {
        '(' [
            | <definition>
            | <conditional>
            | <lambda>
            | <quote>
            | <proc-call>
        ] ')'
    }

    proto rule definition {*}
    rule definition:sym<simple> {
        'define' <identifier> <expression>
    }

    rule definition:sym<lambda> {
        'define' '(' <def-name=identifier> [<lambda-identifier=identifier> ]*  ')' <expression>+
    }

    rule conditional {
        'if' <test=expression> <conseq=expression> <alt=expression>
    }

    proto rule proc-call {*}
    rule proc-call:sym<simple> {
        <identifier> <expression>*
    }
    rule proc-call:sym<lambda> {
        '(' <lambda> ')' <expression>*
    }

    rule lambda {
        'lambda' '(' <identifier>* ')' <expression>+
    }

    rule quote {
        'quote' <datum>
    }

    rule datum {
        <atom> | <list>
    }

    rule list {
        '(' <datum>* ')'
    }
}
