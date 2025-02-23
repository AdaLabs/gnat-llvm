#include "llvm-c/Types.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/APInt.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DIBuilder.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Host.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Transforms/IPO.h"
#include "llvm/Transforms/IPO/AlwaysInliner.h"
#include "llvm/Transforms/Scalar/LoopPassManager.h"
#include "llvm/Transforms/Scalar/LoopRotation.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm-c/Core.h"

using namespace llvm;
using namespace llvm::sys;

extern "C"
Instruction *
Get_Latest_Instruction (IRBuilder<> *bld)
{
  return dyn_cast<Instruction>(&*--bld->GetInsertPoint ());
}

extern "C"
void
Add_Debug_Flags (Module *TheModule)
{
  TheModule->addModuleFlag (Module::Warning, "Debug Info Version",
			    DEBUG_METADATA_VERSION);
  TheModule->addModuleFlag (Module::Warning, "Dwarf Version", 4);
}

extern "C"
MDBuilder *
Create_MDBuilder_In_Context (LLVMContext &Ctx)
{
  return new MDBuilder (Ctx);
}

extern "C"
MDNode *
Create_TBAA_Root (MDBuilder *MDHelper)
{
  return MDHelper->createTBAARoot ("Ada Root");
}

extern "C"
void
Add_Cold_Attribute (Function *fn)
{
  fn->addFnAttr (Attribute::Cold);
}

extern "C"
void
Add_Dereferenceable_Attribute (Function *fn, unsigned idx,
			       unsigned long long Bytes)
{
  fn->addDereferenceableParamAttr (idx, Bytes);
}

extern "C"
void
Add_Ret_Dereferenceable_Attribute (Function *fn, unsigned long long Bytes)
{
  /* There doesn't appear to be a way to do this in LLVM 14, so skip for now.
     fn->addDereferenceableRetAttr (Bytes); */
}

extern "C"
void
Add_Dereferenceable_Or_Null_Attribute (Function *fn, unsigned idx,
				       unsigned long long Bytes)
{
   fn->addDereferenceableOrNullParamAttr (idx, Bytes);
}

extern "C"
void
Add_Ret_Dereferenceable_Or_Null_Attribute (Function *fn, 
					   unsigned long long Bytes)
{
  /* There doesn't appear to be a way to do this in LLVM 14, so skip for now.
     fn->addDereferenceableOrNullRetAttr (Bytes); */
}

extern "C"
void
Add_Inline_Always_Attribute (Function *fn)
{
  fn->addFnAttr (Attribute::AlwaysInline);
}

extern "C"
void
Add_Inline_Hint_Attribute (Function *fn)
{
  fn->addFnAttr (Attribute::InlineHint);
}

extern "C"
void
Add_Inline_No_Attribute (Function *fn)
{
  fn->addFnAttr (Attribute::NoInline);
}

extern "C"
void
Add_Fn_Readonly_Attribute (Function *fn)
{
  fn->addFnAttr (Attribute::ReadOnly);
}

extern "C"
void
Add_Named_Attribute (Function *fn, const char *name, const char *val,
		     LLVMContext &Ctx)
{
    fn->addFnAttr (Attribute::get (Ctx, StringRef (name, strlen (name)),
				   StringRef (val, strlen (val))));
}

extern "C"
void
Add_Nest_Attribute (Value *v, unsigned idx)
{
  if (Function *fn = dyn_cast<Function>(v))
    fn->addParamAttr (idx, Attribute::Nest);
  else if (CallInst *ci = dyn_cast<CallInst>(v))
    ci->addParamAttr (idx, Attribute::Nest);
  else if (InvokeInst *ii = dyn_cast<InvokeInst>(v))
    ii->addParamAttr (idx, Attribute::Nest);
}

extern "C"
void
Add_Noalias_Attribute (Function *fn, unsigned idx)
{
  fn->addParamAttr (idx, Attribute::NoAlias);
}

extern "C"
void
Add_Ret_Noalias_Attribute (Function *fn)
{
  fn->addRetAttr (Attribute::NoAlias);
}

