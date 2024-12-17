import lib.io, lib.string, lib.memory;
import sdc.grammar : NonTerm;
import sdc.parser;
import sdc.codegen;

version(Windows) {
	import lib.sys.windows.kernel32;
	extern(Windows) void* CreateFileA(char* fileName, uint, uint, void*, uint, uint, void*);
}

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

	if(argc < 2) {
		writeln("No source file specified.");
		return -1;
	}
	void* file = CreateFileA(args[1], 0x80000000, 0x00000001, null, 3, 128, null);
	if(cast(long)file == -1) {
		writeln("No file named \"", parseCStr(args[1]), "\".");
		return -1;
	}
	void* mapping = CreateFileMappingA(file, null, 0x02, 0, 0);
	char* sourceCode = cast(char*)MapViewOfFile(mapping, 0x04);
	
	debug {
		import lib.time;
		ulong time = getTicks();
	}
	parse(sourceCode);
	debug {
		writeln("Seconds elapsed: ", cast(ulong)(elapsed(time)*1000), "ms");
	}
	
	return 0;
}