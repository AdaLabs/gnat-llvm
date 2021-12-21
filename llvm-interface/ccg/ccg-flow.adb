------------------------------------------------------------------------------
--                              C C G                                       --
--                                                                          --
--                     Copyright (C) 2020-2021, AdaCore                     --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

with Ada.Containers.Ordered_Sets;
with Ada.Containers.Hashed_Maps;

with Output; use Output;
with Table;

with GNATLLVM.Wrapper; use GNATLLVM.Wrapper;

with CCG.Instructions; use CCG.Instructions;
with CCG.Subprograms;  use CCG.Subprograms;
with CCG.Utils;        use CCG.Utils;

package body CCG.Flow is

   --  First is a table containing pairs of switch statement values and
   --  targets.

   type Case_Data is record
      Value  : Value_T;
      --  Value corresponding to this case or No_Value_T for "default"

      Target : Flow_Idx;
      --  Destination for this value

   end record;

   package Cases is new Table.Table
     (Table_Component_Type => Case_Data,
      Table_Index_Type     => Case_Idx,
      Table_Low_Bound      => Case_Idx_Low_Bound,
      Table_Initial        => 10,
      Table_Increment      => 50,
      Table_Name           => "Cases");

   --  Next is a table containing pairs of if/then tests and targets.

   type If_Data is record
      Test   : Value_T;
      --  Expression corresponding to the test, if Present. If not, this
      --  represents an "else".

      Inst   : Value_T;
      --  Instruction that does test (for debug info)

      Target : Flow_Idx;
      --  Destination if this test is true (or not Present)

   end record;

   package Ifs is new Table.Table
     (Table_Component_Type => If_Data,
      Table_Index_Type     => If_Idx,
      Table_Low_Bound      => If_Idx_Low_Bound,
      Table_Initial        => 100,
      Table_Increment      => 200,
      Table_Name           => "Ifs");

   --  Finally, we have the table that encodes the flows themselves

   type Flow_Data is record
      BB           : Basic_Block_T;
      --  Block corresponding to this flow, if not a return flow

      First_Stmt   : Stmt_Idx;
      --  First statement that's part of this flow, if any

      Last_Stmt    : Stmt_Idx;
      --  Last statement that's part of this flow, if any

      Use_Count    : Nat;
      --  Number of times this flow is referenced by another flow (always one
      --  for the entry block).

      Next         : Flow_Idx;
      --  Next flow executed after this one has completed, if any

      Is_Return    : Boolean;
      --  This is set for the unique return flow

      Return_Value : Value_T;
      --  If a return flow, the value to return, if any

      First_If     : If_Idx;
      Last_If      : If_Idx;
      --  First and last if/then/elseif/else parts, if any

      Case_Expr    : Str;
      --  Expression for switch statement, if any

      First_Case   : Case_Idx;
      Last_Case    : Case_Idx;
      --  First and last of cases for a switch statement, if any

   end record;

   package Flows is new Table.Table
     (Table_Component_Type => Flow_Data,
      Table_Index_Type     => Flow_Idx,
      Table_Low_Bound      => Flow_Idx_Low_Bound,
      Table_Initial        => 100,
      Table_Increment      => 200,
      Table_Name           => "Flows");

   --  We merge returns that have the same return value (or those that
   --  have no return value) and use a map to allow us to do that.

   package Return_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Value_T,
      Element_Type    => Flow_Idx,
      Hash            => Hash,
      Equivalent_Keys => "=");
   Return_Map : Return_Maps.Map;

   --  The unique Flow that indicates a return

   Current_Flow : Flow_Idx := Empty_Flow_Idx;
   --  The flow that we're currently building

   function New_Case (V : Value_T) return Case_Idx;
   --  Create a new case element for V, if any

   function New_If (V, Inst : Value_T) return If_Idx
     with Pre  => Is_A_Instruction (Inst),
          Post => Present (New_If'Result);
   --  Create a new "if" piece for the specified value and instruction

   procedure Add_Use (Idx : Flow_Idx) with Inline;
   procedure Remove_Use (Idx : Flow_Idx) with Inline;
   --  Add or remove (respectively) a usage of the Flow denoted by Idx,
   --  if any.

   -----------
   -- Value --
   -----------

   function Value (Idx : Case_Idx) return Value_T is
     (Cases.Table (Idx).Value);

   ------------
   -- Target --
   ------------

   function Target (Idx : Case_Idx) return Flow_Idx is
     (Cases.Table (Idx).Target);

   --------------
   -- Set_Value --
   --------------

   procedure Set_Value (Idx : Case_Idx; V : Value_T) is
   begin
      Cases.Table (Idx).Value := V;
   end Set_Value;

   ----------------
   -- Set_Target --
   ----------------

   procedure Set_Target (Idx : Case_Idx; Fidx : Flow_Idx) is
   begin
      Remove_Use (Target (Idx));
      Add_Use (Fidx);
      Cases.Table (Idx).Target := Fidx;
   end Set_Target;

   ----------
   -- Test --
   ----------

   function Test (Idx : If_Idx) return Value_T is
     (Ifs.Table (Idx).Test);

   ----------
   -- Inst --
   ----------

   function Inst (Idx : If_Idx) return Value_T is
     (Ifs.Table (Idx).Inst);

   ------------
   -- Target --
   ------------

   function Target (Idx : If_Idx) return Flow_Idx is
     (Ifs.Table (Idx).Target);

   --------------
   -- Set_Test --
   --------------

   procedure Set_Test (Idx : If_Idx; V : Value_T) is
   begin
      Ifs.Table (Idx).Test := V;
   end Set_Test;

   --------------
   -- Set_Inst --
   --------------

   procedure Set_Inst (Idx : If_Idx; V : Value_T) is
   begin
      Ifs.Table (Idx).Inst := V;
   end Set_Inst;

   ----------------
   -- Set_Target --
   ----------------

   procedure Set_Target (Idx : If_Idx; Fidx : Flow_Idx) is
   begin
      Remove_Use (Target (Idx));
      Add_Use (Fidx);
      Ifs.Table (Idx).Target := Fidx;
   end Set_Target;

   --------
   -- BB --
   --------

   function BB (Idx : Flow_Idx) return Basic_Block_T is
     (Flows.Table (Idx).BB);

   ----------------
   -- First_Stmt --
   ----------------

   function First_Stmt (Idx : Flow_Idx) return Stmt_Idx is
     (Flows.Table (Idx).First_Stmt);

   ---------------
   -- Last_Stmt --
   ---------------

   function Last_Stmt (Idx : Flow_Idx) return Stmt_Idx is
     (Flows.Table (Idx).Last_Stmt);

   ---------------
   -- Use_Count --
   ---------------

   function Use_Count (Idx : Flow_Idx)  return Nat is
     (Flows.Table (Idx).Use_Count);

   ----------
   -- Next --
   ----------

   function Next (Idx : Flow_Idx) return Flow_Idx is
     (Flows.Table (Idx).Next);

   ---------------
   -- Is_Return --
   ---------------

   function Is_Return (Idx : Flow_Idx) return Boolean is
     (Flows.Table (Idx).Is_Return);

   ------------------
   -- Return_Value --
   ------------------

   function Return_Value (Idx : Flow_Idx) return Value_T is
     (Flows.Table (Idx).Return_Value);

   --------------
   -- First_If --
   --------------

   function First_If (Idx : Flow_Idx) return If_Idx is
     (Flows.Table (Idx).First_If);

   -------------
   -- Last_If --
   -------------

   function Last_If (Idx : Flow_Idx) return If_Idx is
     (Flows.Table (Idx).Last_If);

   ---------------
   -- Case_Expr --
   ---------------

   function Case_Expr (Idx : Flow_Idx)  return Str is
     (Flows.Table (Idx).Case_Expr);

   ----------------
   -- First_Case --
   ----------------

   function First_Case (Idx : Flow_Idx) return Case_Idx is
      (Flows.Table (Idx).First_Case);

   ----------------
   -- Last_Case --
   ----------------

   function Last_Case (Idx : Flow_Idx) return Case_Idx is
      (Flows.Table (Idx).Last_Case);

   ------------
   -- Set_BB --
   ------------

   procedure Set_BB (Idx : Flow_Idx; B : Basic_Block_T) is
   begin
      Flows.Table (Idx).BB := B;
   end Set_BB;

   --------------------
   -- Set_First_Stmt --
   --------------------

   procedure Set_First_Stmt (Idx : Flow_Idx; S : Stmt_Idx) is
   begin
      Flows.Table (Idx).First_Stmt := S;
   end Set_First_Stmt;

   -------------------
   -- Set_Last_Stmt --
   -------------------

   procedure Set_Last_Stmt (Idx : Flow_Idx; S : Stmt_Idx) is
   begin
      Flows.Table (Idx).Last_Stmt := S;
   end Set_Last_Stmt;

   -------------
   -- Add_Use --
   -------------

   procedure Add_Use (Idx : Flow_Idx) is
   begin
      if Present (Idx) then
         Flows.Table (Idx).Use_Count := Flows.Table (Idx).Use_Count + 1;
      end if;

   end Add_Use;

   ----------------
   -- Remove_Use --
   ----------------

   procedure Remove_Use (Idx : Flow_Idx) is
   begin
      if Present (Idx) then
         Flows.Table (Idx).Use_Count := Flows.Table (Idx).Use_Count - 1;
      end if;

   end Remove_Use;

   --------------
   -- Set_Next --
   --------------

   procedure Set_Next (Idx, Nidx : Flow_Idx) is
   begin
      Remove_Use (Next (Idx));
      Add_Use (Nidx);
      Flows.Table (Idx).Next := Nidx;
   end Set_Next;

   -------------------
   -- Set_Is_Return --
   -------------------

   procedure Set_Is_Return (Idx : Flow_Idx; B : Boolean := True) is
   begin
      Flows.Table (Idx).Is_Return := B;
   end Set_Is_Return;

   ----------------------
   -- Set_Return_Value --
   ----------------------

   procedure Set_Return_Value (Idx : Flow_Idx; V : Value_T) is
   begin
      Flows.Table (Idx).Return_Value := V;
   end Set_Return_Value;

   ------------------
   -- Set_First_If --
   ------------------

   procedure Set_First_If (Idx : Flow_Idx; Iidx : If_Idx) is
   begin
      Flows.Table (Idx).First_If := Iidx;
   end Set_First_If;

   -----------------
   -- Set_Last_If --
   -----------------

   procedure Set_Last_If (Idx : Flow_Idx; Iidx : If_Idx) is
   begin
      Flows.Table (Idx).Last_If := Iidx;
   end Set_Last_If;

   -------------------
   -- Set_Case_Expr --
   -------------------

   procedure Set_Case_Expr (Idx : Flow_Idx; S : Str) is
   begin
      Flows.Table (Idx).Case_Expr := S;
   end Set_Case_Expr;

   --------------------
   -- Set_First_Case --
   --------------------

   procedure Set_First_Case (Idx : Flow_Idx; Cidx : Case_Idx) is
   begin
      Flows.Table (Idx).First_Case := Cidx;
   end Set_First_Case;

   -------------------
   -- Set_Last_Case --
   -------------------

   procedure Set_Last_Case (Idx : Flow_Idx; Cidx : Case_Idx) is
   begin
      Flows.Table (Idx).Last_Case := Cidx;
   end Set_Last_Case;

   ----------------------
   -- Add_Stmt_To_Flow --
   ----------------------

   procedure Add_Stmt_To_Flow (Sidx : Stmt_Idx) is
   begin
      --  ?? During development, allow this to be called with no flow set.
      if No (Current_Flow) then
         return;
      end if;

      if No (First_Stmt (Current_Flow)) then
         Set_First_Stmt (Current_Flow, Sidx);
      end if;

      Set_Last_Stmt (Current_Flow, Sidx);
   end Add_Stmt_To_Flow;

   --------------
   -- New_Case --
   --------------

   function New_Case (V : Value_T) return Case_Idx is
   begin
      Cases.Append ((Value => V, Target => Empty_Flow_Idx));
      return Cases.Last;
   end New_Case;

   ------------
   -- New_If --
   ------------

   function New_If (V, Inst : Value_T) return If_Idx is
   begin
      Ifs.Append ((Test => V, Inst => Inst, Target => Empty_Flow_Idx));
      return Ifs.Last;
   end New_If;

   ------------------------
   -- Get_Or_Create_Flow --
   ------------------------

   function Get_Or_Create_Flow (V : Value_T) return Flow_Idx is
     (Get_Or_Create_Flow (Value_As_Basic_Block (V)));

   ------------------------
   -- Get_Or_Create_Flow --
   ------------------------

   function Get_Or_Create_Flow (BB : Basic_Block_T) return Flow_Idx is
      T   : constant Value_T  := Get_Basic_Block_Terminator (BB);
      Idx : Flow_Idx          := Get_Flow (BB);
      V   : Value_T           := Get_First_Instruction (BB);

   begin
      --  If we already made a flow for this block, return it.

      if Present (Idx) then
         return Idx;
      end if;

      --  Otherwise, make a new flow and set it as the flow for this block
      --  and as the current flow.

      Flows.Append ((Is_Return    => False,
                     Return_Value => No_Value_T,
                     BB           => BB,
                     First_Stmt   => Empty_Stmt_Idx,
                     Last_Stmt    => Empty_Stmt_Idx,
                     Use_Count    => 0,
                     Next         => Empty_Flow_Idx,
                     First_If     => Empty_If_Idx,
                     Last_If      => Empty_If_Idx,
                     Case_Expr    => No_Str,
                     First_Case   => Empty_Case_Idx,
                     Last_Case    => Empty_Case_Idx));
      Idx := Flows.Last;
      Set_Flow (BB, Idx);
      Current_Flow := Idx;

      --  Add all instructions to the flow

      while V /= T loop
         Process_Instruction (V);
         V := Get_Next_Instruction (V);
      end loop;

      --  Finally, process the various types of terminators

      case Get_Opcode (T) is
         when Op_Ret =>
            declare
               use Return_Maps;
               Retval   : Value_T := No_Value_T;
               Ret_Idx  : Flow_Idx;
               Position : Cursor;

            begin
               --  If this function returns and it returns a value,
               --  we'll need to make a return flow coresponding to that
               --  value. Otherwise, we use a flow with no value.

               if not Does_Not_Return (Curr_Func)
                 and then Get_Num_Operands (T) = 1
               then
                  Retval := Get_Operand0 (T);

                  --  If we're returning an array, declare a value (we can
                  --  use T even though its LLVM type is void) of the
                  --  struct type corresponding to Retval's type, assign Retval
                  --  into its only field (which will be done with a
                  --  memmove), and return that value.

                  if Get_Type_Kind (Retval) = Array_Type_Kind then
                     Output_Decl (TP ("#T1_R #2", Retval, T), V => T);
                     Write_Copy (T & ".F", Retval, Type_Of (Retval));
                     Retval := T;
                  end if;
               end if;

               --  If we already have a return flow for this value, use
               --  it. Otherwise, make one and record it.

               Position := Find (Return_Map, Retval);
               if Has_Element (Position) then
                  Ret_Idx := Element (Position);
               else
                  Flows.Append ((Is_Return    => True,
                                 Return_Value => Retval,
                                 BB           => No_BB_T,
                                 First_Stmt   => Empty_Stmt_Idx,
                                 Last_Stmt    => Empty_Stmt_Idx,
                                 Use_Count    => 0,
                                 Next         => Empty_Flow_Idx,
                                 First_If     => Empty_If_Idx,
                                 Last_If      => Empty_If_Idx,
                                 Case_Expr    => No_Str,
                                 First_Case   => Empty_Case_Idx,
                                 Last_Case    => Empty_Case_Idx));
                  Ret_Idx := Flows.Last;
                  Insert (Return_Map, Retval, Ret_Idx);
               end if;

               Set_Next (Idx, Ret_Idx);
            end;

         when Op_Br =>

            --  For a conditional branch, create two if entries, one for
            --  the true and false branch. But make those flows in a second
            --  pass to be sure that our entries are consecutive.

            if Is_Conditional (T) then
               declare
                  Iidx1 : constant If_Idx := New_If (Get_Operand0 (T), T);
                  Iidx2 : constant If_Idx := New_If (No_Value_T, T);

               begin
                  Set_First_If (Idx, Iidx1);
                  Set_Last_If  (Idx, Iidx2);
                  Set_Target   (Iidx1, Get_Or_Create_Flow (Get_Operand2 (T)));
                  Set_Target   (Iidx2, Get_Or_Create_Flow (Get_Operand1 (T)));
               end;
            else
               Set_Next (Idx, Get_Or_Create_Flow (Get_Operand0 (T)));
            end if;

         when Op_Switch =>

            declare
               Val       : constant Value_T                := Get_Operand0 (T);
               POO       : constant Process_Operand_Option :=
                 (if Get_Is_Unsigned (Val) then POO_Unsigned else POO_Signed);
               Last_Case : constant Nat                    :=
                 Get_Num_Operands (T) / 2 - 1;
               Result    : Str                             :=
                 Process_Operand (Val, POO);
               Cidx      : Case_Idx                        :=
                 New_Case (No_Value_T);

            begin
               --  If Val is narrower than int, we must force it to its size

               if Get_Scalar_Bit_Size (Val) < Int_Size then
                  Result := TP ("(#T1) ", Val) & (Result + Unary);
               end if;

               --  Set the case expression and the first case data

               Set_Case_Expr  (Idx, Result);
               Set_First_Case (Idx, Cidx);

               --  Now make case data for each alternative

               for J in 1 .. Last_Case loop
                  Cidx := New_Case (Get_Operand (T, J * 2));
               end loop;

               --  Finally, set the last case and all the targets of the
               --  default and alternative choices.

               Set_Last_Case (Idx, Cidx);
               Cidx := First_Case (Idx);
               Set_Target (Cidx, Get_Or_Create_Flow (Get_Operand1 (T)));
               for J in 1 .. Last_Case loop
                  Cidx := Cidx + 1;
                  Set_Target
                    (Cidx, Get_Or_Create_Flow (Get_Operand (T, J * 2 + 1)));
               end loop;
            end;

         when others =>
            pragma Assert (False);
      end case;

      --  Finally, return the new Flow we contructed

      return Idx;
   end Get_Or_Create_Flow;

   ---------------
   -- Dump_Flow --
   ---------------

   procedure Dump_Flow (J : Pos; Dump_All : Boolean) is
      procedure Write_Flow_Idx (Idx : Flow_Idx)
        with Pre => Present (Idx);
      procedure Dump_One_Flow (Idx : Flow_Idx)
        with Pre => Present (Idx);
      package Dump_Flows is new Ada.Containers.Ordered_Sets
        (Element_Type => Flow_Idx,
         "<"          => "<",
         "="          => "=");
      use Dump_Flows;
      To_Dump : Set;
      Dumped  : Set;
      LB      : constant Pos      := Pos (Flow_Idx_Low_Bound);
      Idx     : constant Flow_Idx := Flow_Idx ((if J < LB then J + LB else J));
      --  To simplify its use, this can be called either with the actual
      --  Flow_Idx value or a smaller integer which represents the low-order
      --  digits of the value.

      --------------------
      -- Write_Flow_Idx --
      --------------------

      procedure Write_Flow_Idx (Idx : Flow_Idx) is
      begin
         Write_Int (Pos (Idx));
         if Is_Return (Idx) then
            Write_Str (" (return");
            if Present (Return_Value (Idx)) then
               Write_Str (" " & Return_Value (Idx));
            end if;

            Write_Str (")");
         end if;

         --  If we haven't already dump this flow, show that we may need to

         if not Contains (Dumped, Idx) then
            Insert (To_Dump, Idx);
         end if;
      end Write_Flow_Idx;

      -------------------
      -- Dump_one_Flow --
      -------------------

      procedure Dump_One_Flow (Idx : Flow_Idx) is
      begin
         Write_Str ("Flow ");
         Write_Int (Pos (Idx));
         Write_Str (" has ");
         Write_Int (Use_Count (Idx));
         if Use_Count (Idx) = 1 then
            Write_Str (" use");
         else
            Write_Str (" uses");
         end if;

         if Is_Return (Idx) then
            Write_Str (" return");
            if Present (Return_Value (Idx)) then
               Write_Str (" " & Return_Value (Idx));
            end if;
         elsif Present (Next (Idx)) then
            Write_Str (" next ");
            Write_Flow_Idx (Next (Idx));
         end if;

         if Present (First_Stmt (Idx)) or else Present (First_If (Idx))
           or else Present (Case_Expr (Idx))
         then
            Write_Str (":");
         end if;

         Write_Eol;

         if Present (First_Stmt (Idx)) then
            for Sidx in First_Stmt (Idx) .. Last_Stmt (Idx) loop
               Write_Str ("      " & Get_Stmt_Line (Sidx).Line_Text,
                          Eol => True);
            end loop;
         end if;

         if Present (First_If (Idx)) then
            for Iidx in First_If (Idx) .. Last_If (Idx) loop
               if Present (Test (Iidx)) then
                  Write_Str ("    if (" & Test (Iidx) & ") then ");
               else
                  Write_Str ("    else ");
               end if;

               Write_Flow_Idx (Target (Iidx));
               Write_Eol;
            end loop;
         end if;

         if Present (Case_Expr (Idx)) then
            Write_Str ("  switch (" & Case_Expr (Idx) & ")");
            Write_Eol;
            for Cidx in First_Case (Idx) .. Last_Case (Idx) loop
               if Present (Value (Cidx)) then
                  Write_Str ("    " & Value (Cidx) & ": goto ");
               else
                  Write_Str ("    default: goto ");
               end if;

               Write_Flow_Idx (Target (Cidx));
               Write_Eol;
            end loop;
         end if;
      end Dump_One_Flow;

   begin  --  Start of processing for Dump_Flow
      Push_Output;
      Set_Standard_Error;

      --  Dump the flow we're asked to dump. If we're to dump nested flow,
      --  keep dumping until all are done.
      Dump_One_Flow (Idx);
      Insert (Dumped, Idx);
      if Dump_All then
         while not Is_Empty (To_Dump) loop
            declare
               Dump_Idx : constant Flow_Idx := First_Element (To_Dump);

            begin
               --  We don't dump return flows since we see them when they are
               --  referenced. But pretend that we did.

               if not Is_Return (Dump_Idx) then
                  Dump_One_Flow (Dump_Idx);
               end if;

               Delete (To_Dump, Dump_Idx);
               Insert (Dumped, Dump_Idx);
            end;
         end loop;
      end if;

      Pop_Output;
   end Dump_Flow;

begin
   --  Ensure we have an empty entry in the tables

   Cases.Increment_Last;
   Ifs.Increment_Last;
   Flows.Increment_Last;

end CCG.Flow;
