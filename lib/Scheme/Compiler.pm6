unit class Scheme::Compiler;

use Scheme::AST;
use Scheme::AST::Dumper;
use Scheme::Grammar;
use Scheme::Context;

has %.macros;

# our proto to-ast($any, :%context)  {
#     {*}
# }

# multi method to-ast($_ where Positional, :%context) {
#     my $current_context = %context{ $_.WHERE };
#     self.list-to-ast(|$_.values, :%context, :$current_context);
# }
# subset IdentifierList of Positional where {
#     $_.values.grep({ $_ ~~ Identifier}) == $_.elems
# }

#### the order of the subs are important

## LIST EXPRESSIONS

# rule conditional { 'if' <test=expression> <conseq=expression> <alt=expression> }
subset Conditional of Positional where {
    $_.elems == 4 and
    $_[0] eq 'if'
}
multi method to-ast(Conditional $any, :%context) {
    # say "Conditional";
    Scheme::AST::Conditional.new:
        context    => %context{ $any.WHERE },
        expression => self.to-ast($any[1], :%context),
        conseq     => self.to-ast($any[2], :%context),
        alt        => self.to-ast($any[3], :%context);
}
# multi method list-to-ast('if', $expression, $conseq, $alt, :%context, :$current_context) {
#     Scheme::AST::Conditional.new:
#         context    => $current_context,
#         expression => self.to-ast($expression, :%context),
#         conseq     => self.to-ast($conseq,     :%context),
#         alt        => self.to-ast($alt,        :%context);
# }

# rule definition:sym<simple> {
#     'define' <identifier> <expression>
# }
subset DefinitionSimple of Positional where {
    $_.elems == 3 and
    $_[0] eq 'define' and
    Scheme::Grammar.parse( :rule('atom:sym<identifier>'), $_[1])
}
multi method to-ast(DefinitionSimple $any, :%context) {
    # say "DefinitionSimple";
    Scheme::AST::Definition.new:
        context    => %context{ $any.WHERE },
        identifier => ~ $any[1],
        expression => self.to-ast($any[2], :%context),
}

# multi method list-to-ast('define', Identifier $identifier, $expression, :%context, :$current_context) {
#     # say "DefinitionSimple";
#     Scheme::AST::Definition.new:
#         context    => $current_context,
#         identifier => $identifier,
#         expression => self.to-ast($expression, :%context),
# }

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
multi method to-ast(DefinitionLambda $any, :%context) {
    # say "DefinitionLambda", $any.WHAT;
    my $context = %context{ $any.WHERE };
    Scheme::AST::Definition.new(
        :$context,
        identifier => ~ $any[1][0],
        expression => Scheme::AST::Lambda.new(
            :$context,
            params => | $any[1][1..*].map( ~* ),
            expressions => self.to-ast($any[2], :%context)
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
multi method to-ast(Lambda $any, :%context) {
    Scheme::AST::Lambda.new:
        context     => %context{ $any.WHERE },
        params      => | $any[1].map( ~* ),
        expressions => self.to-ast($any[2], :%context)
}
# multi method list-to-ast('lambda', IdentifierList $params, Positional $expressions, :%context, :$current_context) {
#     Scheme::AST::Lambda.new:
#         context     => $current_context,
#         params      => $params.values,
#         expressions => self.to-ast($expressions, :%context)
# }

# TODO TODO TODO TODO TODO TODO TODO TODO
# rule define-syntax {
#     'define-syntax' <keyword=identifier> <transformer-spec>+
# }
# rule transformer-spec {
#     '('
#       'syntax-rules'
#       '(' [ <literal=identifier> ]*                                  ')'
#       '(' <src-s-expression=list> <dst-s-expression=list-expression> ')'
#     ')'
# }
# TODO TODO TODO TODO TODO TODO TODO TODO
subset TransformerSpec of Positional where {
    $_.elems == 3
    and $_[0] eq 'syntax-rules'
    and $_[1] ~~ Positional
    and $_[2] ~~ Positional
    # identifier
    and $_[1].values.grep({ Scheme::Grammar.parse( :rule('atom:sym<identifier>'), $_) })
    and $_[2].elems == 2
    # src-s-expression / list
    and $_[2][1]
    # dst-s-expression / list-expression
    and $_[2][1]
}
subset DefineSyntax of Positional where {
    $_.elems >= 3 and
    $_[0] eq 'define-syntax' and
    Scheme::Grammar.parse( :rule('atom:sym<identifier>'), $_[1] )
    #and $_[2] ~~ TransformerSpec
}
multi method to-ast(DefineSyntax $any, :%context) {
    my $identifier = ~ $any[1],
    my $ast = Scheme::AST::Macro.new:
        context => %context{ $any.WHERE },
        identifier => $identifier,
        transformer-spec => self.to-transformer-spec($any[2], :%context);

    dump-ast($ast, :skip-context);
    die "can not redefine macro '$identifier'" if %.macros{ $identifier }:exists;
    $.macros{ $identifier } = $ast;

    return $ast
}
method to-transformer-spec(TransformerSpec $any, :%context) {
    # use Data::Dump;
    # say 'identifier: ', Dump($any[1], :skip-methods);
    # say 'src-s:      ', Dump($any[2][0], :skip-methods);
    # say 'dst-s:      ', Dump($any[2][1], :skip-methods);
    # exit;

    Scheme::AST::TransformerSpec.new:
        context     => %context{ $any.WHERE },
        literals    => | $any[1],
        source      => | $any[2][0],
        destination => self.to-ast($any[2][1], :%context),
}


# rule quote {
#     'quote' <datum>
# }
subset Quote of Positional where {
    $_.elems == 2 and
    $_[0] eq 'quote'
}
multi method to-ast(Quote $any, :%context) {
    Scheme::AST::Quote.new:
        datum   => $any[1],
        context => %context{ $any.WHERE },
}
# multi method list-to-ast('quote', $datum, :%context, :$current_context) {
#     #say "Quote";
#     Scheme::AST::Quote.new:
#         datum   => $datum,
#         context => $current_context,
# }

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
multi method to-ast(ProcOrMacroOrBuildinCall $any, :%context) {
    #say "ProcOrMacroOrBuildinCall";
    my $identifier = $any.shift;
    return %.macros{ $identifier }:exists
        ?? self!to-macro-ast($any)
        !! Scheme::AST::ProcCall.new(
            identifier  => $identifier,
            context     => %context{ $any.WHERE },
            expressions => | map { self.to-ast( $_, :%context ) }, $any.values
        );
}

method !to-macro-ast($any) {

}

subset SequenceOfExpressions of Positional;
multi method to-ast(SequenceOfExpressions $any, :%context) {
    # say "SequenceOfExpressions";
    Scheme::AST::Expressions.new:
        context     => %context{ $any.WHERE },
        expressions => | map { self.to-ast( $_, :%context ) }, $any.values ;
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

multi method to-ast(Identifier $any, :%context) {
    # say "Identifier";
    Scheme::AST::Variable.new:
        context    => %context{ $any.WHERE },
        identifier => $any;
}

multi method to-ast($any, :%context) {
    # say "default", $any.WHAT;
    $any;
}
