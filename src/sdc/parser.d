module sdc.parser;
import lib.memory;
import lib.func;
import sdc.lexer;

struct Stack {
	List!(AST*) buffer;
	alias buffer this;
	uint counter;

	this(AST* start)
	{
		buffer.add(start);
	}
	void push(AST* element)
	{
		buffer.add(element);
		counter++;
	}
	AST* pop()
	{
		counter--;
		return buffer[counter];
	}
	AST* last() => buffer[counter-1];
}

struct AST {
	Expr expr;
	AST* left;
	AST* right;
	this(S...)(S args)
	{
		expr = Expr(args);
	}
}

enum ExprType {
	File,
	FuncDecl,
	VarDecl,
	Assign
}
struct Expr {
	ExprType exprType;
	string exprValue;
	LangType type;
}

immutable Token[] symTokTable = [

];
List!AST parse(string code)
{
	Tokenizer tok = Tokenizer(code);
	List!AST buffer = List!AST([AST(ExprType.File)]);
	Stack stack = Stack(&buffer[0]);

	loop: while(true) {
		with(Token) switch(tok.next)
		{
			default: {
			} break;

			case EOF: break loop;
		}
		//AST* nextItem = buffer.add;
		//stack[0].right = nextItem;
		//stack[0] = nextItem;
	}
	return buffer;
}