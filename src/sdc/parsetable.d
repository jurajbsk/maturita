module sdc.parsetable;
import sdc.grammar;

struct FirstRes {
	Token[] toks;
	alias toks this;
	bool nullable;
}

FirstRes first(Symbol s)
{
	if(__ctfe) {
		FirstRes result;
		
		with(Symbol.Type)
		final switch(s.type)
		{
			case Terminal: {
				result ~= s.term;
			} break;

			case NonTerminal: {
				Rule rule = grammarTable[s.nont];

				foreach(Symbol[] prod; rule.def)
				{
					if(!prod) {
						result.nullable = true;
					}
					foreach(Symbol sym; prod)
					{
						if(sym == s) {
							continue;
						}
						FirstRes set = sym.first;
						foreach(Token t1; set) {
							bool duplicate;
							foreach(Token t2; result) {
								if(t1 == t2) {
									duplicate = true;
								}
							}
							if(!duplicate) {
								result ~= t1;
							}
						}
						if(!set.nullable) {
							break;
						}
					}
				}
			} break;
		}
		return result;
	} assert(0);
}
Token[] follow(NonTerm n)
{
	if(__ctfe) {
		Token[] result;

		foreach(NonTerm curNonterm, Rule rule; grammarTable) {
			Token[] resultQueue;
			foreach(Symbol[] prod; rule.def) {
				foreach(i, Symbol symbol; prod)
				{
					if(symbol != Symbol(n)) {
						continue;
					}

					if(prod.length > i+1) {
						FirstRes firstSet = prod[i+1].first;
						if(!firstSet) {
							if(firstSet.nullable) {
								result ~= curNonterm.follow;
							} else {
								result ~= prod[i+1].nont.follow;
							}
						}
						else {
							resultQueue ~= firstSet;
						}
					}
					else if(curNonterm != n) {
						resultQueue ~= curNonterm.follow;
					}
				}
			}
			foreach(Token t1; resultQueue) {
				bool duplicate;
				foreach(Token t2; result) {
					if(t1 == t2) {
						duplicate = true;
					}
				}
				if(!duplicate) {
					result ~= t1;
				}
			}
		}
		if(!result) {
			result = [Token.EOF];
		}
		return result;
	} assert(0);
}

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

Item[] closure(Item startItem)
{
	if(__ctfe) {
		Item[] result = [startItem];
		
		for(uint i; i < result.length; i++)
		{
			Item cur = result[i];
			Symbol[] prod = grammarTable[cur.nonTerm].def[cur.prodId];
			foreach(Symbol sym; prod[cur.position..$])
			{
				if(sym.type != Symbol.Type.NonTerminal) {
					continue;
				}
				foreach(k, Symbol[] symProd; grammarTable[sym.nont].def)
				{
					Item newItem = Item(sym.nont, cast(p_size)k);

					bool exists;
					foreach(Item item; result) {
						if(newItem == item) {
							exists = true;
							break;
						}
					}
					if(!exists) {
						result ~= newItem;
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
		foreach(Item item; items)
		{
			if(item.complete) {
				continue;
			}
			Symbol curSym = grammarTable[item.nonTerm].def[item.prodId][item.position];
			if(curSym == sym) {
				item.position++;
				Item[] closure = closure(item);

				foreach(Item newItem; closure) {
					bool exists;
					foreach(Item resItem; result) {
						if(newItem == resItem) {
							exists = true;
							break;
						}
					}
					if(!exists) {
						result ~= newItem;
					}
				}
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
		static foreach(member; [__traits(allMembers, Token)]) {{
			Token term = __traits(getMember, Token, member);
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

					if(!gotoSet) {
						continue;
					}
					bool exists;
					foreach(Item[] t; result) {
						if(t == gotoSet) {
							exists = true;
							break;
						}
					}
					if(!exists) {
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
	Action[Token.max+1][canonCollection.length] actionTable;
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
						Token[] followSet = item.nonTerm.follow;
						foreach(Token term; followSet) {
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
					assert(goExists);
					final switch(curSym.type) {
						case Symbol.Type.Terminal: {
							Action nextAction = Action(ActionType.Shift, state: nextState);
							result.actionTable[i][curSym.term] = nextAction;
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