use App::PGTool::PGTreePrinter;

unit class App::PGTool::PGMPrinter does PGTreePrinter is export;

use App::PGTool::PGTree :DEFAULT, :API;

multi method print(::?CLASS $_: Node $dst, ClassTag:U, |p) {
   for $dst.children.values.grep(*.explicit) -> $child {
      .print: $child, |p;
   }
}

multi method print(::?CLASS $_: Node $dst, ClassTag:D $c, |p) {
   my $src = $c.node(src $dst.side);

   $.io.print: $src.full-name, ' -> ', $dst.full-name, ":\n";

   for $c.members -> $member {
      .print: $member, |p, :1depth;
      $.io.print: "\n";
   }
}
