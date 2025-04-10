with Ada.Unchecked_Deallocation, Ada.Streams.Stream_IO;
use Ada, Ada.Streams;

package body item is 

   procedure free_record is new Unchecked_Deallocation(Token_Record, Token_Record_Access);

   procedure free_data is new Unchecked_Deallocation(Token_Item_Data, Token_Item_Access);

   Head, Back : Token_Record_Access := null;

   function Get_Type(Item : String) return Var_Type is
   begin
      return Var_Type'Value("t_" & Item);
   end;

   procedure Push(Item : in Token_Item_Data) is
   begin
      if Back = null then
         Back := new Token_Record'(new Token_Item_Data'(Item), null);
         Head := Back;
      else
         Back.Next := new Token_Record'(new Token_Item_Data'(Item), null);
         Back := Back.Next;
      end if;
   end Push;

   function Pop return Token_Item_Data is
      L : Positive := Back.Token.Length;
      I : String := Back.Token.ID;
      T : States := Back.Token.ID_Type;
      P : Positive := Back.Token.Pos;
      V : Var_Type := Back.Token.Var_T;
      Current : Token_Record_Access := null;
   begin
      if Back /= null then
         Current := Head;
         while Current /= Back loop
            Current := Current.Next;
         end loop;
         free_data(Back.Token);
         free_record(Back);
         Back := Current;
         declare
            Temp : Token_Item_Data := Token_Item_Data'(L, I, T, P, V);
         begin
            return Temp;
         end;
      end if;
      raise Program_Error;
   end Pop;

   procedure Release(Str : in Stream_IO.Stream_Access) is 
      Current : Token_Record_Access := Head;
   begin
      while Current /= null loop
         String'Write(Str, Current.Token.ID & ASCII.LF);
         Current := Current.Next;
         free_data(Head.Token);
         free_record(Head);
         Head := Current;
      end loop;
      Head := null;
      Back := null;
   end Release;


end item;