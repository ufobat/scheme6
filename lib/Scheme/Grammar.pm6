use v6;

grammar Scheme::Grammar {
    rule TOP {
        <expression>+
    }

    rule expression {
        | <atom>
        | <list>
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
    token initial    { <alnum> | <[- + * / $ % & : < = > ? ~ _ ^ ]> }
    token subsequent { <initial> | \d  }
    token bs         { \\ }

    # numbers
    token number    { \d+ }
    token string    { '"' <string-char>*  '"' }
    token string-char {
        | \w
        | <.bs><.bs> # literally \\
        | <.bs> '"'  # literally \"
    }
    token character {
        | [ '#\\' \w ]
        | '#\\newline'
        | '#\\space'
    }
    token boolean   { '#f' | '#t' }

    rule list {
        '(' [
        <definition> | <conditional> | <proc-call>
        ] ')'
    }

    rule definition {
        'define' <identifier> <expression>
    }

    rule conditional {
        'if' <test=expression> <conseq=expression> <alt=expression>
    }

    rule proc-call {
        <identifier> <expression>*
    }
}
