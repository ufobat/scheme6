use Scheme::AST;
use Scheme::Context;

class Scheme::Action {
    has %.context;

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
        my $data    = [ $<expression>>>.made ];
        my $context = get-context $/, :is-file;
        %!context{ $data.WHERE } = $context;
        make $data;
        # make $data but Scheme::Contextual[$data, $context];
        # make Scheme::DataWithContext.new(:$data, :$context);
    }

    multi method expression:sym<atom> ($/) {
        my $data    = $<atom>.made;
        my $context = get-context $/;
        %!context{ $data.WHERE } = $context;
        make $data;
        # make $data but Scheme::Contextual[$data, $context];
        # make Scheme::DataWithContext.new(:$data, :$context);
    }
    multi method expression:sym<list>($/)  {
        my $data    = [ $<expression>>>.made ];
        my $context = get-context $/;
        %!context{ $data.WHERE } = $context;
        make $data;
        # make $data but Scheme::Contextual[$data, $context];
        # make Scheme::DataWithContext.new(:$data, :$context);
    }

    multi method atom:sym<identifier>($/) {
        make Scheme::AST::Symbol.new(
            identifier => ~ $/,
            context => get-context $/,
        )
    }
    multi method atom:sym<build-in>($/) {
        make Scheme::AST::Symbol.new(
            identifier => ~ $/,
            context => get-context $/,
        )
    }
    multi method atom:sym<number>($/)      { make + $/ }
    multi method atom:sym<boolean>($/)     { make $/ eq '#t' }
    multi method atom:sym<string>($/) {
        make ~ $/<string-char>.map(*.made).join();
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
