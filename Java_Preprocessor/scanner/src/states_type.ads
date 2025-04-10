package states_type is
   type States is (Done, Error, Class, Res, Start, OpenP, CloseP, OpenC, CloseC, OpenB, CloseB, Semi, Comma, Atsym, Tilde, Question,
      GreatEq, LessEq, ExclaimEq, Lor, Land, Equal, Colon2, Elipse, Arrow, Inc, Dec, PlusEqual, MinusEqual, TimesEqual, DivideEqual,
      AmpersandEqual, BarEqual, CarrotEqual, ModuloEqual, RshiftEqual, LshiftEqual, URshiftEqual, Dot, Dot2, Colon, Assign, Great, Less, Exclaim, 
      Plus, Minus, Times, Divide, Ampersand, Bar, Carrot, Modulo, Lshift, Rshift, URshift, StringStart, StringIn, StringEnd, Number,
      Comment1, Comment2, CommentIn, CommentDone, CharStart, CharEscape, Charmid, CharEnd, Variable);


end states_type;