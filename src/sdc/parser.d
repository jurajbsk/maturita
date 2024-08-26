module sdc.parser;
import lib.memory;
import sdc.lexer;
import sdc.grammar;
import sdc.parsetable;

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

List!NonTerm parse(string code)
{
	List!NonTerm buffer;
	Tokenizer tok = Tokenizer(code);

	enum ParseTable _ptable = makePTable(NonTerm.File);
	ParseTable ptable = _ptable;
	List!p_size stack;
	stack.add(0);

	tok.next;
	loop: while(true) {
		Token token = tok.current;
		p_size state = stack[$-1];
		Action action = ptable.actionTable[state][token];

		bool nullShift;
		if(action.type == ActionType.Error) {
			Action nullAction = ptable.actionTable[state][TokType.Null];
			if(nullAction.type != ActionType.Error) {
				action = nullAction;
				nullShift = true;
			}
		}
		import lib.io;
		writeln(action);

		with(ActionType)
		final switch(action.type) {
			case Shift: {
				stack.add(action.state);
				if(!nullShift) {
					tok.next;
				}
			} break;

			case Reduce: {
				Prod prod = action.reduce;
				buffer.add(prod.nonTerm);
				stack.pop(prod.length);
				stack.add(ptable.gotoTable[stack[$-1]][prod.nonTerm]);
			} break;

			case Accept: {
				break loop;
			}

			case Error: {
				assert(0);
			}
		}
	}
	
	return buffer;
}