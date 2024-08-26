module sdc.lexer;
import lib.io;
public import sdc.lexertypes;
import sdc.grammar : TokType;

immutable string[] resKeywords = [
	TokType.Module: "module",
	TokType.Import: "import",
	TokType.Type: "void"
];

immutable char[] resSymbols = [
	TokType.LBrace: '{',
	TokType.RBrace: '}',
	TokType.LParen: '(',
	TokType.RParen: ')',
	TokType.SemiCol: ';',
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
				token = Token(TokType.Type, TokenVal(LangType.Void));
				break loop;
			}
			// Reserved symbols
			enum minElement = TokType.LBrace;
			switch(buf[$-1]) {
				static foreach(i0, symbol; resSymbols[minElement..$]) {
					case symbol: {
						if(i > 1) {
							i--;
							token = Token(TokType.Ident, TokenVal(identifier: buf[0..$-1]));
							break loop;
						}
						token = Token(cast(TokType)(i0+minElement));
					} break loop;
				}
				case 0: {
					token = Token(TokType.EOF);
				} break loop;
				default: break;
			}
			if(buf[i-1] == ' ') {
				if(i == 1) {
					cursor++;
					i--;
					continue;
				}
				token = Token(TokType.Ident, TokenVal(identifier: buf));
				break loop;
			}
		}
		cursor += i;
		current = token;
		return token;
	}
}