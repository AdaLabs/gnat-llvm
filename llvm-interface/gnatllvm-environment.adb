------------------------------------------------------------------------------
--                             G N A T - L L V M                            --
--                                                                          --
--                     Copyright (C) 2013-2018, AdaCore                     --
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

with GNATLLVM.Types;       use GNATLLVM.Types;
with GNATLLVM.Utils;       use GNATLLVM.Utils;

package body GNATLLVM.Environment is

   --------------
   -- Get_Type --
   --------------

   function Get_Type (TE : Entity_Id) return Type_T is
   begin
      if LLVM_Info_Map (TE) = Empty_LLVM_Info_Id then
         return No_Type_T;
      else
         return LLVM_Info_Table.Table (LLVM_Info_Map (TE)).Typ;
      end if;
   end Get_Type;

   ---------------------
   -- Is_Dynamic_Size --
   ---------------------

   function Is_Dynamic_Size (TE : Entity_Id) return Boolean is
   begin
      --  ??? It would be better structuring if we could guarantee that this
      --  would only be called after the type has been elaborated, but
      --  we don't yet (and may never) have a good way of early lazy
      --  elaboration of those types.

      if not Has_Type (TE) then
         Discard (Create_Type (TE));
      end if;

      return LLVM_Info_Table.Table (LLVM_Info_Map (TE)).Is_Dynamic_Size;
   end Is_Dynamic_Size;

   --------------
   -- Get_TBAA --
   --------------

   function Get_TBAA (TE : Entity_Id) return Metadata_T is
   begin
      if not Has_Type (TE) then
         Discard (Create_Type (TE));
      end if;

      return LLVM_Info_Table.Table (LLVM_Info_Map (TE)).TBAA;
   end Get_TBAA;

   ---------------
   -- Get_Value --
   ---------------

   function Get_Value (VE : Entity_Id) return GL_Value is
   begin
      if LLVM_Info_Map (VE) = Empty_LLVM_Info_Id then
         return No_GL_Value;
      else
         return LLVM_Info_Table.Table (LLVM_Info_Map (VE)).Value;
      end if;
   end Get_Value;

   ---------------------
   -- Get_Array_Info --
   ---------------------

   function Get_Array_Info (TE : Entity_Id) return Array_Info_Id is
   begin
      if not Has_Type (TE) then
         Discard (Create_Type (TE));
      end if;

      return LLVM_Info_Table.Table (LLVM_Info_Map (TE)).Array_Info;
   end Get_Array_Info;

   ---------------------
   -- Get_Record_Info --
   ---------------------

   function Get_Record_Info (TE : Entity_Id) return Record_Info_Id is
   begin
      if not Has_Type (TE) then
         Discard (Create_Type (TE));
      end if;

      return LLVM_Info_Table.Table (LLVM_Info_Map (TE)).Record_Info;
   end Get_Record_Info;

   --------------------
   -- Get_Field_Info --
   --------------------

   function Get_Field_Info (VE : Entity_Id) return Field_Info_Id is
   begin
      if LLVM_Info_Map (VE) = Empty_LLVM_Info_Id then
         return Empty_Field_Info_Id;
      else
         return LLVM_Info_Table.Table (LLVM_Info_Map (VE)).Field_Info;
      end if;

   end Get_Field_Info;

   --------------------
   -- Get_Label_Info --
   --------------------

   function Get_Label_Info (VE : Entity_Id) return Label_Info_Id is
   begin
      if LLVM_Info_Map (VE) = Empty_LLVM_Info_Id then
         return Empty_Label_Info_Id;
      else
         return LLVM_Info_Table.Table (LLVM_Info_Map (VE)).Label_Info;
      end if;

   end Get_Label_Info;

   function Get_LLVM_Info_Id (N : Node_Id) return LLVM_Info_Id;
   --  Helper for below to allocate LLVM_Info_Table entry if needed.

   ----------------------
   -- Get_LLVM_Info_Id --
   ----------------------

   function Get_LLVM_Info_Id (N : Node_Id) return LLVM_Info_Id
   is
      Id : LLVM_Info_Id := LLVM_Info_Map (N);

   begin
      if Id /= Empty_LLVM_Info_Id then
         return Id;
      else
         LLVM_Info_Table.Append ((Value           => No_GL_Value,
                                  Typ             => No_Type_T,
                                  TBAA            => No_Metadata_T,
                                  Is_Dynamic_Size => False,
                                  Record_Info     => Empty_Record_Info_Id,
                                  Field_Info      => Empty_Field_Info_Id,
                                  Array_Info      => Empty_Array_Info_Id,
                                  Label_Info      => Empty_Label_Info_Id));
         Id := LLVM_Info_Table.Last;
         LLVM_Info_Map (N) := Id;
         return Id;
      end if;
   end Get_LLVM_Info_Id;

   --------------------
   -- Copy_Type_Info --
   --------------------

   procedure Copy_Type_Info (Old_T, New_T : Entity_Id) is
      Id : constant LLVM_Info_Id := LLVM_Info_Map (Old_T);

   begin
      pragma Assert (Id /= Empty_LLVM_Info_Id);
      pragma Assert (LLVM_Info_Map (New_T) in Empty_LLVM_Info_Id | Id);
      --  We know this is a type and one for which we don't have any
      --  data, so we shouldn't have allocated anything for it.
      --  However, we may have a recursive type situation where it
      --  was defined as part of the code that calls us, so also allow
      --  the data to have already been set.  But it's still an error
      --  if it was set to something different.

      LLVM_Info_Map (New_T) := Id;
   end Copy_Type_Info;

   --------------
   -- Set_Type --
   --------------

   procedure Set_Type (TE : Entity_Id; TL : Type_T) is
      Id : constant LLVM_Info_Id := Get_LLVM_Info_Id (TE);

   begin
      LLVM_Info_Table.Table (Id).Typ := TL;
   end Set_Type;

   -------------------------
   -- Set_Is_Dynamic_Size --
   -------------------------

   procedure Set_Is_Dynamic_Size (TE : Entity_Id; B : Boolean := True) is
      Id : constant LLVM_Info_Id := Get_LLVM_Info_Id (TE);

   begin
      LLVM_Info_Table.Table (Id).Is_Dynamic_Size := B;
   end Set_Is_Dynamic_Size;

   --------------
   -- Set_TBAA --
   --------------

   procedure Set_TBAA (TE : Entity_Id; TBAA : Metadata_T) is
      Id : constant LLVM_Info_Id := Get_LLVM_Info_Id (TE);

   begin
      LLVM_Info_Table.Table (Id).TBAA := TBAA;
   end Set_TBAA;

   ---------------
   -- Set_Value --
   ---------------

   procedure Set_Value (VE : Entity_Id; VL : GL_Value) is
      Id : constant LLVM_Info_Id := Get_LLVM_Info_Id (VE);

   begin
      LLVM_Info_Table.Table (Id).Value :=  VL;
   end Set_Value;

   ---------------------
   -- Set_Array_Info --
   ---------------------

   procedure Set_Array_Info (TE : Entity_Id; AI : Array_Info_Id)
   is
      Id : constant LLVM_Info_Id := Get_LLVM_Info_Id (TE);

   begin
      LLVM_Info_Table.Table (Id).Array_Info := AI;
   end Set_Array_Info;

   ---------------------
   -- Set_Record_Info --
   ---------------------

   procedure Set_Record_Info (TE : Entity_Id; RI : Record_Info_Id)
   is
      Id : constant LLVM_Info_Id := Get_LLVM_Info_Id (TE);

   begin
      LLVM_Info_Table.Table (Id).Record_Info := RI;
   end Set_Record_Info;

   --------------------
   -- Set_Field_Info --
   --------------------

   procedure Set_Field_Info (VE : Entity_Id; FI : Field_Info_Id)
   is
      Id : constant LLVM_Info_Id := Get_LLVM_Info_Id (VE);

   begin
      LLVM_Info_Table.Table (Id).Field_Info := FI;
   end Set_Field_Info;

   --------------------
   -- Set_Label_Info --
   --------------------

   procedure Set_Label_Info (VE : Entity_Id; LI : Label_Info_Id)
   is
      Id : constant LLVM_Info_Id := Get_LLVM_Info_Id (VE);

   begin
      LLVM_Info_Table.Table (Id).Label_Info := LI;
   end Set_Label_Info;

end GNATLLVM.Environment;
