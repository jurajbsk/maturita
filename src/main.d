import lib.io, lib.string, lib.memory;
import sdc.grammar : NonTerm;
import sdc.compile;

version(Windows) {
	import lib.sys.windows.kernel32;
	extern(Windows) void* CreateFileA(char* fileName, uint, uint, void*, uint, uint, void*);
}

extern(C) int main(int argc, char** args)
{
	// Handling args
	string inPath, outPath, ip;
	for(ubyte i; i < argc; i++)
	{
		string arg = parseCStr(args[i]);
		switch(arg)
		{
			case "-o": {
				i++;
				outPath = parseCStr(args[i]);
			} break;

			case "--serve": {
				import sdc.distribute;
				openServer();
				return 0;
			} break;
			case "--send": {
				import sdc.distribute;
				i++;
				ip = parseCStr(args[i]);
			} break;

			default: {
				inPath = arg;
			} break;
		}
	}

	if(argc < 2) {
		writeln("No source file specified.");
		return -1;
	}
	void* file = CreateFileA(cast(char*)inPath.ptr, 0x80000000, 0x00000001, null, 3, 128, null);
	if(cast(long)file == -1) {
		writeln("No file named \"", parseCStr(args[1]), "\".");
		return -1;
	}
	void* mapping = CreateFileMappingA(file, null, 0x02, 0, 0);
	char* sourceCode = cast(char*)MapViewOfFile(mapping, 0x04);
	
	if(ip) {
		import sdc.distribute;
		sendToServer(parseCStr(sourceCode), ip);
		return 0;
	}
	debug {
		import lib.time;
		ulong time = getTicks();
	}
	compile(sourceCode);
	debug {
		writeln("Seconds elapsed: ", cast(ulong)(elapsed(time)*1000), "ms");
	}
	
	return 0;
}