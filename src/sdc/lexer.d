module sdc.lexer;
import lib.io;
public import sdc.lexertypes;

enum string[] tokenTable = [
	TokenType.ScopeStart: "{",
	TokenType.ScopeEnd: "}",
	TokenType.ParenOpen: "(",
	TokenType.ParenClose: ")",
	TokenType.LineEnd: ";",
	TokenType.Module: "module",
	TokenType.Import: "import"
];

struct Tokenizer {
	string code;
	uint locs;

	Token current;
	alias current this;
	Token next()
	{
		Token token;
		string[tokenTable.length] table = tokenTable;
		uint i;
		loop: while(true) {
			string buf = code[0..i];
			switch(buf) {
				case "void": {
					token = Token(TokenType.Type, TokenVal(Typing.Void));
				} break loop;
				default: break;
			}
			i++;
			if(code[i] == ' ') {
				token = Token(TokenType.Identifier, TokenVal(identifier: code[0..i-1]));
				break loop;
			}
		}

		code = code[i..$];
		current = token;
		return token;
	}

	bool expect(TokenType type)
	{
		bool expected = (current == type);
		if(!expected) {
			writeln("Expected '", type, "' instead of '", );
		}
		return expected;
	}
	bool expectAny(TokenType[] types)()
	{
		bool res;
		foreach(type; types) {
			res |= (current == type);
		}
		return res;
	}
	bool expectNext(TokenType type)
	{
		next();
		return expect(type);
	}
	bool expectAnyNext(TokenType[] types)()
	{
		next();
		return expectAny!(types);
	}
}