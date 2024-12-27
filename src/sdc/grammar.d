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
	Assign,

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
	TopList,

	FuncDecl,
	FuncHeader,
	ArgsHead,
	Args,

	StmntBody,
	StmntList,
	Stmnt,

	Expr,
	ExprStmnt,
	VarDecl,
	ReturnStmnt,
	AssignStmnt,

	Variable,
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
	n.File: l(n.TopList),
	n.TopList: l(n.FuncDecl) | l(n.TopList, n.FuncDecl),

	n.FuncDecl: l(n.FuncHeader, n.StmntBody),
	n.FuncHeader: l(n.Variable, T.LParen, n.ArgsHead, T.RParen),
	n.ArgsHead: l(n.Args) | l(n.Args, n.Variable),
	n.Args: l(n.Args, n.Variable, T.Comma) | l(null),

	n.StmntBody: l(T.LBrace, n.StmntList, T.RBrace),
	n.StmntList: l(n.Stmnt) | l(n.Stmnt, n.StmntList),
	n.Stmnt: /*l(n.StmntType, n.StmntBody) |*/ l(n.ExprStmnt, T.SemiCol),

	n.Expr: l(T.NumLiteral),
	n.ExprStmnt: Any(n.ReturnStmnt, n.AssignStmnt, n.VarDecl),
	n.VarDecl: l(n.Type, T.Ident),
	n.ReturnStmnt: l(T.Return) | l(T.Return, n.Expr),
	n.AssignStmnt: l(T.Ident, T.Assign, n.Expr) | l(n.VarDecl, T.Assign, n.Expr),

	n.Variable: l(n.Type, T.Ident),

	n.Type: Any(T.tVoid, T.i32, T.i64)
];

struct Variable {
	Token type;
	string ident;
}
struct FuncHeader {
	Variable decl;
	ubyte args;
}
struct Expression {
	void* value;
	Token type;
}
struct Assign {
	Variable var;
	Expression expr;
}