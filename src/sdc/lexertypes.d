module sdc.lexertypes;
import sdc.grammar : TokType;

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