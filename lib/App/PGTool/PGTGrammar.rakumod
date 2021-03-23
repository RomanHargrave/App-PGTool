#| Grammar that describes the structured tree (PGT) format
#| Grammar for an alternative ProGuard map
#| syntax that is nested, allowing for easy editing
unit grammar App::PGTool::PGTGrammar is export;

#| Basic JVM Name
token name { <[a..zA..Z_]> <[a..zA..Z_0..9]>* }

token comment { '#' .* $ }

#| Rules that can apply to 
token common-rule { 'rename' }

rule  package-block {
   'package' <name> '{' <.comment>?
   [
      | <package-block>
      | <class-block>
      | <.comment>
   ]?
   '}' <.comment>?
}
