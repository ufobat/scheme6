unit class Scheme::Compiler;

use Scheme::AST;
use Scheme::AST::Dumper;
use Scheme::Grammar;
use Scheme::Context;

has %.macros;

subset Identifier of Str where {
    Scheme::Grammar.parse( :rule('atom:sym<identifier>'), $_ )
}
subset BuildIn of Str where {
    Scheme::Grammar.parse( :rule('atom:sym<build-in>'), $_ )
}
subset String of Str where {
    Scheme::Grammar.parse( :rule('atom:sym<string>'), $_)
}

subset IdentifierList of Positional where {
    $_.values.grep({ $_ ~~ Identifier}) == $_.elems
}

## LIST EXPRESSIONS
# rule conditional { 'if' <test=expression> <conseq=expression> <alt=expression> }
multi method list-to-ast('if', $expression, $conseq, $alt, :%context, :$current_context) {
    Scheme::AST::Conditional.new:
        context    => $current_context,
        expression => self.to-ast($expression, :%context),
        conseq     => self.to-ast($conseq,     :%context),
        alt        => self.to-ast($alt,        :%context);
}

# rule definition:sym<simple> {
#     'define' <identifier> <expression>
# }

multi method list-to-ast('define', Identifier $identifier, $expression, :%context, :$current_context) {
    # say "DefinitionSimple";
    Scheme::AST::Definition.new:
        context    => $current_context,
        identifier => $identifier,
        expression => self.to-ast($expression, :%context),
}

# rule definition:sym<lambda> {
#     'define' '(' <def-name=identifier> [<lambda-identifier=identifier> ]*  ')' <expression>+
# }
multi method list-to-ast('define', IdentifierList $identifier, $expression, :%context, :$current_context) {
    Scheme::AST::Definition.new(
        context => $current_context,
        identifier => $identifier.shift,
        expression => Scheme::AST::Lambda.new(
            context => $current_context,
            params  => $identifier.values,
            expressions => self.to-ast($expression, :%context)
        )
    );
}

