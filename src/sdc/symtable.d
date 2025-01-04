module sdc.symtable;
import lib.memory;
import sdc.grammar : Token, Variable;

union SymbolData {
	struct {
		string name;
		void* valueRef;
		Token type;
		Variable[] args;
	}
	ulong scopeLen;
}

struct SymbolTable {
	List!SymbolData table;
	ulong scopeLen;

	void add(SymbolData data)
	{
		table.add(data);
		scopeLen++;
	}
	SymbolData* search(string name)
	{
		SymbolData* res;
		foreach(ref SymbolData d; table) {
			if(d.name == name) {
				res = &d;
				break;
			}
		}
		return res;
	}
	void addScope()
	{
		SymbolData marker = SymbolData(scopeLen: scopeLen);
		table.add(marker);
		scopeLen = 0;
	}
	void dropScope()
	{
		table.pop(scopeLen);
		SymbolData marker = table.pop();
		scopeLen = marker.type;
	}
}