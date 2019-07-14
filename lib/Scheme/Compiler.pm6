unit class Scheme::Compiler;

use Scheme::AST;
use Scheme::AST::Dumper;
use Scheme::Grammar;
use Scheme::Context;

has %.macros;

subset SymbolList of Positional where {
    $_.values.grep({ $_ ~~ Scheme::AST::Symbol }) == $_.elems
}

## LIST EXPRESSIONS
# rule conditional { 'if' <test=expression> <conseq=expression> <alt=expression> }
subset IfSymbol of Scheme::AST::Symbol where *.identifier eq 'if';
multi method list-to-ast(IfSymbol $, $expression, $conseq, $alt, :%context, :$current_context) {
    Scheme::AST::Conditional.new:
        context    => $current_context,
        expression => self.to-ast($expression, :%context),
        conseq     => self.to-ast($conseq,     :%context),
        alt        => self.to-ast($alt,        :%context);
}

# rule definition:sym<simple> {
#     'define' <identifier> <expression>
# }

subset DefineSymbol of Scheme::AST::Symbol where *.identifier eq 'define';
multi method list-to-ast(DefineSymbol $, Scheme::AST::Symbol $sym, $expression, :%context, :$current_context) {
    # say "DefinitionSimple";
    Scheme::AST::Definition.new:
        context    => $current_context,
        identifier => $sym.identifier,
        expression => self.to-ast($expression, :%context),
}

# rule definition:sym<lambda> {
#     'define' '(' <def-name=identifier> [<lambda-identifier=identifier> ]*  ')' <expression>+
# }
multi method list-to-ast(DefineSymbol $, SymbolList $identifier, $expression, :%context, :$current_context) {
    Scheme::AST::Definition.new(
        context => $current_context,
        identifier => $identifier.shift.identifier,
        expression => Scheme::AST::Lambda.new(
            context => $current_context,
            params  => $identifier.values.map(*.identifier),
            expressions => self.to-ast($expression, :%context)
        )
    );
}

# rule quote { 'quote' <datum> }
subset QuoteSymbol of Scheme::AST::Symbol where *.identifier eq 'quote';
multi method list-to-ast(QuoteSymbol $, $datum, :%context, :$current_context) {
    Scheme::AST::Quote.new:
        datum   => $datum,
        context => $current_context,
}

# rule proc-or-macro-call:sym<simple> {
#     [ <identifier> | <identifier=build-in> ] <expression>*
# }
multi method list-to-ast(Scheme::AST::Symbol $sym, *@param, :%context, :$current_context) {
    return %.macros{ $sym.identifier }:exists
        ?? self!macro-to-ast(%.macros{ $sym.identifier }, @param, %context)
        !! Scheme::AST::ProcCall.new(
            identifier  => $sym.identifier,
            context     => $current_context,
            expressions => | @param.map({ self.to-ast( $_, :%context ) })
        );
}

# rule lambda { 'lambda' '(' <identifier>* ')' <expression>+ }
subset LambdaSymbol of Scheme::AST::Symbol where *.identifier eq 'lambda';
multi method list-to-ast(LambdaSymbol $, SymbolList $params, $expressions, :%context, :$current_context) {
    Scheme::AST::Lambda.new:
        context     => $current_context,
        params      => $params.values.map(*.identifier),
        expressions => self.to-ast($expressions, :%context)
}

# rule proc-or-macro-call:sym<lambda> { '(' <lambda> ')' <expression>* }
subset Lambda of Positional where {
    $_.elems >= 3 and
    $_[0] ~~ LambdaSymbol and
    $_[1] ~~ Positional and
    $_[1] ~~ SymbolList
    # grep {
    #     Scheme::Grammar.parse( :rule('atom:sym<identifier>'), $_)
    # }, $_[1].values
}
subset LambdaCall of Positional where {
    $_.elems == 2 and
    $_[0] ~~ Lambda
}
# !!! multi method to ast must be in a specific order
multi method to-ast(LambdaCall $any, :%context) {
    Scheme::AST::ProcCall.new:
    context => %context{ $any.WHERE },
    lambda => self.to-ast($any[0]),
    expressions => self.to-ast($any[1]),
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
subset SyntaxRulesSymbol of Scheme::AST::Symbol where *.identifier eq 'syntax-rules';
subset TransformerSpec of Positional where {
    $_.elems == 3
    and $_[0] ~~ SyntaxRulesSymbol
    and $_[1] ~~ SymbolList
    and $_[2] ~~ Positional
    # identifier
    and $_[2].elems == 2
    # src-s-expression / list
    and $_[2][0] ~~ SymbolList
    # and do { unless ($_[2][1] ~~ SymbolList) { say "list: "; for |$_[2][1] { .WHAT.say; .say } };say "done"}
    # dst-s-expression / list-expression
    # and $_[2][1] ~~ SymbolList
}
subset DefineSyntaxSymbol of Scheme::AST::Symbol where *.identifier eq 'define-syntax';
subset DefineSyntax of Positional where {
    $_.elems >= 3
    and $_[0] ~~ DefineSyntaxSymbol
    and $_[1] ~~ Scheme::AST::Symbol
    and $_[2] ~~ TransformerSpec
}
# !!! multi method to ast must be in a specific order
multi method to-ast(DefineSyntax $any, :%context) {
    my $identifier = $any[1].identifier,
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
        source      => | $any[2][0].map(*.identifier),
        destination => self.to-ast($any[2][1], :%context),
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
            # say %replacements.perl;
            my $clone = clone-ast($transformer-spec.destination, %replacements);
            return $clone;
        }
        die 'macro call was invalid'
    }
}

# !!! multi method to ast must be in a specific order
multi method to-ast(Positional $any
                    where {
                           self.^lookup('list-to-ast').cando( \(self, |$any.values, :context(Hash.new), :current_context ))
                       }, :%context) {
    my $current_context = %context{ $any.WHERE };
    self.list-to-ast(|$any.values, :%context, :$current_context);
}


subset SequenceOfExpressions of Positional;
# !!! multi method to ast must be in a specific order
multi method to-ast(SequenceOfExpressions $any, :%context) {
    # say "SequenceOfExpressions";
    Scheme::AST::Expressions.new:
        context     => %context{ $any.WHERE },
        expressions => | map { self.to-ast( $_, :%context ) }, $any.values ;
}

## ATOMS
# !!! multi method to ast must be in a specific order
multi method to-ast(Scheme::AST::Symbol $sym, :%context) {
    # say "Identifier";
    # TODO maybe this: $sym.context( %context{ $sym.WHERE } );
    return $sym;
    # Scheme::AST::Symbol.new:
    #     context    => %context{ $any.WHERE },
    #     identifier => $any;
}

# !!! multi method to ast must be in a specific order
multi method to-ast($any, :%context) {
    # say "default", $any.WHAT;
    $any;
}

sub clone-ast($ast, %replacements) {
    my $clone = $ast.clone;
    if $clone ~~ Scheme::AST {
        for $clone.^attributes(:local) -> $attr {
            my $value = $attr.get_value($clone);
            my $cv;
            if $value ~~ Positional {
                $cv = Array.new;
                for @$value {
                    $cv.append(
                        $_ ~~ Scheme::AST::Symbol
                        ?? %replacements{ $_.identifier }
                        !! clone-ast($_, %replacements)
                    );
                }
            } else {
                $cv = $value ~~ Scheme::AST::Symbol
                ?? %replacements{ $value.identifier }
                !! clone-ast($value, %replacements);
            }

            $attr.set_value($clone, $cv);
        }
    }

    return $clone;
}


