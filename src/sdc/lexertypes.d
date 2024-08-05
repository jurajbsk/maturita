module sdc.lexertypes;

enum TokenType {
	Unknown,
	
	ScopeStart,
	ScopeEnd,
	ArgOpen,
	ArgClose,
	LineEnd,

	Operator,
	Module,
	Import,
	Type,

	Identifier,
	Number,
	EOF,
}
struct Token {
	TokenType type;
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