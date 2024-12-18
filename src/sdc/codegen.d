module sdc.codegen;
import lib.memory;
import sdc.grammar;
import llvm;

alias T = Token;

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

	void addFunc(VarDecl decl, VarDecl[] args)
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
	}

	void addRet(uint num) {
		LLVMTypeRef type = LLVMInt32Type();
		LLVMValueRef val = LLVMConstInt(type, num, 0);
		LLVMBuildRet(builder, val);
	}
	void addRetVoid() {
		LLVMBuildRetVoid(builder);
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