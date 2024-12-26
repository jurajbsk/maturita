module sdc.codegen;
import lib.memory;
import sdc.grammar;
import llvm;

private alias T = Token;

LLVMTypeRef mapType(Token type)
{
	switch(type) {
		case T.tVoid: return LLVMVoidType();
		case T.i32: return LLVMInt32Type();
		case T.i64: return LLVMInt64Type();

		default: {
			import lib.io;
			writeln(type);
			assert(0);
		}
	}
}

struct CodeGen {
	LLVMContextRef context;
	LLVMModuleRef mod;
	LLVMBuilderRef builder;

	List!LLVMTypeRef buffer;

	void initialize() {
		// Initialize LLVM context, module, and builder
		context = LLVMContextCreate();
		mod = LLVMModuleCreateWithName("main_module");
		builder = LLVMCreateBuilderInContext(context);

		// Optional: Initialize targets (for code generation)
		LLVMInitializeNativeTarget();
	}

	void* toValue(ulong num, Token numType)
	{
		LLVMTypeRef type = mapType(numType);
		return LLVMConstInt(type, num, false);
	}
	void* addFunc(Variable decl, Variable[] args)
	{
		foreach(arg; args) {
			LLVMTypeRef llvmType = mapType(arg.type);
			buffer.add(llvmType);
		}
		LLVMTypeRef retType = mapType(decl.type);
		LLVMTypeRef* argTypes;
		if(args.length) {
			argTypes = &buffer[$-args.length];
		}
		LLVMTypeRef funcType = LLVMFunctionType(retType, argTypes, cast(uint)args.length, false);

		char[255] name = decl.ident;
		name[decl.ident.length] = 0;
		LLVMValueRef func = LLVMAddFunction(mod, name.ptr, funcType);

		foreach(i, arg; args) {
			LLVMValueRef param = LLVMGetParam(func, cast(uint)i);
			LLVMSetValueName2(param, arg.ident.ptr, arg.ident.length);
		}

		LLVMBasicBlockRef entryBlock = LLVMAppendBasicBlockInContext(context, func, "");
        LLVMPositionBuilderAtEnd(builder, entryBlock);
		return func;
	}
	void addRet(void* value)
	{
		LLVMBuildRet(builder, cast(LLVMValueRef)value);
	}
	void addRetVoid()
	{
		LLVMBuildRetVoid(builder);
	}
	void* addVar(Variable var)
	{
		LLVMBasicBlockRef origBlock = LLVMGetInsertBlock(builder);
		LLVMValueRef curFunc = LLVMGetBasicBlockParent(origBlock);
		LLVMBasicBlockRef entryBlock = LLVMGetEntryBasicBlock(curFunc);
		LLVMValueRef firstInstr = LLVMGetFirstInstruction(entryBlock);
		if(firstInstr) {
			LLVMPositionBuilderBefore(builder, firstInstr);
		}

		LLVMTypeRef type = mapType(var.type);
		char[255] name = var.ident;
		name[var.ident.length] = 0;
		LLVMValueRef alloca = LLVMBuildAlloca(builder, type, name.ptr);
		LLVMPositionBuilderAtEnd(builder, origBlock);
		return alloca;
	}
	void* addAssign(void* value, void* var)
	{
		return LLVMBuildStore(builder, cast(LLVMValueRef)value, cast(LLVMValueRef)var);
	}

	void dumpIR(string fileName) {
		char* error;
		LLVMPrintModuleToFile(mod, fileName.ptr, &error);
		import lib.string, lib.io;
		if(error) {
			writeln(parseCStr(error));
		}
	}
}