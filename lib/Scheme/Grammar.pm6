use v6;

grammar Scheme::Grammar {
    rule TOP {
        <.ws>?  <expression>+
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
    token initial    { <alpha> | <[- + * / $ % & : < = > ? ~ _ ^ ]> }
    token subsequent { <initial> | \d  }
    token backspace  { \\ }

    # numbers
    token number    { \d+ }
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
        <definition> | <conditional> | <proc-call> | <lambda>
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

    rule lambda {
        'lambda' '(' <identifier>* ')' <expression>+
    }
}
