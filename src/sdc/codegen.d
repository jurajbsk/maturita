module sdc.codegen;
import lib.memory;
import sdc.grammar : NonTerm, p_size;
import sdc.parser : ASTNode, NodeValue;

import llvm;
pragma(lib, "D:\\Software\\LLVM\\lib\\LLVM-C.lib");


void codeGen(List!ASTNode ast) {
	LLVMModuleRef mod = LLVMModuleCreateWithName("Module");

	// Postorder tree traversal
	size_t curParent;
	List!p_size stack;
	foreach_reverse(i, ASTNode node; ast) {
		if(node.childLen > 0) {
			stack.add(i);
			curParent = i;
		}
		else {
			
		}
	}
}

void fun(ASTNode node, LLVMModuleRef mod)
{
	switch(node.nodeType) {
		default: break;
	}
}
