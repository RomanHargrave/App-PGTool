unit role App::PGTool::PGTreePrinter is export;

use App::PGTool::PGTree :DEFAULT, :API;

has $.io = $*OUT;

# Generate whitespace
method ws(Int :$sw = 2, Int :$depth = 0) is pure {
   ' ' x ($sw * $depth)
}

method type-rep(Type $t, TreeSide :$side) {
   $t.class.node($side).full-name ~ '[]' x $t.dimension
}

proto method print(
   Int :$sw = 2,    #= Width of an indent level
   Int :$depth = 0, #= Depth to print at
   |
) { ... }

#| Print a node that has a defined class tag
multi method print(Node, ClassTag:D, |) { ... }

#| Print a node that has an undefined class tag
multi method print(Node, ClassTag:U, |) { ... }

#| Print a node, either with or without a class
multi method print(Node $n, |p(TreeSide :$side?, *%)) {
   self.print($n, $n.class, |p, :side($n.side)) if $n.explicit
}

#| Print a type signature (class name, followed by [] for each dimension)
#| This assumes LHS
multi method print(Type $t, |p) {
   $.io.print: self.type-rep($t, |p)
}

#| Print a field
multi method print($_: Field $f, |p(:$side, |)) {
   $.io.print: .ws(|p);             # Print whitespace leading up to the field declaration
   .print($f.type, |p); # Print type signature
   $.io.print(
      ' ',
      $f.name(src $side),     # Print source name
      ' -> ',
      $f.name(dst $side),     # Print destination name
   )
}

#| Print a method
multi method print($_: Method $m, |p(:$side, |)) {
   $.io.print: .ws(|p); # Print whitespace leading up to the method declaration
   .print: $m.return-type, |p;  # Print the return type of the method
   $.io.print(
      ' ',                         
      $m.name(src $side),          # Print the source name
      '(', $m.param-types.map({self.type-rep($_, |p)}).join(','), ')',
      ' -> ',
      $m.name(dst $side),          # Print the destination name
   )
}
