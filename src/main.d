import lib.string;
import sdc.parser;
import lib.memory;

extern(C) int main(int argc, char** args)
{
	// Handling args
	string inPath, outPath;
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
	}

	// AST
	List!AST ast = parse("void fun() {}");
	return 0;
}