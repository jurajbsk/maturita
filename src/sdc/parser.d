module sdc.parser;
import lib.memory;
import lib.func;
import sdc.lexer;

struct Stack {
	List!(AST*) buffer;
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
	AST* last() => buffer[$-1];
}

struct AST {
	Node node;
	AST* left;
	AST* right;
	this(S...)(S args)
	{
		node = Node(args);
	}
}

enum NodeType {
	File,
	FuncDef,
	Assign
}
struct Node {
	NodeType nodeType;
	string nodeValue;
}

List!AST parse(string code)
{
	Tokenizer tok = Tokenizer(code);
	List!AST buffer;
	buffer.add(AST(NodeType.File));
	Stack stack = Stack(&buffer[0]);

	loop: while(tok.next != Token.EOF) {
		AST* item = buffer.add;
		with(NodeType)
		switch(stack.last.node.nodeType)
		{
			default: {
			} break;
			case File: {
				switch(tok.current) {
					case TokType.Type: {
						if(!tok.expect(TokType.Ident)) {
							break loop;
						}
						item.node = Node(FuncDef, tok.value.identifier);
						tok.expect(TokType.LParen);
						tok.expect(TokType.RParen);
						tok.expect(TokType.LBrace);
						tok.expect(TokType.RBrace);
						stack.last.left = item;
					} break;
					default: break loop;
				}
			} break;
			//case EOF: break loop;
		}
	}
	return buffer;
}