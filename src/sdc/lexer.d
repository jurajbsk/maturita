module sdc.lexer;
import lib.io;
public import sdc.lexertypes;

immutable string[] resKeywords = [
	TokenType.Module: "module",
	TokenType.Import: "import"
];
immutable char[] resSymbols = [
	TokenType.ScopeStart: '{',
	TokenType.ScopeEnd: '}',
	TokenType.ArgOpen: '(',
	TokenType.ArgClose: ')',
	TokenType.LineEnd: ';',
];

struct Tokenizer {
	string code;
	uint cursor;
	uint locs;

	Token current;
	alias current this;
	Token next()
	{
		Token token;
		uint i;
		loop: while(true) {
			string buf = code[cursor..i];
			// Reserved keywords
			switch(buf) {
				case "void": {
					token = Token(TokenType.Type, TokenVal(LangType.Void));
				} break loop;
				default: break;
			}
			// Reserved symbols
			switch(buf[$-1]) {
				static foreach(i0, symbol; resSymbols) {
					case symbol: {
						token = Token(cast(TokenType)i0);
					} break loop;
				}
				case 0: {
					token = Token(TokenType.EOF);
				} break loop;
				default: break;
			}
			i++;
			if(code[i] == ' ') {
				token = Token(TokenType.Identifier, TokenVal(identifier: code[0..i-1]));
				break loop;
			}
		}
		cursor += i;
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