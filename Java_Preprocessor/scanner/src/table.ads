with states_type;
use states_type;

package table is

   subtype Identifier is Character with Static_Predicate =>
      Identifier in 'a' .. 'z' | 'A' .. 'Z' | '_' | '$';
   
   subtype Numeric is Character with Static_Predicate =>
      Numeric in '0' .. '9';
   
   subtype White is Character with Static_Predicate =>
     White in ' ' | ASCII.HT | ASCII.LF | ASCII.CR ;
   
   subtype Nodes is States range Start .. Variable;

   subtype Comment is Nodes range Comment1 .. CommentDone;

   subtype Final is Nodes with Static_Predicate =>
      Final in OpenP .. URshiftEqual;

   Token_Table : constant array (Nodes, Character) of States :=(
      Start => (White => Start, Numeric => Number, Identifier => Variable,
               '(' => OpenP, ')' => CloseP,'[' => OpenB, ']' => CloseB, '{' => OpenC, '}' => CloseC, '~' => Tilde,
               ';' => Semi, '?' => Question, ','=> Comma, '@' => Atsym, '.' => Dot, ':' => Colon, '=' => Assign,
               '>' => Great, '<' => Less, '!' => Exclaim, '&' => Ampersand, '|' => Bar, '^' => Carrot,
               '%' => Modulo, '+' => Plus, '-' => Minus, '*' => Times, '/' => Divide, '"' => StringStart, ''' => CharStart, others => Error),
      Final => (others => Done),
      Dot => ('.' => Dot2, others => Done),
      Dot2 => ('.' => Elipse, others => Error),
      Colon => (':' => Colon2, others => Done),
      Assign => ('=' => Equal, others => Done),
      Great => ('=' => GreatEq, '>' => Rshift, others => Done),
      Less => ('=' => LessEq, '<' => Lshift, others => Done),
      Exclaim => ('=' => ExclaimEq, others => Done), 
      Plus => ('+' => Inc, '=' => PlusEqual, others => Done),
      Minus => ('-' => Dec, '=' => MinusEqual, '>' => Arrow, others => Done),
      Times => ('=' => TimesEqual, others => Done),
      Divide => ('=' => DivideEqual, '/' => Comment1, '*' => Comment2, others => Done),
      Ampersand => ('=' => AmpersandEqual, '&' => Land, others => Done),
      Bar => ('=' => BarEqual, '|' => Lor, others => Done),
      Carrot => ('=' => CarrotEqual, others => Done),
      Modulo => ('=' => ModuloEqual, others => Done),
      Lshift => ('=' => LshiftEqual, others => Done),
      Rshift => ('=' => RshiftEqual, '>' => URshift, others => Done),
      URshift => ('=' => URshiftEqual, others => Done),
      Number => (Numeric => Number, others => Done),
      Variable => (Identifier => Variable, Numeric => Variable, others => Done),
      Comment1 => (ASCII.LF | ASCII.CR => Start, others => Comment1),
      Comment2 => ('*' => CommentIn, others => Comment2),
      CommentIn => ('/' => Start, '*' => CommentIn, others => Comment2),
      CommentDone => (others => Start),
      StringStart => ('"' => StringEnd, '\' => StringIn, others => StringStart),
      StringIn => (others => StringStart), 
      StringEnd => (others => Done),
      CharStart => ('\' => CharEscape, others => Charmid),
      CharEscape => (others => Charmid),
      Charmid => (''' => CharEnd, others => Error),
      CharEnd => (others => Done),
      others => (others => Error)
   );

end table;