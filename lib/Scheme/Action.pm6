use Scheme::AST;

class Scheme::Action {
    method TOP($/) {
        make Scheme::AST::Expressions.new:
        expressions => $<expression>>>.made
    }

    multi method expression($/ where $<atom>) {
        make $<atom>.made;
    }
    multi method expression($/ where $<list-expression>) {
        make $<list-expression>.made;
    }

    multi method atom($/ where $<variable>) {
        make $<variable>.made;
    }
    multi method atom($/ where $<constant>) {
        make $<constant>.made;
    }
    method variable($/) {
        make Scheme::AST::Variable.new: identifier => ~$/;
    }

    multi method constant($/ where $<number>) {
        make $<number>.made;
    }
    multi method constant($/ where $<string>) {
        make $<string>.made;
    }
    multi method constant($/ where $<character>) {
        make $<character>.made;
    }
    multi method constant($/ where $<boolean>) {
        make $<boolean>.made;
    }

    method number($/) { make + $/ }
    method string($/) {
        make $/<string-char>.map(*.made).join();
    }
    method string-char($/) {
        make $/ eq '\\\\'
        ??  '\\'
        !!  $/ eq '\\"' ?? '"' !! ~$/
    }
    method character($/) {
        make $/ eq '#\\newline' ?? "\n" !! $/ eq '#\\space' ?? ' ' !! $/.substr(2,1);
    }
    method boolean($/) {
        make $/ eq '#t';
    }

    multi method list-expression($/ where $<definition>) {
        make $<definition>.made;
    }
    multi method list-expression($/ where $<conditional>) {
        make $<conditional>.made;
    }
    multi method list-expression($/ where $<proc-or-macro-call>) {
        make $<proc-or-macro-call>.made;
    }
    multi method list-expression($/ where $<lambda>) {
        make $<lambda>.made;
    }
    multi method list-expression($/ where $<quote>) {
        make $<quote>.made;
    }
    multi method list-expression($/ where $<define-syntax>) {
        make $<define-syntax>.made;
    }

    method definition:sym<simple>($/) {
        make Scheme::AST::Definition.new:
        identifier =>  ~$<identifier>,
        expression => $<expression>.made
    }
    method definition:sym<lambda>($/) {
        make Scheme::AST::Definition.new(
            identifier =>  ~$<def-name>,
            expression => Scheme::AST::Lambda.new(
                params => | $<lambda-identifier>.map( ~* ),
                expressions => $<expression>>>.made
            )
        );
    }

    method conditional($/) {
        make Scheme::AST::Conditional.new:
        expression => $<test>.made,
        conseq => $<conseq>.made,
        alt => $<alt>.made
    }

    multi method proc-or-macro-call:sym<simple>($/) {
        my $identifier = ~ $/<identifier>;
        my @expressions = | $<expression>>>.made;

        my $ast;
        my $macro-found = %*Macro{ $identifier }:exists;

        if $macro-found {
            my $macro-ast = %*Macro{ $identifier };

            for $macro-ast.transformer-spec -> $transformer-spec {
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

                    multi get-identifier(Scheme::AST::Variable $x) { $x.identifier }
                    multi get-identifier($x) { die "did expect something else", $x.perl }

                    my @source-names = @source.map: *.&get-identifier;
                    # say join "\n", "<SOURCES>", @source-names, "</SOURCES>\n";
                    # does it match??
                    my $underscore = @source-names.shift;
                    unless $underscore eq '_' {
                        note "transformer-spec is confusing: expected '_' but got '$underscore'";
                        return;
                    }
                    # say join "\n", "<expressions>", @expressions.map(*.perl), "<expressions>\n";
                    unless @expressions.elems == @source-names.elems {
                        note "number of elements missmatch";
                        return;
                    }

                    sub syntax-ignore(Str $src-keyword --> Bool) { so @literals.first: $src-keyword }

                    # say "           SOURCE -> EXPRESSION";
                    for @expressions Z @source-names -> ($e, $s) {
                        unless syntax-ignore $s {
                            %replaceables{ $s } = $e;
                        }
                        # say "looop: ", $s.fmt('%10s'), " -> ", $e;
                    }

                    # say %replaceables;
                    return %replaceables;
                }

                my @source   = $transformer-spec.source;
                my @literals = $transformer-spec.literals;

                if my %replaceables = macro-matches(@expressions, @literals, @source) {
                    # replaceables / replacements ?
                    # replacables = $source without literals
                    my %*AST-REPLACE = %replaceables;
                    $ast = $transformer-spec.destination.clone();
                    last;
                }
                die 'macro call was invalid'
            }
        } else {
            $ast = Scheme::AST::ProcCall.new:
            identifier => ~$<identifier>,
            expressions => @expressions,
        }
        make $ast;
    }
    multi method proc-or-macro-call:sym<lambda>($/) {
        make Scheme::AST::ProcCall.new:
        lambda => $<lambda>.made,
        expressions => $<expression>>>.made;
    }

    method lambda($/) {
        make Scheme::AST::Lambda.new:
        params => | $<identifier>.map( ~* ),
        expressions => $<expression>>>.made;
    }

    method define-syntax($/) {
        my $ast = Scheme::AST::Macro.new:
        name => ~ $<keyword>,
        transformer-spec => $<transformer-spec>>>.made;

        my $name = $ast.name;
        die "can not redefine macro '$name'" if %*Macro{$name}:exists;
        %*Macro{$name} = $ast;

        make $ast;
    }

    method transformer-spec($/) {
        make Scheme::AST::TransformerSpec.new:
        literals => $<literal>>>.made,
        source => $<src-s-expression>.made,
        destination => $<dst-s-expression>.made;
    }

    method quote($/) {
        make Scheme::AST::Quote.new:
        datum => $<datum>.made;
    }

    multi method datum($/ where $<atom>) {
        make $<atom>.made;
    }
    multi method datum($/ where $<list>) {
        make $<list>.made;
    }

    method list($/) {
        make $<datum>>>.made
    }
}