# rule lambda { 'lambda' '(' <identifier>* ')' <expression>+ }
multi method list-to-ast('lambda', IdentifierList $params, $expressions, :%context, :$current_context) {
    Scheme::AST::Lambda.new:
        context     => $current_context,
        params      => $params.values,
        expressions => self.to-ast($expressions, :%context)
}

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
    $_[1] ~~ Identifier
    #and $_[2] ~~ TransformerSpec
}
multi method to-ast(DefineSyntax $any, :%context) {
    my $identifier = ~ $any[1],
    my $ast = Scheme::AST::Macro.new:
        context => %context{ $any.WHERE },
        identifier => $identifier,
        transformer-spec => self!to-transformer-spec($any[2], :%context);

    # dump-ast($ast, :skip-context);
    die "can not redefine macro '$identifier'" if %.macros{ $identifier }:exists;
    $.macros{ $identifier } = $ast;

    return $ast
}
method !to-transformer-spec(TransformerSpec $any, :%context) {
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


# rule quote { 'quote' <datum> }
multi method list-to-ast('quote', $datum, :%context, :$current_context) {
    Scheme::AST::Quote.new:
        datum   => $datum,
        context => $current_context,
}

# rule proc-or-macro-call:sym<lambda> { '(' <lambda> ')' <expression>* }
subset Lambda of Positional where {
    $_.elems >= 3 and
    $_[0] eq 'lambda' and
    $_[1] ~~ Positional and
    grep {
        Scheme::Grammar.parse( :rule('atom:sym<identifier>'), $_)
    }, $_[1].values
}
subset LambdaCall of Positional where {
    $_.elems == 2 and
    $_[0] ~~ Lambda
}
multi method to-ast(LambdaCall $any, :%context) {
    Scheme::AST::ProcCall.new:
    context => %context{ $any.WHERE },
    lambda => self.to-ast($any[0]),
    expressions => self.to-ast($any[1]),
}

# rule proc-or-macro-call:sym<simple> {
#     [ <identifier> | <identifier=build-in> ] <expression>*
# }
multi method list-to-ast($identifier where Identifier|BuildIn, *@param, :%context, :$current_context) {
    return %.macros{ $identifier }:exists
        ?? self!macro-to-ast(%.macros{ $identifier }, @param, %context)
        !! Scheme::AST::ProcCall.new(
            identifier  => $identifier,
            context     => $current_context,
            expressions => | @param.map({ self.to-ast( $_, :%context ) })
        );
}

method !macro-to-ast($macro-ast, @param, %context) {
    # (define x -1)
    # (define y  1)
    # (define e  0)
    # (define-syntax three-state-macro                                 ;;; $identifier eq 'three-state-macro'
    #   (syntax-rules (ignore e)                                       ;;; $transformer-spec.literals
    #     (
    #      (_ x ignore e pos-body eq-body neg-body)                    ;;; $transformer-spec.source
    #      (if (> x 0) pos-body (if (= x 0) eq-body neg-body ))        ;;; $transformer-spec.destination
    #     )
    #   )
    # )
    # (three-state-macro x ignore e (display "P") (display "N") (display "Z"))  ;;; @expressions

    sub macro-matches(@expressions, @literals, @source) {
        my %replaceables; # name => $ast

        my $underscore = @source.shift;
        unless $underscore eq '_' {
            note "transformer-spec is confusing: expected '_' but got '$underscore'";
            return;
        }
        # say join "\n", "<expressions>", @expressions.map(*.perl), "<expressions>\n";
        unless @expressions.elems == @source.elems {
            note "number of elements missmatch";
            return;
        }

        sub syntax-ignore(Str $src-keyword --> Bool) { so @literals.first: $src-keyword }

        # say "           SOURCE -> EXPRESSION";
        for @expressions Z @source -> ($e, $s) {
            unless syntax-ignore $s {
                %replaceables{ $s } = $e;
            }
            # say "looop: ", $s.fmt('%10s'), " -> ", $e;
        }

        # say %replaceables;
        return %replaceables;
    }

    # dump-ast(@param, :skip-context);
    my @expressions = @param.map({ self.to-ast( $_, :%context ) });
    for $macro-ast.transformer-spec -> $transformer-spec {

        use Scheme::AST::Dumper;
        # dump-ast(@expressions, :skip-context);
        # dump-ast($transformer-spec, :skip-context);
        my @source   = $transformer-spec.source;
        my @literals = $transformer-spec.literals;

        if my %replacements = macro-matches(@expressions, @literals, @source) {
            my $clone = clone-ast($transformer-spec.destination, %replacements);
            return $clone;
        }
        die 'macro call was invalid'
    }
}

# Must be the last to-ast
multi method to-ast(Positional $any
                    where {
                           self.^lookup('list-to-ast').cando( \(self, |$any.values, :context(Hash.new), :current_context ))
                       }, :%context) {
    my $current_context = %context{ $any.WHERE };
    self.list-to-ast(|$any.values, :%context, :$current_context);
}


subset SequenceOfExpressions of Positional;
multi method to-ast(SequenceOfExpressions $any, :%context) {
    # say "SequenceOfExpressions";
    Scheme::AST::Expressions.new:
        context     => %context{ $any.WHERE },
        expressions => | map { self.to-ast( $_, :%context ) }, $any.values ;
}

## ATOMS

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

sub clone-ast($ast, %replacements) {
    my $clone = $ast.clone;
    if $clone ~~ Scheme::AST {
        for $clone.^attributes(:local) -> $attr {
            my $value = $attr.get_value($clone);
            if $value ~~ Scheme::AST {
                my $cv =  $value ~~ Scheme::AST::Variable
                ?? %replacements{ $value.identifier }
                !! clone-ast($value, %replacements);
                $attr.set_value($clone, $cv);
            }
        }
    }

    return $clone;
}