extern "C"
void
Add_Nocapture_Attribute (Function *fn, unsigned idx)
{
  fn->addParamAttr (idx, Attribute::NoCapture);
}

extern "C"
void
Add_Non_Null_Attribute (Function *fn, unsigned idx)
{
  fn->addParamAttr (idx, Attribute::NonNull);
}

extern "C"
void
Add_Ret_Non_Null_Attribute (Function *fn, unsigned idx)
{
  fn->addRetAttr (Attribute::NonNull);
}

extern "C"
void
Add_Readonly_Attribute (Function *fn, unsigned idx)
{
  fn->addParamAttr (idx, Attribute::ReadOnly);
}

extern "C"
void
Add_Writeonly_Attribute (Function *fn, unsigned idx)
{
  fn->addParamAttr (idx, Attribute::WriteOnly);
}

extern "C"
bool
Has_Inline_Attribute (Function *fn)
{
  return fn->hasFnAttribute (Attribute::InlineHint);
}

extern "C"
bool
Has_Inline_Always_Attribute (Function *fn)
{
  return fn->hasFnAttribute (Attribute::AlwaysInline);
}

extern "C"
bool
Has_Nest_Attribute (Function *fn, unsigned idx)
{
  return fn->hasParamAttribute (idx, Attribute::Nest);
}

extern "C"
bool
Call_Param_Has_Nest (CallBase *CI, unsigned idx)
{
  return CI->getAttributes ().hasParamAttr (idx, Attribute::Nest);
}

extern "C"
MDNode *
Create_TBAA_Scalar_Type_Node (LLVMContext &ctx, MDBuilder *MDHelper,
			      const char *name, uint64_t size, MDNode *parent)
{
  Type *Int64 = Type::getInt64Ty (ctx);
  auto MDname = MDHelper->createString (name);
  auto MDsize = MDHelper->createConstant (ConstantInt::get (Int64, size));
  return MDNode::get (ctx, {parent, MDsize, MDname});
}

extern "C"
MDNode *
Create_TBAA_Struct_Type_Node (LLVMContext &ctx, MDBuilder *MDHelper,
			      const char *name, uint64_t size, int num_fields,
			      MDNode *parent, MDNode *fields[],
			      uint64_t offsets[], uint64_t sizes[])
{
  Type *Int64 = Type::getInt64Ty (ctx);
  SmallVector<Metadata *, 8> Ops (num_fields * 3 + 3);
  Ops [0] = parent;
  Ops [1] = MDHelper->createConstant (ConstantInt::get (Int64, size));
  Ops [2] = MDHelper->createString (name);
  for (unsigned i = 0; i < num_fields; i++)
    {
      Ops[3 + i * 3] = fields[i];
      Ops[3 + i * 3 + 1]
	  = MDHelper->createConstant (ConstantInt::get (Int64, offsets[i]));
      Ops[3 + i * 3 + 2]
	  = MDHelper->createConstant (ConstantInt::get (Int64, sizes[i]));
    }

  return MDNode:: get (ctx, Ops);
}

extern "C"
MDNode *
Create_TBAA_Struct_Node (LLVMContext &ctx, MDBuilder *MDHelper,
			 int num_fields, MDNode *types[], uint64_t offsets[],
			 uint64_t sizes[])
{
  Type *Int64 = Type::getInt64Ty (ctx);
  SmallVector<Metadata *, 8> Ops (num_fields * 3);
  for (unsigned i = 0; i < num_fields; i++)
    {
      Ops[i * 3]
	  = MDHelper->createConstant (ConstantInt::get (Int64, offsets[i]));
      Ops[i * 3 + 1]
	  = MDHelper->createConstant (ConstantInt::get (Int64, sizes[i]));
      Ops[i * 3 + 2] = types[i];
    }

  return MDNode:: get (ctx, Ops);
}

extern "C"
unsigned
Get_Stack_Alignment (DataLayout *dl)
{
  return dl->getStackAlignment ().value ();
}

