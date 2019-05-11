use v6;
unit module Scheme::AST::Dumper;
use Scheme::AST;

use Data::Dump::Tree;
use Data::Dump::Tree::Enums;

role AstDumper {
    multi method get_header(Scheme::AST::Variable $ast) {
        return $ast.identifier, '.' ~ $ast.^name;
    }
    multi method get_elements(Scheme::AST::Variable $ast) { }
}

our sub dump-ast($ast) is export {
    state $ddt = Data::Dump::Tree.new(
        :display_address(DDT_DISPLAY_NONE)
    ) does AstDumper;

    $ddt.ddt: $ast;
}
