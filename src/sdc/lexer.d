module sdc.lexer;
import sdc.grammar : Token;

alias T = Token;
immutable char[] resSymbols = [
	T.LBrace: '{',
	T.RBrace: '}',
	T.LParen: '(',
	T.RParen: ')',
	T.Comma: ',',
	T.SemiCol: ';',
];
immutable string[] resKeywords = [
	T.Module: "module",
	T.Import: "import",
	T.Return: "return",
	T.tVoid: "void",
	T.i32: "int",
	T.i64: "long",
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
			int a = 3;
			a = 3+2;
			// Reserved keywords
			switch(buf) {
				enum minElement = Token.Module;
				static foreach(i0, keyword; resKeywords[minElement..$]) {
					case keyword: {
						token = cast(Token)(i0+minElement);
					} break loop;
				}
				default: break;
			}

			char lastChar = buf[$-1];
			// Reserved symbols
			switch(lastChar) {
				enum minElement = Token.LBrace;
				static foreach(i0, symbol; resSymbols[minElement..$]) {
					case symbol: {
						if(length > 1) {
							length--;
							token = Token.Ident;
							break loop;
						}
						token = Token(cast(Token)(i0+minElement));
					} break loop;
				}
				case 0: {
					token = Token(Token.EOF);
				} break loop;
				default: break;
			}
			if(lastChar == ' ' || lastChar == '\n') {
				if(length == 1) {
					cursor++;
					length--;
					continue;
				}
				token = Token.Ident;
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