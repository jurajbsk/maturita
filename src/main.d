import lib.string;
import sdc.parser;
import lib.memory;
import sdc.grammar:NonTerm;

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

	List!ASTNode ast = parse("void fun() {}\0");
	//pragma(msg, ast);
	//writeln(ast);
	return 0;
}