extern "C"
MDNode *
Create_TBAA_Access_Tag (MDBuilder *MDHelper, MDNode *BaseType,
			MDNode *AccessType, uint64_t offset, uint64_t size)
{
  return MDHelper->createTBAAAccessTag (BaseType, AccessType, offset, size,
					false);
}

extern "C"
void
Set_NUW (Instruction *inst)
{
  inst->setHasNoUnsignedWrap ();
}

extern "C"
void
Set_NSW (Instruction *inst)
{
  inst->setHasNoSignedWrap ();
}

extern "C"
bool
Has_NSW (Instruction *inst)
{
  return inst->hasNoSignedWrap ();
}

extern "C"
void
Add_TBAA_Access (Instruction *inst, MDNode *md)
{
  inst->setMetadata (LLVMContext::MD_tbaa, md);
}

extern "C"
void
Set_DSO_Local (GlobalVariable *GV)
{
  GV->setDSOLocal (true);
}

/* Return nonnull if this value is a constant data.  */

extern "C"
Value *
Is_Constant_Data (Value *v)
{
  return dyn_cast<ConstantData>(v);
}

/* Say whether this struct type has a name.  */

extern "C"
bool
Struct_Has_Name (StructType *t)
{
  return t->hasName ();
}

/*  Say whether this value has a name */

extern "C"
bool
Value_Has_Name (Value *v)
{
    return v->getName ().size () != 0;
}

/* The LLVM C interface only provide single-index forms of extractvalue
   and insertvalue, so provide the multi-index forms here.  */

extern "C"
Value *
Build_Extract_Value_C (IRBuilder<> *bld, Value *aggr,
		       unsigned *IdxList, unsigned NumIdx, char *name)
{
  return bld->CreateExtractValue (aggr, makeArrayRef (IdxList, NumIdx), name);
}

extern "C"
Value *
Build_Insert_Value_C (IRBuilder<> *bld, Value *aggr, Value *elt,
		     unsigned *IdxList, unsigned NumIdx, char *name)
{
  return bld->CreateInsertValue (aggr, elt, makeArrayRef (IdxList, NumIdx),
				 name);
}

/* The LLVM C interface only provides a subset of the arguments for building
   memory copy/move/set, so we provide the full interface here.  */

extern "C"
Value *
Build_MemCpy (IRBuilder<> *bld, Value *Dst, unsigned DstAlign, Value *Src,
	      unsigned SrcAlign, Value *Size, bool isVolatile, MDNode *TBAATag,
	      MDNode *TBAAStructTag, MDNode *ScopeTag, MDNode *NoAliasTag)
{
  return bld->CreateMemCpy (Dst, MaybeAlign (DstAlign), Src,
			    MaybeAlign(SrcAlign), Size, isVolatile, TBAATag,
			    TBAAStructTag, ScopeTag, NoAliasTag);
}

extern "C"
Value *
Build_MemMove (IRBuilder<> *bld, Value *Dst, unsigned DstAlign, Value *Src,
	       unsigned SrcAlign, Value *Size, bool isVolatile,
	       MDNode *TBAATag, MDNode *ScopeTag, MDNode *NoAliasTag)
{
  return bld->CreateMemMove (Dst, MaybeAlign (DstAlign), Src,
			     MaybeAlign (SrcAlign), Size, isVolatile, TBAATag,
			     ScopeTag, NoAliasTag);
}

extern "C"
Value *
Build_MemSet (IRBuilder<> *bld, Value *Ptr, Value *Val, Value *Size,
	      unsigned align, bool isVolatile, MDNode *TBAATag,
	      MDNode *ScopeTag, MDNode *NoAliasTag)
{
  return bld->CreateMemSet (Ptr, Val, Size, MaybeAlign (align), isVolatile,
			    TBAATag, ScopeTag, NoAliasTag);
}

extern "C"
CallInst *
Create_Lifetime_Start (IRBuilder<> *bld, Value *Ptr, ConstantInt *Size)
{
  return bld->CreateLifetimeStart (Ptr, Size);
}

