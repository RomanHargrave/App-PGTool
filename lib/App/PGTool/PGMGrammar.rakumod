#| Grammar for ProGuard Map Files
unit grammar App::PGTool::PGMGrammar is export;

#| Basic JVM Name
token name { <[a..zA..Z_0..9$<>.-]>+ }

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

#| A class mapping, opens a member mapping block
rule class-mapping { <name-lhs=.name> '->' <name-rhs=.name> }

#| A member mapping, which describes the relationship between either a method or field
#| and its updated name
proto rule member-mapping { * }
rule member-mapping:sym<field>  { <field>  '->' <name-rhs=.name> }
rule member-mapping:sym<method> { <method> '->' <name-rhs=.name> }

#| A mapping block. This opens with a class mapping followed by a colon and nl
#| Each following line is lead by at least one ws and a member mapping, repeated
token block {
   <class-mapping> ':' <.ws>
   <member-mapping>* %% <.ws> 
}

token TOP { <block>+ }
