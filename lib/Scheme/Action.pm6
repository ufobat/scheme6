use Scheme::AST;

class Scheme::Action {
    method TOP($/) {
        make Scheme::AST::Expressions.new:
        expressions => $<expression>>>.made
    }

    multi method expression($/ where $<atom>) {
        make $<atom>.made;
    }
    multi method expression($/ where $<list>) {
        make $<list>.made;
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

    multi method list($/ where $<definition>) {
        make $<definition>.made;
    }
    multi method list($/ where $<conditional>) {
        make $<conditional>.made;
    }
    multi method list($/ where $<proc-call>) {
        make $<proc-call>.made;
    }

    method definition($/) {
        make Scheme::AST::Definition.new:
        identifier =>  ~$<identifier>,
        expression => $<expression>.made
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
}