extern "C"
CallInst *
Create_Lifetime_End (IRBuilder<> *bld, Value *Ptr, ConstantInt *Size)
{
  return bld->CreateLifetimeEnd (Ptr, Size);
}

extern "C"
CallInst *
Create_Invariant_Start (IRBuilder<> *bld, Value *Ptr, ConstantInt *Size)
{
  return bld->CreateInvariantStart (Ptr, Size);
}

extern "C"
unsigned char
Does_Not_Throw (Function *fn)
{
  return fn->doesNotThrow () ? 1 : 0;
}

extern "C"
void
Set_Does_Not_Throw (Function *fn)
{
  return fn->setDoesNotThrow ();
}

extern "C"
unsigned char
Does_Not_Return (Function *fn)
{
  return fn->doesNotReturn () ? 1 : 0;
}

extern "C"
void
Set_Does_Not_Return (Function *fn)
{
  return fn->setDoesNotReturn ();
}

/* The LLVM C procedure Set_Volatile only works for loads and stores, not
   Atomic instructions.  */

extern "C"
void
Set_Volatile_For_Atomic (Instruction *inst)
{
  if (AtomicRMWInst *ARW = dyn_cast<AtomicRMWInst>(inst))
    ARW->setVolatile (true);
  else
    cast<AtomicCmpXchgInst>(inst)->setVolatile (true);
}

extern "C"
void
Set_Weak_For_Atomic_Xchg (AtomicCmpXchgInst *inst)
{
  inst->setWeak (true);
}

extern "C"
void
Add_Function_To_Module (Function *f, Module *m)
{
  m->getFunctionList ().push_back (f);
}

extern "C"
void
Dump_Metadata (MDNode *MD)
{
  MD->print (errs ());
}

extern "C"
unsigned
Get_Metadata_Num_Operands (MDNode *MD)
{
  return MD->getNumOperands ();
}

extern "C"
uint64_t
Get_Metadata_Operand_Constant_Value (MDNode *MD, unsigned i)
{
  return mdconst::extract<ConstantInt> (MD->getOperand (i))->getZExtValue ();
}

extern "C"
MDNode *
Get_Metadata_Operand (MDNode *MD, unsigned i)
{
  return dyn_cast<MDNode>(MD->getOperand (i));
}

extern "C"
void
Initialize_LLVM (void)
{
  // Initialize the target registry etc.  These functions appear to be
  // in LLVM.Target, but they reference static inline function, so they
  // can only be used from C, not Ada.

  InitializeAllTargetInfos ();
  InitializeAllTargets ();
  InitializeAllTargetMCs ();
  InitializeAllAsmParsers ();
  InitializeAllAsmPrinters ();
}

/* This is a dummy optimization "pass" that serves just to obtain loop
   information when generating C.

   For now, we don't actually do anything except collect information to look
   at in the debugger.  */

namespace llvm
{
  class Loop;

  struct OurLoopPass : PassInfoMixin<OurLoopPass>
  {
  public:
    PreservedAnalyses run (Loop &L, LoopAnalysisManager &AM,
			   LoopStandardAnalysisResults &AR, LPMUpdater &U);
    static bool isRequired ()
    {
      return true;
    }
  };
}

PreservedAnalyses
OurLoopPass::run (Loop &L, LoopAnalysisManager &LAM,
		  LoopStandardAnalysisResults &AR, LPMUpdater &U)
{

  auto pre = L.getLoopPreheader ();
  auto header = L.getHeader ();
  auto latch = L.getLoopLatch ();
  auto cmp = L.getLatchCmpInst ();
  auto issimple = L.isLoopSimplifyForm ();
  return PreservedAnalyses::all ();
}

