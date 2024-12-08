module src.sdc.symtable;
import lib.memory;
import sdc.grammar : Token;

struct SymbolData {
	string name;
	Token type;
}

struct SymbolTable {
	List!SymbolData table;
	uint scopeLen;

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
		SymbolData marker = SymbolData(null, cast(Token)scopeLen);
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