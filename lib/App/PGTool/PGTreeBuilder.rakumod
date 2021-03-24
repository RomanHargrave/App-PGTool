unit role App::PGTool::PGTreeBuilder is export;

use App::PGTool::PGTree :DEFAULT, :API;

has PGTree $.tree .= new;

sub decompose-name(Str $name) is pure is export {
   my @package = $name.split('.');
   my @class   = @package.pop.split('$');
   return { :@package, :@class };
}

method type($/) {
   # Types in the PGM format always refer to names from the LHS tree
   # This allows use to eagerly create the tag for this type
   make Type.new(
      :dimension(+$<array-flag>),
      :class($.tree.lhs.declare(|decompose-name($<name>.Str)<package class>, :implicit).class)
   )
}

# Field Mappings

method field($/) {
   # Prepare partial parameters for a Field member
   make {
      :type($<type>.made),
      :name-lhs($<name-lhs>.Str)
   }
}

method member-mapping:sym<field>($/) {
   make Field.new(
      :name-rhs($<name-rhs>.Str),
      |$<field>.made
   )
}

# Method Mappings

method method($/) {
   # We can always safely assume method to be on the LHS of the tree
   # as the RHS in this format does not encode signature information
   make {
      :name-lhs($<name-lhs>.Str),
      :return-type($<return-type>.made),
      :param-types($<param-types>.map(*.made).cache)
   }
}

method member-mapping:sym<method>($/) {
   make Method.new(
      :name-rhs($<name-rhs>.Str),
      |$<method>.made
   )
}

method TOP($/) {
   make $.tree;
}
