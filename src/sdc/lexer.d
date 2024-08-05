module sdc.lexer;
import lib.io;
public import sdc.lexertypes;

immutable string[] resKeywords = [
	TokenType.Module: "module",
	TokenType.Import: "import",
	TokenType.Type: "void"
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
		loop: while(++i) {
			string buf = code[cursor..i+cursor];
			// Reserved keywords
			if(buf == "void") {
				token = Token(TokenType.Type, TokenVal(LangType.Void));
				break loop;
			}
			// Reserved symbols
			switch(buf[$-1]) {
				static foreach(i0, symbol; resSymbols) {
					case symbol: {
						if(i > 1) {
							i--;
							token = Token(TokenType.Identifier, TokenVal(identifier: buf[0..$-1]));
							break loop;
						}
						token = Token(cast(TokenType)i0);
					} break loop;
				}
				case 0: {
					token = Token(TokenType.EOF);
				} break loop;
				default: break;
			}
			if(buf[i-1] == ' ') {
				if(i == 1) {
					cursor++;
					i--;
					continue;
				}
				token = Token(TokenType.Identifier, TokenVal(identifier: buf));
				break loop;
			}
		}
		cursor += i;
		current = token;
		return token;
	}

	bool expect(TokenType type)
	{
		next();
		bool expected = (current == type);
		if(!expected) {
			writeln("Expected '", type, "' instead of '", );
		}
		return expected;
	}
	// bool expectAny(TokenType[] types)()
	// {
	// 	bool res;
	// 	foreach(type; types) {
	// 		res |= (current == type);
	// 	}
	// 	return res;
	// }
	// bool expectNext(TokenType type)
	// {
	// 	next();
	// 	return expect(type);
	// }
	// bool expectAnyNext(TokenType[] types)()
	// {
	// 	next();
	// 	return expectAny!(types);
	// }
}