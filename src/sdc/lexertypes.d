module sdc.lexertypes;

enum TokenType {
	ScopeStart,
	ScopeEnd,
	ParenOpen,
	ParenClose,
	LineEnd,

	Operator,
	Module,
	Import,
	Type,

	Identifier,
	Number,
	EOF,
	Unknown
}
struct Token {
	TokenType type;
	alias type this;
	TokenVal value;
}

enum Typing {
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
	Typing type;
	Operator op;
	string identifier;
}