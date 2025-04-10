with Ada.Text_IO, Ada.Streams.Stream_IO, Ada.Text_IO.Text_Streams, Ada.Command_Line, Table, Item, states_type;
use Ada.Streams.Stream_IO, Table, Item, states_type;

procedure Scanner is

   package T_IO renames Ada.Text_IO;
   package CMD renames Ada.Command_Line;
   
   Output_File : File_Type;
   Output_Stream : Stream_Access;

   Symbol_Table : File_Type;
   Symbol_Stream : Stream_Access;

begin

   declare

      function In_Table(Str : in String; T : out Var_Type) return Boolean is
      begin
         Reset(Symbol_Table, In_File);
         while not End_Of_File(Symbol_Table) loop
            declare
               Sample : Token_Item_Data := Token_Item_Data'Input(Symbol_Stream);
            begin
               if Str = Sample.ID then
                  T := Sample.Var_T;
                  Reset(Symbol_Table, Append_File);
                  return True;
               end if;
            end;
         end loop;
         Reset(Symbol_Table, Append_File);
         return False;
      end In_Table;

      Reserved_Words : array (1 .. 4) of File_Type;

      function is_reserved(Str : in String) return Boolean is
         Value : Natural :=  Boolean'Pos(Str(Str'First) >= 'a') + 
                              Boolean'Pos(Str(Str'First) >= 'f') + 
                              Boolean'Pos(Str(Str'First) >= 'o') + 
                              Boolean'Pos(Str(Str'First) >= 't');
         Reserved_Stream : Stream_Access;
      begin
         if Value = 0 then
            return False;
         end if;

         Reserved_Stream := Stream(Reserved_Words(Positive(Value)));

         while not End_Of_File(Reserved_Words(Value)) loop
            if Str = String'Input(Reserved_Stream) then
               Reset(Reserved_Words(Value));
               return True;
            end if;
         end loop;
         Reset(Reserved_Words(Value));
         return False;
      end is_reserved;

      Input_File : File_Type;
      Input_Stream : Stream_Access;
      Input_Char : Character;
      Input_State : States := Start;
      Input_Position : Count := 1;

      Var_T : Var_Type := t_none;
      Table_Insert : Boolean := False;
   
   begin

      if CMD.Argument_Count /= 1 then
         CMD.Set_Exit_Status (CMD.Failure);
         return;
      end if;
   

      for I in Reserved_Words'Range loop
         Open(Reserved_Words(I), In_File, "scanner/" & I'Image(2..I'Image'Length));
      end loop;

      Create(Symbol_Table, Out_File, "scanner/Variables");
      Symbol_Stream := Stream(Symbol_Table);

      Create(Output_File, Append_File, "scanner/Out");
      Output_Stream := Stream(Output_File);

      Open (Input_File, In_File, CMD.Argument(1));
      Input_Stream := Stream (Input_File);

      for I in 1 .. Size(Input_File) + 1 loop
      
         begin
            Character'Read(Input_Stream, Input_Char);
         exception
            when End_Error => Input_Char := ' ';
            when others => CMD.Set_Exit_Status(CMD.Failure);
         end;

         loop
            case Token_Table(Input_State, Input_Char) is
               when Start =>
                  exit;
               when Done =>
                  T_IO.New_Line;
                  declare
                     Class_Type : String := T_IO.Get_Line;
                     Var_Def : Boolean := Boolean'Value(T_IO.Get_Line);
                     ID : String := T_IO.Get_Line;

                  begin

                     if Input_State = Variable and then Var_Def then
                        Var_T := Get_Type(Class_Type);
                        Table_Insert := True;
                        Token_Item_Data'Output(Output_Stream, (ID'Length, ID, Res, Positive(Input_Position), t_none));

                     elsif Input_State = Variable and then is_reserved(ID) then
                        Token_Item_Data'Output(Output_Stream, (ID'Length, ID, Res, Positive(Input_Position), t_none));

                     elsif Input_State = Variable and then Table_Insert then
                        --Token_Item_Data'Output(Symbol_Stream, (ID'Length, ID, Input_State, Positive(Input_Position), Var_T));
                        Token_Item_Data'Output(Output_Stream, (ID'Length, ID, Input_State, Positive(Input_Position), Var_T));
                     else
                        if Input_State = Semi or Input_State = OpenC then
                           Table_Insert := False;
                           Token_Item_Data'Output(Output_Stream, (ID'Length, ID, Input_State, Positive(Input_Position), t_none));
                        elsif Input_State = Variable and then In_Table(ID, Var_T) then
                           Token_Item_Data'Output(Output_Stream, (ID'Length, ID, Input_State, Positive(Input_Position), Var_T));
                        else
                           Token_Item_Data'Output(Output_Stream, (ID'Length, ID, Input_State, Positive(Input_Position), t_none));
                        end if;
                     end if;
                  end;
                  Input_State := Start;
               when Error => 
                  CMD.Set_Exit_Status (CMD.Failure);
                  return;
               when Comment =>
                  T_IO.Put(Input_Char);
                  T_IO.New_Line;
                  declare
                     T1 : String := T_IO.Get_Line;
                     T2 : String := T_IO.Get_Line;
                  begin
                     null;
                  end;
                  Input_Char := T_IO.Get_Line(2);
                  Input_State := Token_Table(Input_State, Input_Char);
                  while Input_State /= Start loop
                     begin
                        Character'Read(Input_Stream, Input_Char);
                        Input_State := Token_Table(Input_State, Input_Char);
                     exception
                        when End_Error => Input_Char := ASCII.LF;
                        when others => CMD.Set_Exit_Status(CMD.Failure);
                        return;
                     end;
                  end loop;
                  Input_Char := ' ';
               when others =>
                  if Input_State = Start then
                     Input_Position := I;
                  end if;
                  T_IO.Put(Input_Char);
                  Input_State := Token_Table(Input_State, Input_Char);
                  exit;
            end case;
         end loop;
      end loop;
      Close (Input_File);

      for I in Reserved_Words'Range loop
         Close(Reserved_Words(I));
      end loop;
   end;

   Close(Symbol_Table);
   Close(Output_File);

   Open (Output_File,In_File, "scanner/Out");
   Output_Stream := Stream(Output_File);
   
   Open(Symbol_Table, In_File, "scanner/Variables");
   Symbol_Stream := Stream(Symbol_Table);
      
   declare
      Normalized_Code : File_Type;
      Normalized_Stream : Stream_Access;
      Pgm_Name : constant String := CMD.Argument(1)(1 .. CMD.Argument(1)'Length - 5);
      Boolean_Context : Boolean := False;
      Var_T : Var_Type := t_none;
   begin
      
      Create(Normalized_Code, Append_File, "scanner/" & CMD.Argument(1));
      Normalized_Stream := Stream(Normalized_Code);
      
      String'Write(Normalized_Stream, "import java.util.Objects;" & ASCII.LF);
      String'Write(Normalized_Stream, "import java.util.Scanner;" & ASCII.LF);

      while not End_Of_File (Output_File) loop

         declare
            Item : Token_Item_Data := Token_Item_Data'Input(Output_Stream);
         begin
            if Item.ID = "import" or else Item.ID = "package" then
               String'Write(Normalized_Stream, Item.ID & ASCII.LF);
               loop
                  declare
                     Item2 : Token_Item_Data :=  Token_Item_Data'Input(Output_Stream);
                  begin
                     String'Write(Normalized_Stream, Item2.ID & ASCII.LF);
                     exit when Item2.ID_Type = Semi;
                     if Item2.ID_Type /= Variable and Item2.ID_Type /= Dot and Item2.ID_Type /= Times then
                        CMD.Set_Exit_Status (CMD.Failure);
                        return;
                     end if;
                  end;
               end loop;
            else
               String'Write(Normalized_Stream, "class " & Pgm_Name & " {" & ASCII.LF);
               String'Write(Normalized_Stream, "Scanner scanner = new Scanner(System.in);" & ASCII.LF);
               Push(Item);
               exit;
            end if;
         end;
      end loop;

      while not End_Of_File (Output_File) loop
         declare
            Item : Token_Item_Data := Token_Item_Data'Input(Output_Stream);
            
         begin
            if Item.ID = "Print" then
               Push(Token_Item_Data'(16, "System.out.print", Item.ID_Type, Item.Pos, t_none));
            elsif Item.ID = "Input" then
               case Var_T is
                  when t_integer =>
                     Push(Token_Item_Data'(15,"scanner.nextInt", Item.ID_Type, Item.Pos, t_none));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'(19, "scanner.nextLine();", Res, 1, t_none));
                     Release(Normalized_Stream);
                  when t_boolean =>
                     Push(Token_Item_Data'(19,"scanner.nextBoolean", Item.ID_Type, Item.Pos, t_none));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'(19, "scanner.nextLine();", Res, 1, t_none));
                     Release(Normalized_Stream);
                  when t_byte =>
                     Push(Token_Item_Data'(16,"scanner.nextByte", Item.ID_Type, Item.Pos, t_none));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'(19, "scanner.nextLine();", Res, 1, t_none));
                     Release(Normalized_Stream);
                  when t_short =>
                     Push(Token_Item_Data'(17,"scanner.nextShort", Item.ID_Type, Item.Pos, t_none));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'(19, "scanner.nextLine();", Res, 1, t_none));
                     Release(Normalized_Stream);
                  when t_long =>
                     Push(Token_Item_Data'(16,"scanner.nextLong", Item.ID_Type, Item.Pos, t_none));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'(19, "scanner.nextLine();", Res, 1, t_none));
                     Release(Normalized_Stream);
                  when t_float =>
                     Push(Token_Item_Data'(17,"scanner.nextFloat", Item.ID_Type, Item.Pos, t_none));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'(19, "scanner.nextLine();", Res, 1, t_none));
                     Release(Normalized_Stream);
                  when t_double =>
                     Push(Token_Item_Data'(18,"scanner.nextDouble", Item.ID_Type, Item.Pos, t_none));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'(19, "scanner.nextLine();", Res, 1, t_none));
                     Release(Normalized_Stream);
                  when t_character =>
                     Push(Token_Item_Data'(16,"scanner.nextLine", Item.ID_Type, Item.Pos, t_none));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'Input(Output_Stream));
                     Push(Token_Item_Data'(10, ".charAt(0)", Res, 1, t_none));
                  when others =>
                     Push(Token_Item_Data'(16,"scanner.nextLine", Item.ID_Type, Item.Pos, t_none));
               end case;

            elsif Item.ID = "and" then
               Push(Token_Item_Data'(2, "&&", Item.ID_Type, Item.Pos, t_none));
            elsif Item.ID = "or" then
               Push(Token_Item_Data'(2,"||", Item.ID_Type, Item.Pos, t_none));
            elsif Item.ID = "not" then
               Push(Token_Item_Data'(1,"!", Item.ID_Type, Item.Pos, t_none));
            elsif Item.ID = "of" then
               Push(Token_Item_Data'(1,":", Item.ID_Type, Item.Pos, t_none));

            elsif Item.ID_Type = Semi or Item.ID_Type = CloseC then
               Push(Item);
               Release(Normalized_Stream);

            elsif Item.ID_Type = OpenC or Item.ID_Type = OpenP then
               Release(Normalized_Stream);
               Push(Item);

            elsif Item.ID_Type = CloseP then
               Push(Item);
               Release(Normalized_Stream);
               Boolean_Context := False;

            elsif Item.ID = "==" or else (Item.ID = "=" and Boolean_Context) then
               declare
                  V1 : Token_Item_Data := Pop;
                  V2 : Token_Item_Data := Token_Item_Data'Input(Output_Stream);
                  Str : String := "Objects.deepEquals(";
               begin
                  Push(Token_Item_Data'(str'Length,Str, Item.ID_Type, Item.Pos, t_none));
                  Push(V1);
                  Push(Token_Item_Data'(1,",", Comma, Item.Pos, t_none));
                  Push(V2);
                  Push(Token_Item_Data'(1,")", Comma, Item.Pos, t_none));
               end;

            elsif Item.ID = "!=" then
               declare
                  V1 : Token_Item_Data := Pop;
                  V2 : Token_Item_Data := Token_Item_Data'Input(Output_Stream);
                  Str : String := "!Objects.deepEquals(";
               begin
                  Push(Token_Item_Data'(Str'Length, Str, Item.ID_Type, Item.Pos, t_none));
                  Push(V1);
                  Push(Token_Item_Data'(1,",", Comma, Item.Pos, t_none));
                  Push(V2);
                  Push(Token_Item_Data'(1,")", Comma, Item.Pos, t_none));
               end;
            elsif Item.ID = "if" or Item.ID = "while" then
               Boolean_Context := True;
               Push(Item);
            else
               if Item.ID_Type = Variable then
                  Var_T := Item.Var_T;
               end if;
               Push(Item);
            end if;

         end;
      end loop;
      String'Write(Normalized_Stream, ASCII.LF & "public static void main(String[] args){ "& ASCII.LF);
      String'Write(Normalized_Stream, Pgm_Name & " main = new " & Pgm_Name & "();" & ASCII.LF);
      String'Write(Normalized_Stream, "main.main();}}" & ASCII.LF);
      Close(Normalized_Code);
   end;
   Close(Symbol_Table);
   Close(Output_File);
end Scanner;
