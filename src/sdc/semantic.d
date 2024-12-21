module sdc.semantic;
import sdc.grammar;

struct Semantic {
	FuncHeader lastFunc;

	void checkRet(Token type)
	{
		assert(type == lastFunc.decl.type, "Error: Return type doesn't match function type");
	}
}