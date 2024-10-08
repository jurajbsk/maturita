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

	StmntList,
	Stmnt,
	//StmntType,

	FuncDecl,
	FuncHeader,
	Args,

	StmntBody,

	ExprStmnt,
	ReturnStmnt,

	VarDecl,

	Expr,
	Type
}
alias l = Rule;
alias T = Token;
alias n = NonTerm;
enum Rule[] grammarTable = [
	n.File: l(n.FuncDecl),

	n.FuncDecl: l(n.FuncHeader, n.StmntBody),
	n.FuncHeader: l(n.VarDecl, T.LParen, n.Args, T.RParen),
	n.Args: l(n.VarDecl) | l(n.Args, T.Comma, n.VarDecl) | l(null),

	n.StmntBody: l(T.LBrace, n.StmntList, T.RBrace),
	n.StmntList: l(n.Stmnt) | l(n.Stmnt, n.StmntList),
	n.Stmnt: /*l(n.StmntType, n.StmntBody) |*/ l(n.ExprStmnt, T.SemiCol),

	n.ExprStmnt: l(n.VarDecl) | l(n.ReturnStmnt),
	n.ReturnStmnt: l(T.Return) ,//| l(T.Return, n.Expr),

	n.VarDecl: l(n.Type, T.Ident),

	// n.Expr: l(T.NumLiteral),


	n.Type: l(T.tVoid) | l(T.i32) | l(T.i64)
];
import sdc.parsetable;
pragma(msg, Item(n.File,0,0).closure);

struct VarDecl {
	Token type;
	string ident;
}
struct FuncHeader {
	Token type;
	string ident;
	VarDecl[] args;
}