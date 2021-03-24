# use Grammar::Tracer;
#| Grammar that describes the structured tree (PGT) format
#| Grammar for an alternative ProGuard map
#| syntax that is nested, allowing for easy editing
unit grammar App::PGTool::PGTGrammar is export;

#| Basic JVM Name
token name { <[a..zA..Z_0..9$<>.-]>+ }
token lb { <[\c[LF] \r \r\c[LF]]> }
token comment { '#' <-lb>* }

token array-flag { '[]' }

#| A type name, which is a fully qualified name possibly
#| followed by an array indicator ([])
token type { <name> <array-flag>* }

#| Matches a method signature, which has a return type
token method {
   <return-type=.type> <.ws> <name-lhs=.name> '(' ~ ')' <param-types=.type>* % [ <.ws>? ',' <.ws>? ]
}

#| A member field
rule field { <type> <name-lhs=.name> }

#| A member mapping, which describes the relationship between either a method or field
#| and its updated name
proto rule member-mapping { * }
rule member-mapping:sym<field>  { <field>  '->' <name-rhs=.name> <.comment>? }
rule member-mapping:sym<method> { <method> '->' <name-rhs=.name> <.comment>? }

rule class-block {
   'class' <name-rhs=.name> 'from' <name-lhs=.name> '{'
   [
      | <class-block>
      | <member-mapping>
      | <.comment>
   ]*
   '}' <.comment>?
}

rule package-block {
   'package' <name-rhs=.name> '{'
   [
      | <package-block>
      | <class-block>
      | <.comment>
   ]*
   '}' <.comment>?
}

rule TOP {
   [
      | <package-block>
      | <class-block>
      | <.comment>
   ]+
}
