------------------------------------------------------------------------------
--                             G N A T - L L V M                            --
--                                                                          --
--                     Copyright (C) 2013-2022, AdaCore                     --
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

with Interfaces.C.Strings; use Interfaces.C.Strings;

package body GNATLLVM.Wrapper is

   ----------------------------------
   -- Create_TBAA_Scalar_Type_Node --
   ----------------------------------

   function Create_TBAA_Scalar_Type_Node
     (Ctx    : Context_T;
      MDBld  : MD_Builder_T;
      Name   : String;
      Size   : ULL;
      Parent : Metadata_T) return Metadata_T
   is
      function Create_TBAA_Scalar_Type_Node_C
        (Ctx    : Context_T;
         MDBld  : MD_Builder_T;
         Name   : String;
         Size   : ULL;
         Parent : Metadata_T) return Metadata_T
        with Import, Convention => C,
             External_Name => "Create_TBAA_Scalar_Type_Node";

   begin
      return Create_TBAA_Scalar_Type_Node_C (Ctx, MDBld, Name & ASCII.NUL,
                                             Size, Parent);
   end Create_TBAA_Scalar_Type_Node;

   ----------------------------------
   -- Create_TBAA_Struct_Type_Node --
   ----------------------------------

   function Create_TBAA_Struct_Type_Node
     (Ctx        : Context_T;
      MDBld      : MD_Builder_T;
      Name       : String;
      Size       : ULL;
      Num_Fields : Nat;
      Parent     : Metadata_T;
      Fields     : System.Address;
      Offsets    : System.Address;
      Sizes      : System.Address) return Metadata_T
   is
      function Create_TBAA_Struct_Type_Node_C
        (Ctx        : Context_T;
         MDBld      : MD_Builder_T;
         Name       : String;
         Size       : ULL;
         Num_Fields : Nat;
         Parent     : Metadata_T;
         Fields     : System.Address;
         Offsets    : System.Address;
         Sizes      : System.Address) return Metadata_T
        with Import, Convention => C,
             External_Name => "Create_TBAA_Struct_Type_Node";

   begin
      return Create_TBAA_Struct_Type_Node_C (Ctx, MDBld, Name & ASCII.NUL,
                                             Size, Num_Fields, Parent, Fields,
                                             Offsets, Sizes);
   end Create_TBAA_Struct_Type_Node;

   ------------------------
   -- Build_Extract_Value --
   ------------------------

   function Build_Extract_Value
     (Bld      : Builder_T;
      Aggr     : Value_T;
      Idx_List : System.Address;
      Num_Idx  : unsigned;
      Name     : String) return Value_T
   is
      function Build_Extract_Value_C
        (Bld      : Builder_T;
         Aggr     : Value_T;
         Idx_List : System.Address;
         Num_Idx  : unsigned;
         Name     : String) return Value_T
        with Import, Convention => C,
             External_Name =>  "Build_Extract_Value_C";

   begin
      return Build_Extract_Value_C (Bld, Aggr, Idx_List, Num_Idx,
                                    Name & ASCII.NUL);
   end Build_Extract_Value;

   ------------------------
   -- Build_Insert_Value --
   ------------------------

   function Build_Insert_Value
     (Bld      : Builder_T;
      Aggr     : Value_T;
      Elt      : Value_T;
      Idx_List : System.Address;
      Num_Idx  : unsigned;
      Name     : String) return Value_T
   is
      function Build_Insert_Value_C
        (Bld      : Builder_T;
         Aggr     : Value_T;
         Elt      : Value_T;
         Idx_List : System.Address;
         Num_Idx  : unsigned;
         Name     : String) return Value_T
        with Import, Convention => C, External_Name => "Build_Insert_Value_C";

   begin
      return Build_Insert_Value_C (Bld, Aggr, Elt, Idx_List, Num_Idx,
                                   Name & ASCII.NUL);
   end Build_Insert_Value;

   ------------------
   -- Build_MemCpy --
   ------------------

   function Build_MemCpy
     (Bld         : Builder_T;
      Dst         : Value_T;
      Dst_Align   : unsigned;
      Src         : Value_T;
      Src_Align   : unsigned;
      Size        : Value_T;
      Is_Volatile : Boolean;
      TBAA        : Metadata_T;
      TBAA_Struct : Metadata_T;
      Scope       : Metadata_T;
      NoAlias     : Metadata_T) return Value_T
   is
      function Build_MemCpy_C
        (Bld         : Builder_T;
         Dst         : Value_T;
         Dst_Align   : unsigned;
         Src         : Value_T;
         Src_Align   : unsigned;
         Size        : Value_T;
         Is_Volatile : LLVM_Bool;
         TBAA        : Metadata_T;
         TBAA_Struct : Metadata_T;
         Scope       : Metadata_T;
         NoAlias     : Metadata_T) return Value_T
        with Import, Convention => C, External_Name => "Build_MemCpy";
   begin
      return Build_MemCpy_C (Bld, Dst, Dst_Align, Src, Src_Align, Size,
                             Boolean'Pos (Is_Volatile), TBAA, TBAA_Struct,
                             Scope, NoAlias);
   end Build_MemCpy;

   -------------------
   -- Build_MemMove --
   -------------------

   function Build_MemMove
     (Bld         : Builder_T;
      Dst         : Value_T;
      Dst_Align   : unsigned;
      Src         : Value_T;
      Src_Align   : unsigned;
      Size        : Value_T;
      Is_Volatile : Boolean;
      TBAA        : Metadata_T;
      Scope       : Metadata_T;
      NoAlias     : Metadata_T) return Value_T
   is
      function Build_MemMove_C
        (Bld         : Builder_T;
         Dst         : Value_T;
         Dst_Align   : unsigned;
         Src         : Value_T;
         Src_Align   : unsigned;
         Size        : Value_T;
         Is_Volatile : LLVM_Bool;
         TBAA        : Metadata_T;
         Scope       : Metadata_T;
         NoAlias     : Metadata_T) return Value_T
        with Import, Convention => C, External_Name => "Build_MemMove";

   begin
      return Build_MemMove_C (Bld, Dst, Dst_Align, Src, Src_Align, Size,
                              Boolean'Pos (Is_Volatile), TBAA, Scope, NoAlias);
   end Build_MemMove;

   ------------------
   -- Build_MemSet --
   ------------------

   function Build_MemSet
     (Bld         : Builder_T;
      Ptr         : Value_T;
      Val         : Value_T;
      Size        : Value_T;
      Align       : unsigned;
      Is_Volatile : Boolean;
      TBAA        : Metadata_T;
      Scope       : Metadata_T;
      NoAlias     : Metadata_T) return Value_T
   is
      function Build_MemSet_C
        (Bld         : Builder_T;
         Ptr         : Value_T;
         Val         : Value_T;
         Size        : Value_T;
         Align       : unsigned;
         Is_Volatile : LLVM_Bool;
         TBAA        : Metadata_T;
         Scope       : Metadata_T;
         NoAlias     : Metadata_T) return Value_T
        with Import, Convention => C, External_Name => "Build_MemSet";

   begin
      return Build_MemSet_C (Bld, Ptr, Val, Size, Align,
                             Boolean'Pos (Is_Volatile), TBAA, Scope, NoAlias);
   end Build_MemSet;

   -------------------------
   -- Add_Named_Attribute --
   -------------------------

   procedure Add_Named_Attribute
     (Func : Value_T; Name, Value : String; Ctx : Context_T)
   is
      procedure Add_Named_Attribute_C
        (Func : Value_T; Name, Value : String; Ctx : Context_T)
        with Import, Convention => C, External_Name => "Add_Named_Attribute";

   begin
      Add_Named_Attribute_C (Func, Name & ASCII.NUL, Value & ASCII.NUL, Ctx);
   end Add_Named_Attribute;

   --------------------------
   -- Has_Inline_Attribute --
   --------------------------

   function Has_Inline_Attribute (Func : Value_T) return Boolean is
      function Has_Inline_Attribute_C (Func : Value_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Has_Inline_Attribute";
   begin
      return Has_Inline_Attribute_C (Func) /= 0;
   end Has_Inline_Attribute;

   ---------------------------------
   -- Has_Inline_Always_Attribute --
   ---------------------------------

   function Has_Inline_Always_Attribute (Func : Value_T) return Boolean is
      function Has_Inline_Always_Attribute_C (Func : Value_T) return LLVM_Bool
        with Import, Convention => C,
        External_Name => "Has_Inline_Always_Attribute";
   begin
      return Has_Inline_Always_Attribute_C (Func) /= 0;
   end Has_Inline_Always_Attribute;

   ------------------------
   -- Has_Nest_Attribute --
   ------------------------

   function Has_Nest_Attribute (Func : Value_T; Idx : unsigned) return Boolean
   is
      function Has_Nest_Attribute
        (Func : Value_T; Idx : unsigned) return LLVM_Bool
        with Import, Convention => C, External_Name => "Has_Nest_Attribute";
   begin
      return Has_Nest_Attribute (Func, Idx) /= 0;
   end Has_Nest_Attribute;

   -------------------------
   -- Call_Param_Has_Nest --
   -------------------------

   function Call_Param_Has_Nest (V : Value_T; Idx : unsigned) return Boolean
   is
      function Call_Param_Has_Nest
        (V : Value_T; Idx : unsigned) return LLVM_Bool
        with Import, Convention => C, External_Name => "Call_Param_Has_Nest";
   begin
      return Call_Param_Has_Nest (V, Idx) /= 0;
   end Call_Param_Has_Nest;

   -------------
   -- Has_NSW --
   -------------

   function Has_NSW (V : Value_T) return Boolean is
      function Has_NSW (V : Value_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Has_NSW";
   begin
      return Has_NSW (V) /= 0;
   end Has_NSW;

   -----------------------------------------
   -- Get_Metadata_Operand_Constant_Value --
   -----------------------------------------
   function Get_Metadata_Operand_Constant_Value
     (MD : Metadata_T; Idx : Nat) return ULL
   is
      function Get_Metadata_Operand_Constant_Value_C
        (MD : Metadata_T; Idx : unsigned) return uint64_t
        with Import, Convention => C,
             External_Name => "Get_Metadata_Operand_Constant_Value";
   begin
      return ULL (Get_Metadata_Operand_Constant_Value_C (MD, unsigned (Idx)));
   end Get_Metadata_Operand_Constant_Value;

   ---------------------------
   --  LLVM_Optimize_Module --
   ---------------------------

   function LLVM_Optimize_Module
     (Module                : Module_T;
      Target_Machine        : Target_Machine_T;
      Code_Opt_Level        : Nat;
      Size_Opt_Level        : Nat;
      Need_Loop_Info        : Boolean;
      No_Unroll_Loops       : Boolean;
      No_Loop_Vectorization : Boolean;
      No_SLP_Vectorization  : Boolean;
      Merge_Functions       : Boolean;
      Prepare_For_Thin_LTO  : Boolean;
      Prepare_For_LTO       : Boolean;
      Reroll_Loops          : Boolean;
      Pass_Plugin_Name      : String_Access;
      Error_Message         : System.Address) return Boolean
   is
      function LLVM_Optimize_Module_C
        (Module                : Module_T;
         Target_Machine        : Target_Machine_T;
         Code_Opt_Level        : Nat;
         Size_Opt_Level        : Nat;
         Need_Loop_Info        : LLVM_Bool;
         No_Unroll_Loops       : LLVM_Bool;
         No_Loop_Vectorization : LLVM_Bool;
         No_SLP_Vectorization  : LLVM_Bool;
         Merge_Functions       : LLVM_Bool;
         Prepare_For_Thin_LTO  : LLVM_Bool;
         PrepareFor_LTO        : LLVM_Bool;
         Reroll_Loops          : LLVM_Bool;
         Pass_Plugin_Name      : chars_ptr;
         Error_Message         : System.Address) return LLVM_Bool
        with Import, Convention => C, External_Name => "LLVM_Optimize_Module";
      Need_Loop_Info_B : constant LLVM_Bool := Boolean'Pos (Need_Loop_Info);
      No_Unroll_B      : constant LLVM_Bool := Boolean'Pos (No_Unroll_Loops);
      No_Loop_Vect_B   : constant LLVM_Bool :=
        Boolean'Pos (No_Loop_Vectorization);
      No_SLP_Vect_B    : constant LLVM_Bool :=
        Boolean'Pos (No_SLP_Vectorization);
      Merge_B          : constant LLVM_Bool := Boolean'Pos (Merge_Functions);
      Thin_LTO_B       : constant LLVM_Bool :=
        Boolean'Pos (Prepare_For_Thin_LTO);
      LTO_B            : constant LLVM_Bool := Boolean'Pos (Prepare_For_LTO);
      Reroll_B         : constant LLVM_Bool := Boolean'Pos (Reroll_Loops);
      Pass_PN_Ptr      : chars_ptr :=
        (if Pass_Plugin_Name = null then
            Null_Ptr
         else
            New_String (Pass_Plugin_Name.all));
      Result           : LLVM_Bool;

   begin
      Result :=
        LLVM_Optimize_Module_C (Module, Target_Machine,
                                Code_Opt_Level, Size_Opt_Level,
                                Need_Loop_Info_B, No_Unroll_B, No_Loop_Vect_B,
                                No_SLP_Vect_B, Merge_B, Thin_LTO_B, LTO_B,
                                Reroll_B, Pass_PN_Ptr, Error_Message);
      Free (Pass_PN_Ptr);
      return Result /= 0;
   end LLVM_Optimize_Module;

   -----------------------------
   -- Get_GEP_Constant_Offset --
   -----------------------------

   function Get_GEP_Constant_Offset
     (GEP : Value_T; Layout : Target_Data_T; Offset : out ULL) return Boolean
   is
      function Get_GEP_Constant_Offset_C
        (GEP    : Value_T;
         Layout : Target_Data_T;
         Offset : access ULL) return LLVM_Bool
        with Import, Convention => C,
             External_Name => "Get_GEP_Constant_Offset";

      Result_Offset : aliased ULL;
      Result        : constant LLVM_Bool :=
        Get_GEP_Constant_Offset_C (GEP, Layout, Result_Offset'Access);

   begin
      Offset := Result_Offset;
      return Result /= 0;
   end Get_GEP_Constant_Offset;

   --------------------
   -- Does_Not_Throw --
   --------------------

   function Does_Not_Throw (Fn : Value_T) return Boolean is
      function Does_Not_Throw_C (Fn : Value_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Does_Not_Throw";
   begin
      return Does_Not_Throw_C (Fn) /= 0;
   end Does_Not_Throw;

   ---------------------
   -- Does_Not_Return --
   ---------------------

   function Does_Not_Return (Fn : Value_T) return Boolean is
      function Does_Not_Return_C (Fn : Value_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Does_Not_Return";
   begin
      return Does_Not_Return_C (Fn) /= 0;
   end Does_Not_Return;

   -----------------
   -- Is_C_String --
   -----------------

   function Is_C_String (V : Value_T) return Boolean is
      function Is_C_String_C (V : Value_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Is_C_String";
   begin
      return Is_C_String_C (V) /= 0;
   end Is_C_String;

   ------------------------
   -- Get_Element_Offset --
   ------------------------

   function Get_Element_Offset (T : Type_T; Idx : Int) return ULL is
      function Get_Element_Offset_C
        (Layout : Target_Data_T; T : Type_T; Idx : unsigned) return int64_t
        with Import, Convention => C, External_Name => "Get_Element_Offset";
   begin
      return ULL (Get_Element_Offset_C (Module_Data_Layout, T,
                                        unsigned (Idx)));
   end Get_Element_Offset;

   ----------------
   -- Equals_Int --
   ----------------

   function Equals_Int (V : Value_T; Val : ULL) return Boolean is
      function Equals_Int_C (V : Value_T; Val : ULL) return LLVM_Bool
        with Import, Convention => C, External_Name => "Equals_Int";
   begin
      return Equals_Int_C (V, Val) /= 0;
   end Equals_Int;

   ----------------------
   -- Equals_Constants --
   ----------------------

   function Equal_Constants (V1, V2 : Value_T) return Boolean is
      function Equal_Constants_C (V1, V2 : Value_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Equal_Constants";
   begin
      return Equal_Constants_C (V1, V2) /= 0;
   end Equal_Constants;

   ---------------------
   -- Struct_Has_Name --
   ---------------------

   function Struct_Has_Name (T : Type_T) return Boolean is
      function Struct_Has_Name (T : Type_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Struct_Has_Name";
   begin
      return Struct_Has_Name (T) /= 0;
   end Struct_Has_Name;

   --------------------
   -- Value_Has_Name --
   --------------------

   function Value_Has_Name (V : Value_T) return Boolean is
      function Value_Has_Name (V : Value_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Value_Has_Name";
   begin
      return Value_Has_Name (V) /= 0;
   end Value_Has_Name;

   ---------------------------
   -- Is_Lifetime_Intrinsic --
   ---------------------------

   function Is_Lifetime_Intrinsic (V : Value_T) return Boolean is
      function Is_Lifetime_Intrinsic (V : Value_T) return LLVM_Bool
        with Import, Convention => C, External_Name => "Is_Lifetime_Intrinsic";
   begin
      return Is_Lifetime_Intrinsic (V) /= 0;
   end Is_Lifetime_Intrinsic;

   --------------------------------
   -- All_Preds_Are_Unc_Branches --
   --------------------------------

   function All_Preds_Are_Unc_Branches (BB : Basic_Block_T) return Boolean is
      function All_Preds_Are_Unc_Branches (BB : Basic_Block_T) return LLVM_Bool
        with Import, Convention => C,
             External_Name => "All_Preds_Are_Unc_Branches";

   begin
      return All_Preds_Are_Unc_Branches (BB) /= 0;
   end All_Preds_Are_Unc_Branches;

   -------------------------
   -- Is_Dead_Basic_Block --
   -------------------------

   function Is_Dead_Basic_Block (BB : Basic_Block_T) return Boolean is
      function Is_Dead_Basic_Block (BB : Basic_Block_T) return LLVM_Bool
        with Import, Convention => C,
             External_Name => "Is_Dead_Basic_Block";

   begin
      return Is_Dead_Basic_Block (BB) /= 0;
   end Is_Dead_Basic_Block;

end GNATLLVM.Wrapper;
