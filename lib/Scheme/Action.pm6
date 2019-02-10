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

    method identifier($/) {
        make ~$/;
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
    multi method list-expression($/ where $<proc-call>) {
        make $<proc-call>.made;
    }
    multi method list-expression($/ where $<lambda>) {
        make $<lambda>.made;
    }
    multi method list-expression($/ where $<quote>) {
        make $<quote>.made;
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

    method proc-call($/) {
        make Scheme::AST::ProcCall.new:
        identifier => ~$<identifier>,
        expressions => $<expression>>>.made;
    }

    method lambda($/) {
        make Scheme::AST::Lambda.new:
        params => | $<identifier>.map( ~* ),
        expressions => $<expression>>>.made;
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
