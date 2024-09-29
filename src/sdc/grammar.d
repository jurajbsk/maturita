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

struct Rule {
	Symbol[][] def;

	this(S...)(S symbols) {
		def = [[]];
		foreach(Symbol cur; symbols) {
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

enum TokType : ubyte {
	EOF,

	LBrace,
	RBrace,
	LParen,
	RParen,
	Comma,
	SemiCol,

	Assign,

	Module,
	Import,
	Return,

	tVoid,
	i32,
	i64,

	Ident,
	Number,
	Null
}
enum NonTerm : ubyte {
	File,

	Stmnt,
	StmntList,
	ExprStmnt,
	StmntType,

	FuncDecl,
	Args,

	FuncInfo,
	VarDecl,
	Type
}
alias l = Rule;
alias T = TokType;
alias n = NonTerm;
enum Rule[] grammarTable = [
	n.File: l(n.FuncDecl),

	n.StmntList: l(n.Stmnt, n.StmntList) | l(null),
	n.Stmnt: l(n.StmntType, T.LBrace, n.StmntList, T.RBrace) | l(n.ExprStmnt, T.SemiCol),
	n.ExprStmnt: l(T.Return),

	n.FuncDecl: l(n.FuncInfo, T.LBrace, /*n.StmntList,*/ T.RBrace),
	n.Args: l(n.VarDecl) | l(n.VarDecl, T.Comma, n.Args) | l(null),

	n.FuncInfo: l(n.Type, T.Ident, T.LParen, n.Args, T.RParen),
	n.VarDecl: l(n.Type, T.Ident),
	n.Type: l(T.tVoid) | l(T.i32) | l(T.i64)
];