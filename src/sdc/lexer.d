module sdc.lexer;

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
	ushort length;

	Token current;
	Token next()
	{
		Token token;
		length = 0;
		loop: while(++length)
		{
			string buf = code[cursor..cursor+length];
			// Reserved keywords
			if(buf == "void") {
				token = Token(TokType.Type);
				break loop;
			}
			// Reserved symbols
			switch(buf[$-1]) {
				enum minElement = TokType.LBrace;
				static foreach(i0, symbol; resSymbols[minElement..$]) {
					case symbol: {
						if(length > 1) {
							length--;
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
			if(buf[length-1] == ' ') {
				if(length == 1) {
					cursor++;
					length--;
					continue;
				}
				token = Token(TokType.Ident, TokenVal(identifier: buf));
				break loop;
			}
		}
		cursor += length;
		current = token;
		return token;
	}
	string curString() {
		return code[cursor-length..cursor];
	}
}