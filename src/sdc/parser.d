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
	Typing type;
}

AST parse(string code)
{
	AST root;
	Tokenizer tok = {code};
	List!AST buffer;
	Stack stack = Stack(&root);
	loop: while(true) {
		with(Token) switch(tok.next)
		{
			case Type: {
				Typing type = tok.value.type;
				if(tok.expectNext(Identifier))
				{
					string ident = tok.value.identifier;
					// Function
					if(tok.next == (ParenOpen)) {
						tok.expectNext(ParenClose);
						if(tok.expectNext(ScopeStart)) {
							AST* func = buffer.add(AST(ExprType.FuncDecl, ident, type));
							stack.push(func);
						}
					}
					// Variable
					else if(tok.expectAny!([Operator, LineEnd])) {
						stack.push(buffer.add(AST(ExprType.VarDecl)));
					}
				}
			} break;

			case Identifier: {
				
			} break;

			case ScopeEnd: {
				stack.pop();
			} break;

			case Module: {
				if(tok.expectNext(Identifier)) {
					root.expr.exprValue = tok.current.value.identifier;
					tok.expectNext(LineEnd);
				}
			} break;

			case EOF: break loop;
			default: break;
		}
		//AST* nextItem = buffer.add;
		//stack[0].right = nextItem;
		//stack[0] = nextItem;
	}
	return root;
}