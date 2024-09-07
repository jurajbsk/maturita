module sdc.parsetable;
import sdc.grammar;
alias p_size = uint;

struct Item {
    NonTerm nonTerm;
	p_size prodId;
    p_size position;

	bool complete() {
		if(__ctfe) {
			assert(grammarTable.length >= nonTerm && grammarTable[nonTerm] != Rule());
			return position == grammarTable[nonTerm].def[prodId].length;
		} assert(0);
	}
}

Item[] closure(Item item)
{
	if(__ctfe) {
		Item[] result = [item];
		
		for(uint i; i < result.length; i++)
		{
			NonTerm cur = result[i].nonTerm;
			foreach(j, Symbol[] prod; grammarTable[cur].def)
			{
				foreach(Symbol sym; prod) {
					if(sym.type != Symbol.Type.NonTerminal || sym.nont == cur)
					{
						continue;
					}
					foreach(k, Symbol[] symProd; grammarTable[sym.nont].def) {
						Item newItem = Item(sym.nont, cast(p_size)k);

						bool alreadyIn;
						foreach(Item t; result) {
							if(newItem == t) {
								alreadyIn = true;
							}
						}
						if(!alreadyIn) {
							result ~= newItem;
						}
					}
				}
			}
		}
		return result;
	} assert(0);
}

Item[] goTo(Item[] items, Symbol sym)
{
	if(__ctfe) {
		Item[] result;
		foreach (Item item; items)
		{
			if(!item.complete && grammarTable[item.nonTerm].def[item.prodId][item.position] == sym) {
				item.position++;
				result ~= item.closure();
			}
		}
		return result;
	} assert(0);
}

Symbol[] allSymbols()
{
	if(__ctfe) {
		Symbol[] result;
		static foreach(member; [__traits(allMembers, NonTerm)]) {{
			NonTerm nont = __traits(getMember, NonTerm, member);
			result ~= Symbol(nont);
		}}
		static foreach(member; [__traits(allMembers, TokType)]) {{
			TokType term = __traits(getMember, TokType, member);
			result ~= Symbol(term);
		}}
		return result;
	} assert(0);
}

Item[][] canonCollection() {
	if(__ctfe) {
		Item[][] result = [closure(Item(NonTerm.File))];

		while (true) {
			bool added = false;
			foreach(Item[] items; result) {
				foreach(Symbol sym; allSymbols()) {
					Item[] gotoSet = goTo(items, sym);
					bool alreadyIn;
					foreach(Item[] t; result) {
						if(t == gotoSet) {
							alreadyIn = true;
						}
					}
					if(gotoSet && !alreadyIn) {
						result ~= gotoSet;
						added = true;
					}
				}
			}
			if(!added) break;
		}
		return result;
	} assert(0);
}

struct Prod {
	NonTerm nonTerm;
	p_size length;
}
enum ActionType : ubyte {
	Error, Shift, Reduce, Accept
}
struct Action {
	ActionType type;
	union {
		p_size state;
		Prod reduce;
	}
}
struct ParseTable {
	p_size[NonTerm.max+1][canonCollection.length] gotoTable;
	Action[TokType.max+1][canonCollection.length] actionTable;
}

ParseTable makePTable(NonTerm startSym)
{
	if(__ctfe) {
		ParseTable result;
		Item[][] states = canonCollection();

		foreach(i, Item[] state; states)
		{
			foreach(Item item; state) {
				if(item.complete) {
					if(item.nonTerm == startSym) {
						result.actionTable[i] = Action(ActionType.Accept);
					}
					else {
						TokType[] followSet = item.nonTerm.follow;
						foreach(TokType term; followSet) {
							Prod prod = Prod(item.nonTerm, cast(p_size)grammarTable[item.nonTerm].def[item.prodId].length);
							result.actionTable[i][term] = Action(ActionType.Reduce, reduce: prod);
						}
					}
				}
				else {
					Symbol curSym = grammarTable[item.nonTerm].def[item.prodId][item.position];
					p_size nextState;
					
					bool goExists;
					Item[] goSet = goTo(state, curSym);
					foreach(j, Item[] st; states) {
						if(st == goSet) {
							nextState = cast(p_size) j;
							goExists = true;
							break;
						}
					}
					final switch(curSym.type) {
						case Symbol.Type.Terminal: {
							result.actionTable[i][curSym.term] = Action(ActionType.Shift, state: nextState);
						} break;
						case Symbol.Type.NonTerminal: {
							result.gotoTable[i][curSym.nont] = nextState;
						} break;
					}
				}
			}
		}
		return result;
	} assert(0);
}