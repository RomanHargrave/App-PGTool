use App::PGTool::PGTreePrinter;

unit class App::PGTool::PGTPrinter does PGTreePrinter is export;

use App::PGTool::PGTree :DEFAULT, :API;

# Print a package
multi method print(::?CLASS $_: Node $dst, ClassTag:U, |p(:$depth = -1, :$side, |)) {
   my $ws = .ws: |p;
   my @children = $dst.children.values.grep(*.explicit);

   $.io.print: $ws, 'package ', $dst.name, ' {' unless $dst.root;

   $.io.print: "\n" if @children && !$dst.root;
   
   for @children -> $node {
      .print: $node, |p, :depth($depth + 1);
      $.io.print: "\n";
   }

   unless $dst.root {
      $.io.print: $ws, '}';
      $.io.print: ' # package ', $dst.name if @children;
   }
}

# Print a class
multi method print(::?CLASS $_: Node $dst, ClassTag:D $c, |p(:$depth = 0, :$side, |)) {
   my $ws       = .ws: |p;
   my $src      = $c.node(src $dst.side);
   my @children = $dst.children.values.grep(*.explicit);
   my $has-body = @children || $c.members;
   
   $.io.print: $ws, 'class ', $dst.name, ' from ', $src.full-name, ' {';

   $.io.print: "\n" if $has-body;
   
   for @children -> $node {
      .print: $node, |p, :depth($depth + 1);
      $.io.print: "\n";
   }

   for $c.members -> $member {
      .print: $member, |p, :depth($depth + 1);
      $.io.print: "\n";
   }

   $.io.print: $ws, '}';
   $.io.print: ' # class ', $src.name if $has-body;
}
