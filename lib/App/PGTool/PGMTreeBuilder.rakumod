use App::PGTool::PGTreeBuilder;

#| Populate a PGTree from a PGMGrammar
unit class App::PGTool::PGMTreeBuilder does PGTreeBuilder is export;

use App::PGTool::PGTree :DEFAULT, :API;

method class-mapping($/) {
   my $lcls  = decompose-name $<name-lhs>.Str;
   my $rcls  = decompose-name $<name-rhs>.Str;

   my $lhs   = $.tree.lhs.declare(|$lcls<package class>);

   # since any prior declarations will have been on the left side of
   # the tree (as RHS class names are mentioned only in class mappings)
   my $class = $lhs.class;
   
   my $rhs   = $.tree.rhs.declare(|$rcls<package class>, :$class);

   $class.implicit = False;
   $class.lhs      = $lhs;
   $class.rhs      = $rhs;
   
   make $class;
}

method block($/) {
   $<class-mapping>.made.members = $<member-mapping>.map(*.made);
}
