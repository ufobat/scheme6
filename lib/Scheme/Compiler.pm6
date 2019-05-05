unit module Scheme::Compiler;

use Scheme::AST;
use Scheme::Grammar;

our proto to-ast($any) {*}

#### the order of the subs are important

## LIST EXPRESSIONS

# rule conditional { 'if' <test=expression> <conseq=expression> <alt=expression> }
subset Conditional of Positional where {
    $_.elems == 4 and
    $_[0] eq 'if'
}
multi sub to-ast(Conditional $any) {
    Scheme::AST::Conditional.new:
        expression => to-ast($any[1]),
        conseq     => to-ast($any[2]),
        alt        => to-ast($any[3]);
}

# rule definition:sym<simple> {
#     'define' <identifier> <expression>
# }
subset DefinitionSimple of Positional where {
    $_.elems == 3 and
    $_[0] eq 'define' and
    Scheme::Grammar.parse( :rule('atom:sym<identifier>'), $_[1])
}
multi sub to-ast(DefinitionSimple $any) {
    Scheme::AST::Definition.new:
        identifier => ~ $any[1],
        expression => to-ast($any[2]),
}

# rule definition:sym<lambda> {
#     'define' '(' <def-name=identifier> [<lambda-identifier=identifier> ]*  ')' <expression>+
# }
subset DefinitionLambda of Positional where {
    $_.elems >= 3 and
    $_[0] eq 'define' and
    $_[1] ~~ Positional and
    $_[1].elems >= 1 and
    grep {
        Scheme::Grammar.parse( :rule('atom:sym<identifier>'), $_)
    }, $_[1].values
}
multi sub to-ast(DefinitionLambda $any) {
    Scheme::AST::Definition.new(
        identifier =>  ~ $any[1][0],
        expression => Scheme::AST::Lambda.new(
            params => | $any[1][1..*].map( ~* ),
            expressions => to-ast($any[2])
        )
    );
}

# rule lambda { 'lambda' '(' <identifier>* ')' <expression>+ }
subset Lambda of Positional where {
    $_.elems >= 3 and
    $_[0] eq 'lambda' and
    $_[1] ~~ Positional and
    grep {
        Scheme::Grammar.parse( :rule('atom:sym<identifier>'), $_)
    }, $_[1].values
}
multi sub to-ast(Lambda $any) {
    # TODO TODO TODO TODO TODO TODO TODO TODO
    Scheme::AST::Lambda.new:
        params => | $any[1].map( ~* ),
        expressions => to-ast($any[2])
}

# TODO TODO TODO TODO TODO TODO TODO TODO
# rule define-syntax {
#     'define-syntax' <keyword=identifier> <transformer-spec>+
# }
# TODO TODO TODO TODO TODO TODO TODO TODO

# TODO TODO TODO TODO TODO TODO TODO TODO
# rule transformer-spec {
#     '('
#       'syntax-rules'
#       '(' [ <literal=identifier> ]*                                  ')'
#       '(' <src-s-expression=list> <dst-s-expression=list-expression> ')'
#     ')'
# }
# TODO TODO TODO TODO TODO TODO TODO TODO

# rule quote {
#     'quote' <datum>
# }
subset Quote of Positional where {
    $_.elems == 2 and
    $_[0] eq 'quote'
}
multi sub to-ast(Quote $any) {
    Scheme::AST::Quote.new: datum => $any[1];
}

# TODO TODO TODO TODO TODO TODO TODO TODO
# rule proc-or-macro-call:sym<lambda> { '(' <lambda> ')' <expression>* }
# TODO TODO TODO TODO TODO TODO TODO TODO

# rule proc-or-macro-call:sym<simple> {
#     [ <identifier> | <identifier=build-in> ] <expression>*
# }
subset ProcOrMacroOrBuildinCall of Positional where {
    Scheme::Grammar.parse(
        :rule('atom:sym<build-in>'), $_[0]
    )
    or
    Scheme::Grammar.parse(
        :rule('atom:sym<identifier>'), $_[0]
    );
}
multi sub to-ast(ProcOrMacroOrBuildinCall $any) {
    my $identifier = $any.shift;
    Scheme::AST::ProcCall.new:
        :$identifier,
        expressions => map { to-ast $_ }, $any.values
}

subset SequenceOfExpressions of Positional;
multi sub to-ast(SequenceOfExpressions $any) {
    Scheme::AST::Expressions.new:
        expressions => map { to-ast $_ }, $any.values ;
}

## ATOMS

subset Identifier of Str where {
    Scheme::Grammar.parse(
        :rule('atom:sym<identifier>'), $_
    );
}

subset String of Str where {
    Scheme::Grammar.parse(
        :rule('atom:sym<string>'), $_
    );
}

multi sub to-ast(Identifier $any) {
    Scheme::AST::Variable.new: identifier => $any;
}

multi sub to-ast($any) {
    $any;
}