extern "C"
LLVMBool
LLVM_Optimize_Module (Module *M, TargetMachine *TM, int CodeOptLevel,
		      int SizeOptLevel, bool NeedLoopInfo,
		      bool NoUnrollLoops, bool NoLoopVectorization,
		      bool NoSLPVectorization, bool MergeFunctions,
		      bool PrepareForThinLTO, bool PrepareForLTO,
		      bool RerollLoops, const char *PassPluginName,
                      char** ErrorMessage)
{
  // This code is derived from EmitAssemblyWithNewPassManager in clang

  Optional<PGOOptions> PGOOpt;
  PipelineTuningOptions PTO;
  PassInstrumentationCallbacks PIC;
  Triple TargetTriple (M->getTargetTriple ());
  OptimizationLevel Level
    = (CodeOptLevel == 1 ? OptimizationLevel::O1
       : CodeOptLevel == 2 ? OptimizationLevel::O2
       : CodeOptLevel == 3 ? OptimizationLevel::O3
       : OptimizationLevel::O0);
  PTO.LoopUnrolling = !NoUnrollLoops;
  PTO.LoopInterleaving = !NoUnrollLoops;
  PTO.LoopVectorization = !NoLoopVectorization;
  PTO.SLPVectorization = !NoSLPVectorization;
  PTO.MergeFunctions = MergeFunctions;

  LoopAnalysisManager LAM;
  FunctionAnalysisManager FAM;
  CGSCCAnalysisManager CGAM;
  ModuleAnalysisManager MAM;

  PassBuilder PB (TM, PTO, PGOOpt, &PIC);

  if (PassPluginName != nullptr)
    {
      auto Plugin = PassPlugin::Load (PassPluginName);

      if (auto Err = Plugin.takeError())
        {
          handleAllErrors(std::move(Err), [&](const StringError &Err) {
            if (ErrorMessage != nullptr)
              *ErrorMessage = strdup (Err.getMessage().c_str());
          });

          return 1;
        }

      Plugin->registerPassBuilderCallbacks(PB);
    }

  FAM.registerPass ([&] { return PB.buildDefaultAAPipeline (); });

  // Register the target library analysis directly and give it a customized
  // preset TLI.
  TargetLibraryInfoImpl *TLII = new TargetLibraryInfoImpl(TargetTriple);
  FAM.registerPass ([&] { return TargetLibraryAnalysis (*TLII); });

  // Register all the basic analyses with the managers.

  PB.registerModuleAnalyses (MAM);
  PB.registerCGSCCAnalyses (CGAM);
  PB.registerFunctionAnalyses (FAM);
  PB.registerLoopAnalyses (LAM);
  PB.crossRegisterProxies (LAM, FAM, CGAM, MAM);

  ModulePassManager MPM;
  if (CodeOptLevel == 0)
    {
      MPM = PB.buildO0DefaultPipeline (Level,
				       PrepareForLTO || PrepareForThinLTO);
      if (NeedLoopInfo)
	MPM.addPass (createModuleToFunctionPassAdaptor
		     (createFunctionToLoopPassAdaptor (LoopRotatePass ())));
    }
  else if (PrepareForThinLTO)
    MPM = PB.buildThinLTOPreLinkDefaultPipeline (Level);
  else if (PrepareForLTO)
    MPM = PB.buildLTOPreLinkDefaultPipeline (Level);
  else
    MPM = PB.buildPerModuleDefaultPipeline (Level);

  if (NeedLoopInfo)
    MPM.addPass (createModuleToFunctionPassAdaptor
		 (createFunctionToLoopPassAdaptor (OurLoopPass ())));
  MPM.run (*M, MAM);
  return 0;
}

extern "C"
Value *
Get_Float_From_Words_And_Exp (LLVMContext *Context, Type *T, int Exp,
			      unsigned NumWords, const uint64_t Words[])
{
  auto LongInt = APInt (NumWords * 64, makeArrayRef (Words, NumWords));
  auto Initial = APFloat (T->getFltSemantics (),
			  APInt::getNullValue (T->getPrimitiveSizeInBits ()));
  Initial.convertFromAPInt (LongInt, false, APFloat::rmTowardZero);
  auto Result = scalbn (Initial, Exp, APFloat::rmTowardZero);
  return ConstantFP::get (*Context, Result);
}

