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
		case T.str: return LLVMPointerType(LLVMInt8Type, 0);

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
	void* toValue(string str)
	{
		char[255] buf = str;
		buf[str.length] = 0;
		return LLVMBuildGlobalStringPtr(builder, buf.ptr, "str");
	}
	void* addFunc(Variable decl, Variable[] args, bool external = false)
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

		if(!external) {
			LLVMBasicBlockRef entryBlock = LLVMAppendBasicBlockInContext(context, func, "");
			LLVMPositionBuilderAtEnd(builder, entryBlock);
		}
		buffer.clear();
		return func;
	}
	void addRet(void* value) {
		LLVMBuildRet(builder, cast(LLVMValueRef)value);
	}
	void addRetVoid() {
		LLVMBuildRetVoid(builder);
	}
	void* addCall(void* func, void*[] argVals)
	{
		LLVMValueRef[] llvmArgs = cast(LLVMValueRef[])argVals;
		LLVMTypeRef funcType = LLVMGlobalGetValueType(cast(LLVMValueRef)func);
		import lib.io;
		char* x = LLVMPrintValueToString(cast(LLVMValueRef)func);
		for(int i=0; x[i] !=0; i++) write(x[i]);
		write('X');
		x = LLVMPrintTypeToString(cast(LLVMTypeRef)funcType);
		for(int i=0; x[i] !=0; i++) write(x[i]);
		write('X');
		x = LLVMPrintValueToString(llvmArgs[0]);
		for(int i=0; x[i] !=0; i++) write(x[i]);
		write('X');
		return LLVMBuildCall2(builder, funcType, cast(LLVMValueRef)func, llvmArgs.ptr, cast(uint)llvmArgs.length, "");
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
	void* addLoad(void* var, Token type)
	{
		LLVMTypeRef llvmType = mapType(type);
		return LLVMBuildLoad2(builder, llvmType, cast(LLVMValueRef)var, "");
	}
	void* addPlus(void* leftValue, void* rightValue)
	{
		return LLVMBuildAdd(builder, cast(LLVMValueRef)leftValue, cast(LLVMValueRef)rightValue, "");
	}

	void dumpIR(string fileName)
	{
		char* error;
		LLVMPrintModuleToFile(mod, fileName.ptr, &error);
		import lib.string, lib.io;
		if(error) {
			writeln(parseCStr(error));
		}
	}
	void dumpObject(string fileName)
	{
		LLVMInitializeX86AsmPrinter();
		char* error;
		char* triple = LLVMGetDefaultTargetTriple();
		LLVMSetTarget(mod, triple);
		LLVMTargetRef target;
		LLVMGetTargetFromTriple(triple, &target, &error);
		LLVMTargetMachineRef targetMachine = LLVMCreateTargetMachine(target, triple, "generic", "",
			LLVMCodeGenLevelDefault, LLVMRelocDefault, LLVMCodeModelDefault);
		LLVMTargetMachineEmitToFile(targetMachine, mod, cast(char*)"object.o", LLVMObjectFile, &error);
		import lib.string, lib.io;
		if(error) {
			writeln(parseCStr(error));
		}
	}
}