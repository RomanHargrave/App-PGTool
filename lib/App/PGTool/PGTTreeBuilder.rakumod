use App::PGTool::PGTreeBuilder;

unit class App::PGTool::PGTTreeBuilder does PGTreeBuilder is export;

use App::PGTool::PGTree :DEFAULT, :API;

method package-block($/) {
   # we build RHS in reverse for this tree!
   # by the time this is called for a block, all nested
   # blocks have been computed, this is guaranteed to include
   # all classes beneath this block, so we can decorate them with
   # tags and nodes

   my $name = $<name-rhs>.Str;

   make my $node = Node.new(
      :side(RHS), # all blocks represent RHS-first data
      :$name
   );

   # connect children
   for (|$<package-block>, |$<class-block>).map(*.made) {
      .parent = $node;
      $node.children{.name} = $_;
   }
}

method class-block($/) {
   my $lcls  = decompose-name $<name-lhs>.Str;
   my $name  = $<name-rhs>.Str;
   
   my $lhs   = $.tree.lhs.declare(|$lcls<package class>);
   my $class = $lhs.class;

   make my $rhs = Node.new(
      :side(RHS),
      :$name,
      :$class
   );

   $class.implicit = False;
   $class.lhs      = $lhs;
   $class.rhs      = $rhs;

   # Attach members
   $class.members  =  $<member-mapping>.map: *.made;
   
   # Deal with sublcasses
   for $<class-block>.map(*.made) {
      .parent = $rhs;
      $rhs.children{.name} = $_;
   }
}

method TOP($/) {
   # Connect all top-level nodes to the root RHS node
   # LHS will have already been built implicitly
   for (|$<package-block>, |$<class-block>).map(*.made) {
      .parent = $.tree.rhs;
      $.tree.rhs.children{.name} = $_;
   }

   make $.tree;
}
