module sdc.parsetable;
import sdc.grammar;

struct Item {
    NonTerm nonTerm;
    size_t position;

	bool complete() {
		if(__ctfe) {
			return position >= grammarTable[nonTerm].def.length;
		} assert(0);
	}
}

Item[] closure(Item item)
{
	if(__ctfe) {
		Item[] result = [item];
		bool[NonTerm.max] used;
		
		for(uint i; i < result.length; i++)
		{
			NonTerm cur = result[i].nonTerm;
			foreach(Symbol[] prod; grammarTable[cur].def)
			{
				foreach(Symbol sym; prod) {
					if(sym.type == Symbol.Type.NonTerminal && !used[sym.nont]) {
						used[sym.nont] = true;
						result ~= Item(sym.nont);
					}
				}
			}
		}
		return result;
	} assert(0);
}

Item[] goNont(Item[] items, NonTerm n)
{
	if(__ctfe) {
		Item[] result;
		foreach (Item item; items)
		{
			if(!item.complete && item.nonTerm == n) {
				result ~= Item(item.nonTerm, item.position+1).closure();
			}
		}
		return result;
	} assert(0);
}

Item[][] canonCollection() {
	if(__ctfe) {
		Item[][] result = [closure(Item(NonTerm.File))];

		for(uint i; i < result.length; i++)
		{
			Item[] items = result[i];
			foreach(Item item; items) {
				if(item.complete) {
					continue;
				}
				Symbol[] curSymbols = grammarTable[item.nonTerm].def[item.position];
				foreach(Symbol sym; curSymbols) {
					if(sym.type == Symbol.Type.NonTerminal) {
						Item[] goSet = goNont(items, sym.nont);
						bool inResult;
						foreach(Item[] t; result) {
							if(t == goSet) {
								inResult = true;
							}
						}
						if(!inResult) {
							result ~= goSet;
						}
					}
				}
			}
		}
		return result;
	} assert(0);
}

enum test = Item(NonTerm.File).closure;
pragma(msg, test);
pragma(msg, test.goNont(NonTerm.FuncDecl));
pragma(msg, canonCollection);