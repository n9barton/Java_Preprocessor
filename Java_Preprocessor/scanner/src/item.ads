with states_type, Ada.Streams.Stream_IO;
use states_type, Ada, Ada.Streams;

package item is
   
   type Var_Type is (t_none, t_byte, t_short, t_integer, t_long, t_float, t_double, t_character, t_boolean, t_string );

   function Get_Type(Item : String) return Var_Type;

   type Token_Item_Data;

   type Token_Item_Access is access all Token_Item_Data;

   type Token_Item_Data (Length : Positive) is record
      ID : String(1 .. Length) := (others => ' ');
      ID_Type : States := Start;
      Pos : Positive := 1;
      Var_T : Var_Type := t_none;
   end record;

   type Token_Record is private;

   type Token_Record_Access is access all Token_Record;

   procedure Push(Item : in Token_Item_Data);
   
   function Pop return Token_Item_Data;

   procedure Release(Str : in Stream_IO.Stream_Access);

private

   type Token_Record is record
      Token : Token_Item_Access;
      Next : Token_Record_Access;
   end record;

end item;