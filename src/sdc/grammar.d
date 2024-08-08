module sdc.grammar;
import sdc.lexer : TokType;

union Symbol {
	enum Type : ubyte {
		Terminal,
		NonTerminal
	}
	Type type() {
		static assert(TokType.sizeof <= size_t.sizeof);
		return cast(Type) (nont.def.length || !nont.def.ptr);
	}
	TokType term;
	NonTerm nont;
	this(NonTerm n) {
		nont = n;
	}
	this(TokType t) {
		term = t;
	}
}
struct NonTerm {
	Symbol[][] def = [[]];

	this(S...)(S symbols) {
		foreach(cur; symbols) {
			def[$-1] ~= Symbol(cur);
		}
	}
	auto opBinary(string op : "|")(NonTerm rhs) const
	{
		def ~ rhs.def;
	}
}


alias l = NonTerm;
alias T = TokType;
enum : NonTerm {
	//File = cast(Symbol)[FuncDecl],
	FuncDecl = l(T.Type, T.LParen, T.Ident, /*Args,*/ T.RParen, T.LBrace, /*FuncBody,*/ T.RBrace),
	Args = l(),
	FuncBody = l()
}