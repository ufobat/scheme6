use v6;
unit module Scheme::AST::Dumper;
use Scheme::AST;
use Scheme::Context;

use Data::Dump::Tree;
use Data::Dump::Tree::Enums;

role AstDumper {
    multi method get_header(Scheme::AST::Variable $ast) {
        return $ast.identifier, '.' ~ $ast.^name;
    }
    multi method get_elements(Scheme::AST::Variable $ast) { }
}

our sub dump-ast($ast, :$skip-context) is export {
    state $ddt = Data::Dump::Tree.new(
        :display_address(DDT_DISPLAY_NONE)
    ) does AstDumper;

    my @header_filters = ();

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

    # TODO
    # 1) If $s has a attribute named 'identifier'
    #    move the identifier to the header
    #    like done in the AstDumper role (which would be obsolte)
    # 2) in the element_filter i need to skip the 'identifier' attribute
    multi sub identifier-to-header (
        $dumper, \r, Scheme::AST $s,
        ($depth, $path, $glyph, @renderings),
        (\k, \b, \v, \f, \final, \want_address)
    ) {
        # TODO
    }

    $ddt.ddt( $ast, :@header_filters );
}
