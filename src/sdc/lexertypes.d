module sdc.lexertypes;

enum TokType : ubyte {
	Unknown,
	
	LBrace,
	RBrace,
	LParen,
	RParen,
	LineEnd,

	Operator,
	Module,
	Import,
	Type,

	Ident,
	Number,
	EOF,
}
struct Token {
	TokType type;
	alias type this;
	TokenVal value;
}

enum LangType {
	Enum,
	Void,
	Int,

}

enum Operator {
	Assign,
	Increment,
	Decrement
}

union TokenVal {
	LangType type;
	Operator op;
	string identifier;
}