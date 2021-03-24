#| Tree that understands semantic meaning of FQDNs and lays them out
#| accordingly
unit class App::PGTool::PGTree is export;

class ClassTag is export(:API) { ... };

# What side of the tree something is on
enum TreeSide is export(:API) <LHS RHS>;

multi src(LHS) is export(:API) is pure { RHS }
multi src(RHS) is export(:API) is pure { LHS }

multi dst(LHS) is export(:API) is pure { LHS }
multi dst(RHS) is export(:API) is pure { RHS }

class Node is export(:API) {
   has Node $.parent;

   #| Class data, if this node is a class
   has ClassTag $.class is rw;

   has TreeSide $.side is required;

   #| Node name
   has Str $.name;

   #| Is root node
   has $.root = False;

   #| Child nodes
   has %.children;

   method traverse(&visit) {
      visit(self) unless $.root; # by no means elegant - just lazy at this point
      %!children.values>>.traverse(&visit);
   }

   method explicit is pure {
      return True if $.class.?implicit.not;
      return True if .explicit for %!children.values;
   }
   
   # Tree building functions

   method !new-child($parent: Str $name) is pure {
      Node.new: :$parent, :$name, :$.side;
   }
   
   multi method declare(Node:D $parent: [Str $name, *@package], $class, |p(:class($class-tag)?, *%x)) {
      #say "PACKAGES   | Node.declare([$name {@package.gist}], {$class.gist}, {%x.gist})";
      given %.children{$name} //= $parent!new-child($name) {
         .declare: @package, $class, |p;
      }
   }
   
   multi method declare(Node:D $parent: [], [Str $name, *@class], |p(:$class?, *%x)) {
      #say "CLASSES    | Node.declare([], [$name {@class.gist}], {%x.gist})";
      given %.children{$name} //= $parent!new-child($name) {
         .class //= ClassTag.new: :implicit, :lhs($_);
         .declare: [], @class, |p;
      }
   }

   multi method declare(Node:D $parent: [], [Str $name], :$implicit, :$class) {
      #say "CLASS TAIL | Node.declare([], [$name])";
      given %.children{$name} //= $parent!new-child($name) {
         .class //= ($class // ClassTag.new: :$implicit, :lhs($_));
         $_;
      }
   }

   method !joiner {
      if $.class { '$' }
      else { '.' }
   }
   
   #| Get name by walking up tree
   #| This varient represents the base case (undefined parent)
   multi method full-name(Node:U: Str $n = '') { $n }
   #| Get name by walking up tree, prepending to $lhs
   multi method full-name(Node:D: Str $rhs)    { $.parent.full-name(($.name ~ self!joiner unless $.root) ~ $rhs) }
   multi method full-name(Node:D:)             { $.parent.full-name($.name) }
}

role Member {
   has Str $.name-lhs;
   has Str $.name-rhs;

   multi method name(LHS) { $.name-lhs; }
   multi method name(RHS) { $.name-rhs; }
}

#| A type, possibly an array
class Type is export(:API) {
   has ClassTag $.class;
   has Int      $.dimension = 0;
}

class Field does Member is export(:API) {
   has Type $.type;
}

class Method does Member is export(:API) {
   has Type $.return-type;
   has      $.param-types;
}

#| ClassTags serve to convey information about member
#| tag ownership. ClassTags need distinct identity because
#| they are referenced from both trees.
class ClassTag is export(:API) {
   #| Tree node representing the OLD path
   #| for this tag.
   has Node $.lhs is rw = Nil;

   #| Tree node representing the NEW path
   #| for this tag.
   has Node $.rhs is rw = Nil;

   has $.implicit is rw = False;

   multi method implicit(ClassTag:U:) { True }
   multi method implicit(ClassTag:D:) { return-rw $!implicit }

   #| Class members
   has @.members is rw;

   #| Get the LHS (source) node
   multi method node(LHS) { $.lhs }

   #| Get the RHS (destination) node
   #| If there is no destination node because this ClassTag was created
   #| to satisfy a reference, it's destination IS its source.
   multi method node(RHS) {
      # We must fall back to LHS as a class may not always have a RHS name, this can
      # happen when a field or method references a type that isn't itself being renamed.
      # This will only happen with RHS names.
      # A ClassTag should always have an LHS (source) value
      $.rhs // $.lhs
   }
}

has Node $.lhs = Node.new: :root, :side(LHS);
has Node $.rhs = Node.new: :root, :side(RHS);

multi method root(LHS) { $.lhs }
multi method root(RHS) { $.rhs }

# method tree-rep(|p) { self.root(|p).tree-rep(|p); }