extern "C"
Value *
Pred_FP (LLVMContext *Context, Type *T, Value *Val)
{
  // We want to compute the predecessor of Val, but the "next" function
  // can return unnormalized, so we have to multiply by one (adding zero
  // doesn't do it).
  auto apf = dyn_cast<ConstantFP>(Val)->getValueAPF ();
  auto one = APFloat (T->getFltSemantics (), 1);
  apf.next (true);
  apf.multiply (one, APFloat::rmTowardZero);
  return ConstantFP:: get (*Context, apf);
}

extern "C"
int
Convert_FP_To_String (Value *V, char *Buf)
{
  const APFloat &APF = dyn_cast<ConstantFP>(V)->getValueAPF ();

  if (&APF.getSemantics () == &APFloat::IEEEsingle ()
      || &APF.getSemantics () == &APFloat::IEEEdouble ())
    {
      if (!APF.isInfinity () && !APF.isNaN ())
	{
	  SmallString<128> StrVal;
	  APF.toString (StrVal, 0, 0, false);

	  if (&APF.getSemantics () == &APFloat::IEEEsingle ())
	    StrVal += "f";

	  strcpy (Buf, StrVal.c_str ());
	  return strlen (Buf);
	}

      // Output special values in hexadecimal format
      std::string S =
	("0x" + utohexstr (APF.bitcastToAPInt ().getZExtValue (),
			   /*Lower=*/true)
	 + "p0");

      std::strcpy (Buf, S.c_str ());
      return S.length ();
    }

  return strlen (strcpy (Buf, "<unsupported floating point type>"));
}

extern "C"
Value *
Get_Infinity (Type *T)
{
  return ConstantFP::getInfinity (T, false);
}

extern "C"
bool
Equals_Int (ConstantInt *v, uint64_t val)
{
  return v->equalsInt (val);
}

/* Return whether V1 and V2 have the same constant values, interpreted as
   signed integers. If the sizes differ, we have to convert to the
   widest size.  */

extern "C"
bool
Equal_Constants (ConstantInt *v1, ConstantInt *v2)
{
  APInt i1 = v1->getValue (), i2 = v2->getValue ();

  if (i1.getBitWidth () > i2.getBitWidth ())
    i2 = i2.sext (i1.getBitWidth ());
  else if (i2.getBitWidth () > i1.getBitWidth ())
    i1 = i1.sext (i2.getBitWidth ());
  return i1 == i2;
}

extern "C"
bool
Get_GEP_Constant_Offset (Value *GEP, DataLayout &dl, uint64_t *result)
{
  auto Offset = APInt (dl.getTypeAllocSize (GEP->getType()) * 8, 0);
  auto GEPO = dyn_cast<GEPOperator>(GEP);

  if (!GEPO || !GEPO->accumulateConstantOffset (dl, Offset)
      || !Offset.isIntN (64))
    return false;

  *result = Offset.getZExtValue ();
  return true;
}

extern "C"
int64_t
Get_Element_Offset (DataLayout &DL, StructType *ST, unsigned idx)
{
  const StructLayout *SL = DL.getStructLayout (ST);
  return SL->getElementOffset (idx);
}

extern "C"
unsigned
Get_Num_CDA_Elements (ConstantDataArray *CA)
{
  return CA->getNumElements ();
}

extern "C"
bool
Is_C_String (ConstantDataSequential *CDS)
{
  return CDS->isCString ();
}

/* There are two LLVM "opcodes": the real LLVM opcode, which is used
   throughout the LLVM C++ interface, and a "stable" version of the
   opcodes, that's used in the C interface.  We need to map between them,
   but the only function to do so in LLVM is static (in Core.cpp), so we
   duplicate that small function here.  */

static int map_from_llvmopcode (LLVMOpcode code)
{
  switch (code)
    {
#define HANDLE_INST(num, opc, clas) case LLVM##opc: return num;
#include "llvm/IR/Instruction.def"
#undef HANDLE_INST
    }

  llvm_unreachable ("Unhandled Opcode.");
}

extern "C"
const char *
Get_Opcode_Name (LLVMOpcode opc)
{
  return Instruction::getOpcodeName (map_from_llvmopcode (opc));
}

