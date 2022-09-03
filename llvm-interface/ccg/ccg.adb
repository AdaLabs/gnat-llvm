------------------------------------------------------------------------------
--                              C C G                                       --
--                                                                          --
--                     Copyright (C) 2020-2022, AdaCore                     --
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

with Atree;       use Atree;
with Einfo.Utils; use Einfo.Utils;
with Errout;      use Errout;
with Lib;         use Lib;

with GNATLLVM.Codegen; use GNATLLVM.Codegen;
with GNATLLVM.Types;   use GNATLLVM.Types;
with GNATLLVM.Wrapper; use GNATLLVM.Wrapper;

with CCG.Codegen;      use CCG.Codegen;
with CCG.Environment;  use CCG.Environment;
with CCG.Helper;       use CCG.Helper;
with CCG.Instructions; use CCG.Instructions;
with CCG.Subprograms;  use CCG.Subprograms;
with CCG.Target;       use CCG.Target;
with CCG.Utils;        use CCG.Utils;

package body CCG is

   --  This package and its children generate C code from the LLVM IR
   --  generated by GNAT LLLVM.

   -------------------------
   -- C_Initialize_Output --
   -------------------------

   procedure C_Initialize_Output renames Initialize_Output;

   ----------------
   -- C_Generate --
   ----------------

   procedure C_Generate (Module : Module_T) renames Generate;

   ---------------------------
   -- C_Add_To_Source_Order --
   ---------------------------

   procedure C_Add_To_Source_Order (N : Node_Id) is
   begin
      if Emit_C and then not Emit_Header then
         Add_To_Source_Order (N);
      end if;
   end C_Add_To_Source_Order;

   ----------------------------
   -- C_Protect_Source_Order --
   ----------------------------

   procedure C_Protect_Source_Order renames Protect_Source_Order;

   ----------------------
   -- C_Set_Field_Info --
   ----------------------

   procedure C_Set_Field_Info
     (UID         : Unique_Id;
      Idx         : Nat;
      Name        : Name_Id   := No_Name;
      Entity      : Entity_Id := Types.Empty;
      Is_Padding  : Boolean   := False;
      Is_Bitfield : Boolean   := False) is
   begin
      if Emit_C then
         Set_Field_C_Info (UID, Idx, Name, Entity, Is_Padding, Is_Bitfield);
      end if;
   end C_Set_Field_Info;

   ------------------
   -- C_Set_Struct --
   ------------------

   procedure C_Set_Struct (UID : Unique_Id; T : Type_T) is
   begin
      if Emit_C then
         Set_Struct (UID, T);
      end if;
   end C_Set_Struct;

   ---------------------
   -- C_Set_Parameter --
   ---------------------

   procedure C_Set_Parameter
     (UID : Unique_Id; Idx : Nat; Entity : Entity_Id) is
   begin
      if Emit_C then
         Set_Parameter (UID, Idx, Entity);
      end if;
   end C_Set_Parameter;

   --------------------
   -- C_Set_Function --
   --------------------

   procedure C_Set_Function (UID : Unique_Id; V : Value_T) is
   begin
      if Emit_C then
         Set_Function (UID, V);
      end if;
   end C_Set_Function;

   ------------------
   -- C_Set_Entity --
   ------------------

   procedure C_Set_Entity (V : Value_T; E : Entity_Id) is
      Prev_E : constant Entity_Id := Get_Entity (V);

   begin
      --  If we're not emitting C, we don't need to do anything

      if not Emit_C then
         return;

      --  We only want to set this the first time because that will be the
      --  most reliable information. However, we prefer an entity over a type.

      elsif (Present (Prev_E) and then not Is_Type (E)
             and then Is_Type (Prev_E))
        or else No (Prev_E)
      then
         Notify_On_Value_Delete (V, Delete_Value_Info'Access);
         Set_Entity (V, E);
      end if;

      --  If we have a type that's an access function type, show that we
      --  have such since we need to write out a typedef.

      if (Is_Type (E) and then Is_Access_Subprogram_Type (E))
        or else (not Is_Type (E)
                   and then Is_Access_Subprogram_Type (Full_Etype (E)))
      then
         Has_Access_Subtype := True;
      end if;

   end C_Set_Entity;

   ------------------
   -- C_Set_Entity --
   ------------------

   procedure C_Set_Entity (T : Type_T; TE : Type_Kind_Id) is
   begin
      if Emit_C then
         Set_Entity (T, TE);
      end if;
   end C_Set_Entity;

   ------------------------------
   -- C_Dont_Add_Inline_Always --
   ------------------------------

   function C_Dont_Add_Inline_Always return Boolean is
     (Emit_C and then Inline_Always_Must);

   ---------------------
   -- C_Address_Taken --
   ---------------------

   procedure C_Address_Taken (V : Value_T) is
   begin
      if Emit_C then
         Set_Needs_Nest (V);
      end if;
   end C_Address_Taken;

   ---------------
   -- Error_Msg --
   ---------------

   procedure Error_Msg (Msg : String; V : Value_T) is
   begin
      if Present (V)
        and then (Is_A_Instruction (V) or else Is_A_Function (V)
                  or else Is_A_Global_Variable (V))
      then
         declare
            File : constant String := Get_Debug_Loc_Filename (V);
            Line : constant String := CCG.Helper.Get_Debug_Loc_Line (V)'Image;
         begin
            if File /= "" then
               Error_Msg_N (Msg & " at " & File & ":" & Line (2 .. Line'Last),
                            Cunit (Types.Main_Unit));
               return;
            end if;
         end;
      end if;

      Error_Msg_N (Msg, Cunit (Types.Main_Unit));
   end Error_Msg;

   -------------------------
   -- C_Create_Annotation --
   -------------------------

   function C_Create_Annotation (S : String) return Nat
     renames Create_Annotation;

   ----------------------
   -- C_Process_Switch --
   ----------------------

   function C_Process_Switch (Switch : String) return Boolean
     renames Process_Switch;

   -----------------
   -- C_Is_Switch --
   -----------------

   function C_Is_Switch (Switch : String) return Boolean renames Is_Switch;
end CCG;
