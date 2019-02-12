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

    # for proc-calls that do not match the <identfier>
    token build-in {
        <[- + * /]>
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
        | \w | \s
        | <[- + * / $ . : _ ^ < = > ? ~]>  # fixme: there are others as well
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
            | <define-syntax>
            | <proc-or-macro-call>
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

    proto rule proc-or-macro-call {*}
    rule proc-or-macro-call:sym<simple> {
        [ <identifier> | <identifier=build-in> ] <expression>*
    }
    rule proc-or-macro-call:sym<lambda> {
        '(' <lambda> ')' <expression>*
    }

    rule lambda {
        'lambda' '(' <identifier>* ')' <expression>+
    }

    rule define-syntax {
        'define-syntax' <keyword=identifier> <transformer-spec>+
    }

    rule transformer-spec {
        '('
          'syntax-rules'
          '(' [ <literal=identifier> ]*                                  ')'
          '(' <src-s-expression=list> <dst-s-expression=list-expression> ')'
        ')'
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
