module sdc.codegen;
import lib.memory;
import sdc.grammar : NonTerm, p_size;
import sdc.parser;

import llvm;
pragma(lib, "D:\\Software\\LLVM\\lib\\LLVM-C.lib");

/*
void codeGen(List!ASTNode ast) {
	LLVMModuleRef mod = LLVMModuleCreateWithName("Module");

	// Postorder tree traversal
	size_t curParent = 0;
	List!size_t stack;
	stack.add(ast[$-1].childLen);
	foreach_reverse(i, ASTNode node; ast[0..$-1]) {
		if(node.childLen > 0) {
			stack.add(i);
		}
		else {
			node.fun(mod);

		}
		stack[$-1]--;
	}
}*/

struct CodeGenInfo {
	LLVMModuleRef mod;
}

void fun(ref LLVMModuleRef mod)
{
	
}