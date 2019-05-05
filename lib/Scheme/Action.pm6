use Scheme::AST;
use Scheme::Context;

class Scheme::Action {

    sub get-context($/, :$is-file = False) {
        my $length = $/.Str.chars;
        my $parsed = $/.target.substr(0, $/.pos - $length);
        my @lines  = $parsed.lines;
        my $line   = @lines.elems;
        my $column = $line == 0
            ?? 0
            !! @lines[*-1].chars;
        return Scheme::Context.new(:$line, :$column, file => 'NYI', :$is-file);
    }

    method TOP($/) {
        make [  $<expression>>>.made ] but Scheme::Contextual[ get-context($/, :is-file) ];
    }

    multi method expression:sym<atom> ($/) {
        make $<atom>.made but Scheme::Contextual[ get-context($/) ];
    }
    multi method expression:sym<list>($/)  {
        make [ $<expression>>>.made ] but Scheme::Contextual[ get-context($/) ];
    }

    multi method atom:sym<identifier>($/)  { make ~ $/ }
    multi method atom:sym<build-in>($/)    { make ~ $/ }
    multi method atom:sym<number>($/)      { make + $/ }
    multi method atom:sym<boolean>($/)     { make $/ eq '#t' }
    multi method atom:sym<string>($/) {
        make '"' ~ $/<string-char>.map(*.made).join() ~ '"';
    }
    multi method atom:sym<character>($/) {
        make $/ eq '#\\newline' ?? "\n" !! $/ eq '#\\space' ?? ' ' !! $/.substr(2,1);
    }

    method string-char($/) {
        make $/ eq '\\\\'
        ??  '\\'
        !!  $/ eq '\\"' ?? '"' !! ~$/
    }
}
