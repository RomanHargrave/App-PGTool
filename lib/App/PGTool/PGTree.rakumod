#| Tree that understands semantic meaning of FQDNs and lays them out
#| accordingly
unit class App::PGTool::PGTree is export;

class ClassTag { ... };

class Node {
   has Node $.parent;

   #| Class data, if this node is a class
   has ClassTag $.class is rw;

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

   #| Write tree out as package/class heirarchy
   method tree-rep(Int $depth = 0, |p(:$indent = 2, :$lhs?, :$rhs?, |)) {
      die "Must specify one of :rhs or :lhs when calling Node.tree-rep" unless $lhs.so ^ $rhs.so;

      when $.root {
         %.children.values.grep(*.explicit)>>.tree-rep($depth, |p).join("\n");
      }

      when self.explicit.not { () }
      when $.parent.class { die "Node.tree-rep called for sub-class node" }
      
      when $.class.so {
         # this should prevent Node.tree-rep from getting called on sub-class nodes
         $.class.tree-rep($depth, |p);
      }

      default {
         my $shift = ' ' x ($depth * $indent);
         # these will indent themselves as it's likely more efficient
         my $body  = %.children.values>>.tree-rep($depth + 1, |p).join("\n");
         
         ~ $shift ~ 'package ' ~ $.name ~ ' {'
         ~ ("\n" ~ $body ~ "\n" if %.children)
         ~ $shift ~ '}' ~ (' # package ' ~ $.name if %.children)
      }
   }

   #| Write tree out as proguard map
   method map-rep(|p(:$lhs?, :$rhs?)) {
      die "Must specify one of :rhs or :lhs when calling Node.map-rep" unless $lhs.so ^ $rhs.so;
      
   }
   
   # Tree building functions

   multi method declare(Node:D $parent: [Str $name, *@package], $class, |p(:class($class-tag)?, *%x)) {
      #say "PACKAGES   | Node.declare([$name {@package.gist}], {$class.gist}, {%x.gist})";
      given %.children{$name} //= Node.new: :$parent, :$name {
         .declare: @package, $class, |p;
      }
   }
   
   multi method declare(Node:D $parent: [], [Str $name, *@class], |p(:$class?, *%x)) {
      #say "CLASSES    | Node.declare([], [$name {@class.gist}], {%x.gist})";
      given %.children{$name} //= Node.new: :$parent, :$name {
         .class //= ClassTag.new: :implicit, :lhs($_);
         .declare: [], @class, |p;
      }
   }

   multi method declare(Node:D $parent: [], [Str $name], :$implicit, :$class) {
      #say "CLASS TAIL | Node.declare([], [$name])";
      given %.children{$name} //= Node.new: :$parent, :$name {
         .class //= ($class // ClassTag.new: :$implicit, :lhs($_));
         $_;
      }
   }

   method !joiner {
      when $.class { '$' }
      '.';
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

   #| SOURCE name when renaming TO RHS (forward)
   multi method src-name(:$rhs!) { $.name-lhs };
   #| DESTINATION name when renaming TO RHS (forward)
   multi method dst-name(:$rhs!) { $.name-rhs };

   #| SOURCE name when renaming TO LHS (reverse)
   multi method src-name(:$lhs!) { $.name-lhs };
   #| DESTINATION name when renaming TO LHS (reverse)
   multi method dst-name(:$lhs!) { $.name-rhs };
}

#| A type, possibly an array
class Type is export(:API) {
   has ClassTag $.class;
   has Int      $.dimension = 0;

   method rep(|p) {
      "{$.class.rep(|p)}{'[]' x $.dimension}"
   }
}

class Field does Member is export(:API) {
   has Type $.type;

   method rep(|p) {
      "{$.type.rep(|p)} {self.src-name(|p)} -> {self.dst-name(|p)}"
   }
}

class Method does Member is export(:API) {
   has Type $.return-type;
   has      $.param-types;

   method rep(|p) {
      my $params = $.param-types>>.rep(|p).join(',');
      "{$.return-type.rep(|p)} {self.src-name(|p)}($params) -> {self.dst-name(|p)}"
   }
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
   multi method node(:$lhs!) { $.lhs }

   #| Get the RHS (destination) node
   #| If there is no destination node because this ClassTag was created
   #| to satisfy a reference, it's destination IS its source.
   multi method node(:$rhs!) {
      # We must fall back to LHS as a class may not always have a RHS name, this can
      # happen when a field or method references a type that isn't itself being renamed.
      # This will only happen with RHS names.
      # A ClassTag should always have an LHS (source) value
      $.rhs // $.lhs
   }

   #| Get the full name of this node in terms of a given tree side.
   method rep(|p) { self.node(|p).full-name }

   #| Get the SOURCE node in terms of renaming TO RHS (forward)
   multi method src(:$rhs!) { self.node(:lhs) }
   #| Get the DESTINATION node in terms of renaming TO RHS (forward)
   multi method dst(:$rhs!) { self.node(:rhs) }

   #| Get the SOURCE node in terms of renaming TO LHS (reverse)
   multi method src(:$lhs!) { self.node(:rhs) }
   #| Get the DESTINATION node in terms of renaming TO LHS (reverse)
   multi method dst(:$lhs!) { self.node(:lhs) }

   #| Get the textual representation of this class in a structured format.
   #| SOURCE names are fully qualified, types refer to SOURCE names
   method tree-rep(Int $depth = 0, |p(:$indent = 2, |)) {
      my $shfo = ' ' x ($depth * $indent);
      my $sw   = ($depth + 1) * $indent;
      my $shfi = ' ' x $sw;
      
      my $src = self.src: |p;
      my $dst = self.dst: |p;
      my $src-name = $src.full-name;
      my $dst-name = $dst.name;
      my $children = $dst.children.values>>.class.grep: *.implicit.not;
      my $has-body = $children || @.members;

      ~ $shfo ~ 'class ' ~ $dst-name ~ ' aka ' ~ $src-name ~ ' {'
      ~ ("\n" ~ @.members>>.rep(|p).join("\n").indent($sw) if @.members)
      ~ ("\n" ~ $children>>.tree-rep($depth + 1, |p).join("\n") if $children)
      ~ ("\n$shfo" if $has-body) ~ '}' ~ (" # class $dst-name" if $has-body)
   }
}

has Node $.lhs = Node.new: :root;
has Node $.rhs = Node.new: :root;

multi method root(:$lhs!) { $.lhs }
multi method root(:$rhs!) { $.rhs }

method tree-rep(|p) { self.root(|p).tree-rep(|p); }
