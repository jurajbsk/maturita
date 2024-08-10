module sdc.grammar;

union Symbol {
	TokType term;
	NonTerm nont;

	enum Type : ubyte {
		Terminal,
		NonTerminal
	}
	Type type() {
		static assert(TokType.sizeof <= size_t.sizeof);
		return cast(Type) !(term || !nont.length);
	}

	this(TokType t) {
		term = t;
	}
	this(NonTerm n) {
		nont = n.def;
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
	SemiCol,

	Operator,

	Ident,
	Number,
	EOF,
	Repeat
}
struct NonTerm {
	Symbol[][] def;
	alias def this;

	TokType[] first() {
		if(__ctfe) {
			TokType[] result;
			foreach(Symbol[] alt; def)
			{
				Symbol firstSym = alt[0];
				with(Symbol.Type)
				final switch(firstSym.type) {
					case Terminal: {
						result ~= firstSym.term;
					} break;
					case NonTerminal: {
						NonTerm n = firstSym.nont;
						result ~= n.first();
					} break;
				}
			}
			return result;
		} assert(0);
	}

	this(S...)(S symbols) {
		def = [[]];
		foreach(cur; symbols) {
			def[$-1] ~= Symbol(cur);
		}
	}
	this(Symbol[][] s) {
		def = s;
	}
	NonTerm opBinary(string op : "|")(NonTerm rhs)
	{
		if(__ctfe) {
			return NonTerm(def ~ rhs.def);
		} assert(0);
	}
}

alias l = NonTerm;
alias T = TokType;
enum Grammar : NonTerm {
	File = l(FuncDecl),
	FuncDecl = l(T.Type, T.LParen, T.Ident, /*Args,*/ T.RParen, T.LBrace, /*FuncBody,*/ T.RBrace),
	Args = l(T.Type) | l([[]]),
	FuncBody = l()
}
pragma(msg, Grammar.File.first);