use v6;
unit module Scheme::AST::Dumper;
use Scheme::AST;
use Scheme::Context;

use Data::Dump::Tree;
use Data::Dump::Tree::Enums;

role AstDumper {
    multi method get_header(Scheme::AST $ast where {$_.^can('identifier')}) {
        return $ast.identifier, '.' ~ $ast.^name;
    }
    multi method get_elements(Scheme::AST $ast) {
        return callsame.grep: { $_[0] ne '$.identifier' };
    }
}

our sub dump-ast($ast, :$skip-context) is export {
    state $ddt = Data::Dump::Tree.new(
        :display_address(DDT_DISPLAY_NONE)
    ) does AstDumper;

    my @header_filters   = ();

    if $skip-context {
        # needs to be multi
        multi sub skip-context (
            $dumper, \r, Scheme::Context $s,
            ($depth, $path, $glyph, @renderings),
            (\k, \b, \v, \f, \final, \want_address)
        ) {
            r = Data::Dump::Tree::Type::Nothing;
        };
        push @header_filters, &skip-context;
    }

    $ddt.ddt( $ast, :@header_filters );
}
