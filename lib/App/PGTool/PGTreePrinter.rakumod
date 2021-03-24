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
   die "Bad tree printer state: walking {$n.side} node with tagged side $side" unless $n.side ~~ $side;

   self.print($n, $n.class, |p, :side($n.side)) if $n.explicit
}

#| Print a type signature (class name, followed by [] for each dimension)
#| This assumes LHS
multi method print(Type $t, |p) {
   $.io.print: self.type-rep($t, |p)
}

#| Print a field
multi method print($_: Field $f, |p(TreeSide :$side!, |)) {
   # say "print(Field, |p(TreeSide $side, |)) # src={src $side} dst={dst $side}";
   
   $.io.print: .ws(|p);                   # Print whitespace leading up to the field declaration
   .print: $f.type, |p, :side(src $side); # Print type sig with type from source side
   
   $.io.print(
      ' ',
      $f.name(src $side),     # Print source name
      ' -> ',
      $f.name(dst $side),     # Print destination name
   )
}

#| Print a method
multi method print($_: Method $m, |p(TreeSide :$side!, |)) {
   # say "print(Method, |p(TreeSide $side, |)) # src={src $side} dst={dst $side}";

   $.io.print: .ws(|p);                           # Print whitespace leading up to the method declaration
   .print: $m.return-type, |p, :side(src $side);  # Print return type using src-side type


   $.io.print(
      ' ',                         
      $m.name(src $side),          # Print the source name
      '(', $m.param-types.map({self.type-rep($_, |p, :side(src $side))}).join(','), ')',
      ' -> ',
      $m.name(dst $side),          # Print the destination name
   )
}
