module sdc.grammar;
alias p_size = uint;

struct Symbol {
	union {
		Token term;
		NonTerm nont;
	}
	Type type;

	enum Type : ubyte {
		Terminal,
		NonTerminal,
	}

	this(Token t) {
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
			def ~= [[]];
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

enum Token : ubyte {
	EOF,

	LBrace,
	RBrace,
	LParen,
	RParen,
	Comma,
	SemiCol,
	Equals,

	Module,
	Import,
	Return,

	tVoid,
	i32,
	i64,

	Ident,
	NumLiteral,
}
enum NonTerm : ubyte {
	File,

	StmntList,
	Stmnt,
	//StmntType,

	FuncDecl,
	FuncHeader,
	ArgsHead,
	Args,

	StmntBody,

	Expr,
	ExprStmnt,
	ReturnStmnt,

	VarDecl,
	Type,
}
private {
	alias l = Rule;
	alias T = Token;
	alias n = NonTerm;
	Rule Any(S...)(S elements) {
		if(__ctfe) {
			Rule res;
			foreach(Symbol sym; elements) {
				res.def ~= [sym];
			}
			return res;
		} assert(0);
	}
}
enum Rule[NonTerm.max+1] grammarTable = [
	n.File: l(n.FuncDecl),

	n.FuncDecl: l(n.FuncHeader, n.StmntBody),
	n.FuncHeader: l(n.VarDecl, T.LParen, n.ArgsHead, T.RParen),
	n.ArgsHead: l(n.Args) | l(n.Args, n.VarDecl),
	n.Args: l(n.Args, n.VarDecl, T.Comma) | l(null),

	n.StmntBody: l(T.LBrace, n.StmntList, T.RBrace),
	n.StmntList: l(n.Stmnt) | l(n.Stmnt, n.StmntList),
	n.Stmnt: /*l(n.StmntType, n.StmntBody) |*/ l(n.ExprStmnt, T.SemiCol),

	n.ExprStmnt: Any(n.VarDecl, n.ReturnStmnt),
	n.ReturnStmnt: l(T.Return) | l(T.Return, n.Expr),
	n.Expr: l(T.NumLiteral),

	n.VarDecl: l(n.Type, T.Ident),

	n.Type: Any(T.tVoid, T.i32, T.i64)
];

struct VarDecl {
	align(1):
	Token type;
	string ident;
}
struct FuncHeader {
	align(1):
	Token type;
	string ident;
	ubyte args;
}