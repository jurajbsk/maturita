module sdc.lexer;
import sdc.grammar : Token;

alias T = Token;
immutable Token[char.max] resSymbols = [
	'{': T.LBrace,
	'}': T.RBrace,
	'(': T.LParen,
	')': T.RParen,
	',': T.Comma,
	';': T.SemiCol,
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
			char lastChar = code[cursor+length-1];
			bool isWhitespace = lastChar == ' ' || lastChar == '\n';

			// Reserved symbols
			token = resSymbols[lastChar];
			bool isSymbol = token != 0 || lastChar == '\0';
			if(!isSymbol && !isWhitespace) {
				continue;
			}
			else if(length == 1) {
				if(isSymbol) {
					break;
				}
				cursor++;
				length--;
				continue;
			}
			length--;
			token = T.Ident;

			// Reserved keywords
			string buf = code[cursor..cursor+length];
			switch(buf) {
				enum minElement = Token.Module;
				static foreach(i0, keyword; resKeywords[minElement..$]) {
					case keyword: {
						token = cast(Token)(i0+minElement);
					} break loop;
				}
				default: break;
			}
			break;
		}
		cursor += length;
		current = token;
		return token;
	}
	string curString() {
		return code[cursor-length..cursor];
	}
}