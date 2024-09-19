module sdc.grammar;
alias p_size = uint;

struct Symbol {
	union {
		TokType term;
		NonTerm nont;
	}
	Type type;

	enum Type : ubyte {
		Terminal,
		NonTerminal,
	}

	this(TokType t) {
		term = t;
		type = Type.Terminal;
	}
	this(NonTerm n) {
		nont = n;
		type = Type.NonTerminal;
	}
	bool opEquals(const Symbol sym) {
		if(type != sym.type) {
			return false;
		}
		final switch(type)
		{
			case Type.Terminal:
				return term == sym.term;
			case Type.NonTerminal:
				return nont == sym.nont;
		}
	}
}
enum TokType : ubyte {
	Unknown,
	
	Module,
	Import,
	Type,

	LBrace,
	RBrace,
	LParen,
	RParen,
	Comma,
	SemiCol,

	Operator,

	Ident,
	Number,
	EOF,
	Null
}
struct Rule {
	Symbol[][] def;

	this(S...)(S symbols) {
		def = [[]];
		foreach(Symbol cur; symbols) {
			// foreach (Symbol[] key; def)
			// {
				
			// }
			def[$-1] ~= cur;
		}
	}
	this(typeof(null) nullable) {
		if(__ctfe) {
			def ~= [[Symbol(T.Null)]];
		}
	}
	this(Symbol[][] s) {
		def = s;
	}
	Rule opBinary(string op : "|")(Rule rhs)
	{
		if(__ctfe) {
			return Rule(def ~ rhs.def);
		} assert(0);
	}
}

TokType[] first(Symbol s)
{
	if(__ctfe) {
		TokType[] result;
		
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
					bool hasNull;
					foreach(Symbol sym; prod)
					{
						if(sym == s) {
							continue;
						}
						TokType[] set = sym.first;
						foreach(TokType tok; set)
						{
							if(sym == Symbol(TokType.Null)) {
								hasNull = true;
							}
							else {
								result ~= tok;
							}
						}
						if(!hasNull) {
							break;
						}
					}
					if(hasNull) {
						result ~= TokType.Null;
					}
				}
			} break;
		}
		return result;
	} assert(0);
}
TokType[] follow(NonTerm n)
{
	if(__ctfe) {
		TokType[] result;

		foreach(NonTerm curNonterm, Rule rule; grammarTable) {
			foreach(Symbol[] prod; rule.def) {
				foreach(i, Symbol symbol; prod)
				{
					if(symbol != Symbol(n)) {
						continue;
					}

					if(prod.length > i+1) {
						TokType[] set = prod[i+1].first;
						bool hasNull;
						foreach(TokType tok; set) {
							if(tok == TokType.Null) {
								hasNull = true;
							}
							else {
								result ~= tok;
							}
						}
						if(hasNull) {
							if(set == [TokType.Null]) {
								result ~= curNonterm.follow;
							} else {
								result ~= prod[i+1].nont.follow;
							}
						}
					}
					else if(curNonterm != n) {
						result ~= curNonterm.follow;
					}
				}
			}
		}
		if(!result) {
			result = [TokType.EOF];
		}
		return result;
	} assert(0);
}

enum NonTerm : ubyte {
	File,
	FuncDecl,
	Args,

	Stmnt,
	StmntList,
	ExprStmnt,
	StmntType,

	VarDecl,
	OptComma,
}
alias l = Rule;
alias T = TokType;
alias n = NonTerm;
enum Rule[] grammarTable = [
	n.File: l(n.FuncDecl),
	n.FuncDecl: l(n.VarDecl, T.LParen, n.Args, T.RParen, T.LBrace, /*n.StmntList,*/ T.RBrace),
	n.Args: l(n.VarDecl) | l(n.VarDecl, T.Comma, n.Args) | l(null),

	//n.StmntList: l(n.Stmnt, n.StmntList) | l(null),
	//n.Stmnt: l(n.StmntType, T.LBrace, n.StmntList, T.RBrace) | l(n.ExprStmnt, T.SemiCol),
	//n.ExprStmnt: l(),

	n.VarDecl: l(T.Type, T.Ident),
];