extern "C"
BasicBlock *Get_Unique_Predecessor (BasicBlock *bb)
{
  return bb->getUniquePredecessor ();
}

extern "C"
void
Invert_Predicate (CmpInst *c)
{
  c->setPredicate (c->getInversePredicate ());
}

extern "C"
void
Swap_Successors (BranchInst *c)
{
  c->swapSuccessors ();
}

extern "C"
void
Replace_Inst_With_Inst (Instruction *from, Instruction *to)
{
  ReplaceInstWithInst (from, to);
}

extern "C"
BinaryOperator *
Create_And (Value *Op1, Value *Op2)
{
  return BinaryOperator::CreateAnd (Op1, Op2);
}

extern "C"
BinaryOperator *
Create_Or (Value *Op1, Value *Op2)
{
  return BinaryOperator::CreateOr (Op1, Op2);
}

extern "C"
CallInst *
Create_Call_2 (Function *Fn, Value *op1, Value *op2)
{
  return CallInst::Create (Fn, {op1, op2});
}

extern "C"
ReturnInst *
Create_Return (LLVMContext &C, Value *retVal)
{
  return ReturnInst::Create (C, retVal);
}

extern "C"
BranchInst *
Create_Br (BasicBlock *dest)
{
  return BranchInst::Create (dest);
}

extern "C"
void
Insert_At_Block_End (Instruction *I, BasicBlock *BB, Instruction *From)
{
  BB->getInstList ().insert (BB->end (), I);
  I->setDebugLoc (From->getDebugLoc ());
}

extern "C"
AllocaInst *
Insert_Alloca_Before (Type *Ty, Instruction *Before)
{
 auto Inst = new AllocaInst (Ty, 0, "", Before);
 Inst->setDebugLoc (Before->getDebugLoc ());
 return Inst;
}

extern "C"
LoadInst*
Insert_Load_Before (Type *Ty, Value *Ptr, Instruction *Before)
{
 auto Inst = new LoadInst (Ty, Ptr, "", Before);
 Inst->setDebugLoc (Before->getDebugLoc ());
 return Inst;
}

extern "C"
void
Insert_Store_Before (Value *Val, Value *Ptr, Instruction *Before)
{
 auto Inst = new StoreInst (Val, Ptr, Before);
 Inst->setDebugLoc (Before->getDebugLoc ());
}

extern "C"
bool
All_Preds_Are_Unc_Branches (BasicBlock *BB)
{
  for (auto *PBB : predecessors (BB))
    if (PBB->getTerminator ()->getNumSuccessors () != 1)
      return false;

  return true;
}

extern "C"
bool
Is_Dead_Basic_Block (BasicBlock *BB)
{
  return BB->hasNPredecessors (0);
}

extern "C"
Value *
Get_First_Non_Phi_Or_Dbg (BasicBlock *BB)
{
  return BB->getFirstNonPHIOrDbg ();
}

extern "C"
bool
Is_Lifetime_Intrinsic (Instruction *v)
{
  return v->isLifetimeStartOrEnd ();
}

/* If we call into CCG from GNAT LLVM during the compilation process to
   record some information about a Value (for example, its signedness),
   there's a chance that that value will be deleted during the optimization
   process and that same address used for some other value. So we need to
   set a callback on that value to notify us that this happened so we can
   delete the value from our table. The below class and function is used
   for that purpose.  */

class GNATCallbackVH final : public CallbackVH
{
  Value *val;
  void (*fn) (Value *);
  void deleted () override;

 public:
  GNATCallbackVH (Value *V, void (*Fn) (Value *));
};

void
GNATCallbackVH::deleted()
{
  delete this;
  (this->fn) (this->val);
}

GNATCallbackVH::GNATCallbackVH (Value *V, void (*Fn) (Value *))
  : CallbackVH (V), val (V), fn (Fn)
{
}

extern "C"
void
Notify_On_Value_Delete (Value *V, void (*Fn) (Value *))
{
  GNATCallbackVH *CB= new GNATCallbackVH (V, Fn);
}
