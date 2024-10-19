import lib.string;
import lib.memory;
import sdc.grammar : NonTerm;
import sdc.parser;
import sdc.codegen;

extern(C) int main(int argc, char** args)
{
	// Handling args
	/*string inPath, outPath;
	for(ubyte i; i < argc; i++) {
		string arg = parseCStr(args[i]);
		switch(arg)
		{
			case "-o": {
				i++;
				outPath = parseCStr(args[i]);
			} break;

			default: {
				if(arg[$-3..$] == ".d") {
					inPath = arg;
				}
			} break;
		}
	} */

	parse("void fun(int a, int b) {return ;}\0");
	//codeGen(ast);
	
	return 0;
}