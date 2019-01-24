------------------------------------------------------------------------------
--                             G N A T - L L V M                            --
--                                                                          --
--                     Copyright (C) 2013-2019, AdaCore                     --
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

with Sem_Aux;  use Sem_Aux;
with Sem_Util; use Sem_Util;

with GNATLLVM.GLValue;     use GNATLLVM.GLValue;
with GNATLLVM.Types;       use GNATLLVM.Types;

package GNATLLVM.GLType is

   --  To support representation clauses on objects and components, we need
   --  multiple LLVM types for the same GNAT tree type (Ada type), each
   --  corresponding to a different length and alignment.  Some of these
   --  may be biased types or may represent the maximum size of an
   --  unconstrained discriminated record with default discriminant values.
   --
   --  We maintain a table of such types, referring to the index of the
   --  table as a GL_Type.  Each table entry contains the GNAT Entity_Id of
   --  the type, the LLVM type, the size, alignment, and related flags, and
   --  a chain to record all the alternates for the GNAT type.  We create a
   --  link from the GNAT type to its first GL_Type.  One entry is
   --  designated as "primitive", meaning it's the actual type used for the
   --  value (in the case of scalar types) or the natural type (without any
   --  padding) in the case of aggregates.  One GL_Type (possibly the same
   --  one, but not necessarily) is the default for that type.

   procedure Dump_GL_Type_Int (GT : GL_Type; Full_Dump : Boolean);

   procedure Discard (GT : GL_Type)
     with Pre => Present (GT);

   function New_GT (TE : Entity_Id) return GL_Type
     with Pre  => Is_Type_Or_Void (TE),
          Post => Default_GL_Type (TE) = New_GT'Result;
   --  Create a new GL_Type with None kind for type TE.  It will be the
   --  new default type for TE

   function Create_GL_Type
     (TE       : Entity_Id;
      Size     : Uint    := No_Uint;
      Align    : Uint    := No_Uint;
      For_Type : Boolean := False;
      Max_Size : Boolean := False;
      Biased   : Boolean := False) return GL_Type
     with Pre => Is_Type_Or_Void (TE), Post => Present (Create_GL_Type'Result);
   --  Return a GL_Type (creating one if necessary) with the specified
   --  parameters.  For_Type is True if we're doing this for a type; in that
   --  case the size needs to be rounded to the alignment.  Max_Size is True
   --  if we're computing the maximum size of an unconstrained record and
   --  Biased is True if we're using a biased representation to store this
   --  integral value.

   procedure Update_GL_Type (GT : GL_Type; T : Type_T; Is_Dummy : Boolean)
     with Pre => Is_Empty_GL_Type (GT) or else Is_Dummy_Type (GT)
                 or else T = Type_Of (GT);
   --  Update GT with a new type and dummy status

   function Primitive_GL_Type (TE : Entity_Id) return GL_Type
     with Pre  => Is_Type_Or_Void (TE),
          Post => Present (Primitive_GL_Type'Result);
   --  Return the GT_Type for TE that corresponds to its basic computational
   --  form, creating it if it doesn't exist.

   function Dummy_GL_Type (TE : Entity_Id) return GL_Type
     with Pre  => Is_Type_Or_Void (TE),
          Post => Present (Dummy_GL_Type'Result);
   --  Return the GT_Type for TE that corresponds to a dummy form

   function Default_GL_Type
     (TE : Entity_Id; Create : Boolean := True) return GL_Type
     with Pre  => Is_Type_Or_Void (TE),
          Post => not Create or else Present (Default_GL_Type'Result);
   --  Return the GT_TYpe for TE that's to be used as the default for
   --  objects or components of the type.  If Create is True, make one if
   --  it doesn't already exist.  This may or may not be the same as what
   --  Primitive_GL_Type returns.

   procedure Mark_Default (GT : GL_Type)
     with Pre => Present (GT);
   --  Mark GT as the type to be used as the default representation of
   --  its corresponding GNAT type.

   function Convert
     (V              : GL_Value;
      GT             : GL_Type;
      Float_Truncate : Boolean := False) return GL_Value
     with Pre  => Is_Data (V) and then Is_Elementary_Type (GT)
                  and then Is_Elementary_Type (V),
          Post => Is_Data (Convert'Result)
                  and then Is_Elementary_Type (Convert'Result);
   --  Convert V to the type GT, with both the types of V and GT being
   --  elementary.

   function Convert_Ref (V : GL_Value; GT : GL_Type) return GL_Value
     with Pre  => Is_Reference (V),
          Post => Is_Reference (Convert_Ref'Result);
   --  Convert V, which should be a reference, into a reference to GT

   function Emit_Conversion
     (N                   : Node_Id;
      GT                  : GL_Type;
      From_N              : Node_Id := Empty;
      For_LHS             : Boolean := False;
      Is_Unchecked        : Boolean := False;
      Need_Overflow_Check : Boolean := False;
      Float_Truncate      : Boolean := False;
      No_Truncation       : Boolean := False) return GL_Value
     with Pre  => Present (GT) and then Present (N)
                  and then not (Is_Unchecked and Need_Overflow_Check),
          Post => Present (Emit_Conversion'Result);
   --  Emit code to convert N to GT, optionally in unchecked mode
   --  and optionally with an overflow check.  From_N is the conversion node,
   --  if there is a corresponding source node.

   function Emit_Convert_Value (N : Node_Id; GT : GL_Type) return GL_Value is
     (Get (Emit_Conversion (N, GT), Object))
     with Pre  => Present (GT) and then Present (N),
          Post => Present (Emit_Convert_Value'Result);
   --  Emit code to convert N to GL and get it as a value

   function Convert_Pointer (V : GL_Value; GT : GL_Type) return GL_Value
     with Pre  => Is_Access_Type (V) and then Present (GT),
          Post => Is_Access_Type (Convert_Pointer'Result);
   --  V is a reference to some object.  Convert it to a reference to GT
   --  with the same relationship.

   function Full_GL_Type (N : Node_Id) return GL_Type is
     (Default_GL_Type (Full_Etype (N)))
     with Pre => Present (N), Post => Present (Full_GL_Type'Result);

   --  Here are the access function to obtain fields from a GL_Type.
   --  Many are overloaded from the functions that obtain these fields from
   --  a GNAT type.

   function Full_Etype (GT : GL_Type) return Entity_Id
     with Pre => Present (GT), Post => Is_Type_Or_Void (Full_Etype'Result);

   function Type_Of (GT : GL_Type) return Type_T
     with Pre => Present (GT);

   function Get_Type_Size (GT : GL_Type) return GL_Value
     with Pre => Present (GT), Post => Present (Get_Type_Size'Result);

   function Get_Type_Alignment (GT : GL_Type) return GL_Value
     with Pre => Present (GT), Post => Present (Get_Type_Alignment'Result);

   function Is_Dummy_Type (GT : GL_Type) return Boolean
     with Pre => Present (GT);

   function Is_Primitive_GL_Type (GT : GL_Type) return Boolean
     with Pre => Present (GT);

   function Is_Empty_GL_Type (GT : GL_Type) return Boolean
     with Pre => Present (GT);
   --  Return True if GT is a GL_Type created by New_GT and never updated

   --  Now define functions that operate on GNAT types that we want to
   --  also operate on GL_Type's.

   function Ekind (GT : GL_Type) return Entity_Kind is
     (Ekind (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Access_Type (GT : GL_Type) return Boolean is
     (Is_Access_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Full_Designated_Type (GT : GL_Type) return Entity_Id is
     (Full_Designated_Type (Full_Etype (GT)))
     with Pre  => Is_Access_Type (GT),
          Post => Is_Type_Or_Void (Full_Designated_Type'Result);

   function Full_Base_Type (GT : GL_Type) return Entity_Id is
     (Full_Base_Type (Full_Etype (GT)))
     with Pre  => Present (GT), Post => Is_Type (Full_Base_Type'Result);

   function Is_Dynamic_Size (GT : GL_Type) return Boolean
     with Pre => Present (GT);

   function Is_Nonnative_Type (GT : GL_Type) return Boolean
     with Pre => Present (GT);

   function Is_Loadable_Type (GT : GL_Type) return Boolean is
     (Is_Loadable_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Array_Type (GT : GL_Type) return Boolean is
     (Is_Array_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Access_Subprogram_Type (GT : GL_Type) return Boolean is
    (Is_Access_Type (GT)
       and then Ekind (Full_Designated_Type (GT)) = E_Subprogram_Type)
     with Pre => Present (GT);

   function Is_Constrained (GT : GL_Type) return Boolean is
     (Is_Constrained (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Record_Type (GT : GL_Type) return Boolean is
     (Is_Record_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Composite_Type (GT : GL_Type) return Boolean is
     (Is_Composite_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Elementary_Type (GT : GL_Type) return Boolean is
     (Is_Elementary_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Scalar_Type (GT : GL_Type) return Boolean is
     (Is_Scalar_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Discrete_Type (GT : GL_Type) return Boolean is
     (Is_Discrete_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Integer_Type (GT : GL_Type) return Boolean is
     (Is_Integer_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Boolean_Type (GT : GL_Type) return Boolean is
     (Is_Boolean_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Fixed_Point_Type (GT : GL_Type) return Boolean is
     (Is_Fixed_Point_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Floating_Point_Type (GT : GL_Type) return Boolean is
     (Is_Floating_Point_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Unsigned_Type (GT : GL_Type) return Boolean is
     (Is_Unsigned_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Discrete_Or_Fixed_Point_Type (GT : GL_Type) return Boolean is
     (Is_Discrete_Or_Fixed_Point_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Modular_Integer_Type (GT : GL_Type) return Boolean is
     (Is_Modular_Integer_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Unconstrained_Record (GT : GL_Type) return Boolean is
     (Is_Unconstrained_Record (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Unconstrained_Array (GT : GL_Type) return Boolean is
     (Is_Unconstrained_Array (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Unconstrained_Type (GT : GL_Type) return Boolean is
     (Is_Unconstrained_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Access_Unconstrained_Array (GT : GL_Type) return Boolean is
     (Is_Access_Unconstrained_Array (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Packed_Array_Impl_Type (GT : GL_Type) return Boolean is
     (Is_Packed_Array_Impl_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Bit_Packed_Array_Impl_Type (GT : GL_Type) return Boolean is
     (Is_Bit_Packed_Array_Impl_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_Constr_Subt_For_UN_Aliased (GT : GL_Type) return Boolean is
     (Is_Constr_Subt_For_UN_Aliased (Full_Etype (GT)))
     with Pre => Present (GT);

   function Is_By_Reference_Type (GT : GL_Type) return Boolean is
     (Is_By_Reference_Type (Full_Etype (GT)))
     with Pre => Present (GT);

   function Requires_Transient_Scope (GT : GL_Type) return Boolean is
     (Requires_Transient_Scope (Full_Etype (GT)))
     with Pre => Present (GT);

   function Type_Needs_Bounds (GT : GL_Type) return Boolean is
     (Type_Needs_Bounds (Full_Etype (GT)))
     with Pre => Present (GT);

   function RM_Size (GT : GL_Type) return Uint is
     (RM_Size (Full_Etype (GT)))
     with Pre => not Is_Access_Type (GT);

   function Esize (GT : GL_Type) return Uint is
     (Esize (Full_Etype (GT)))
     with Pre => not Is_Access_Type (GT);

   function Component_Type (GT : GL_Type) return Entity_Id is
     (Component_Type (Full_Etype (GT)))
     with Pre => Is_Array_Type (GT), Post => Present (Component_Type'Result);

   function Number_Dimensions (GT : GL_Type) return Pos is
     (Number_Dimensions (Full_Etype (GT)))
     with Pre => Is_Array_Type (GT);

end GNATLLVM.GLType;
