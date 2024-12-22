module sdc.symtable;
import lib.memory;
import sdc.grammar : Token, Variable;

struct SymbolData {
	string name;
	Token type;
	Variable[] args;
}

struct SymbolTable {
	List!SymbolData table;
	uint scopeLen;

	SymbolData* add(SymbolData data)
	{
		table.add(data);
		scopeLen++;
		return &table[$-1];
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