import lib.string;
import sdc.parser;
import lib.memory;

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

	import lib.io;
	List!AST ast = parse("void fun() {}\0");
	foreach(cur; ast) {
		write(cur);
	} writeln();
	writeln(ast[0]);
	return 0;
}