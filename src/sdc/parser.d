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
	tok.next;

	enum ParseTable _ptable = makePTable(NonTerm.File);
	ParseTable ptable = _ptable;
	List!p_size stack;
	stack.add(0);

	bool nullState;
	loop: while(true) {
		Token token = tok.current;
		p_size state = stack[$-1];
		Action action = ptable.actionTable[state][token];

		version(ParserDEBUG) {
			import lib.io;
			writeln(action);
		}

		with(ActionType)
		actionSwitch: final switch(action.type) {
			case Shift: {
				stack.add(action.state);
				if(!nullState) {
					tok.next;
				}
			} break;

			case Reduce: {
				Prod prod = action.reduce;
				buffer.add(prod.nonTerm);
				stack.pop(prod.length);
				stack.add(ptable.gotoTable[stack[$-1]][prod.nonTerm]);

				nullState = false;
			} break;

			case Error: {
				Action nullAction = ptable.actionTable[state][TokType.Null];
				if(nullAction.type != ActionType.Error) {
					action = nullAction;
					nullState = true;
					goto actionSwitch;
				}

				assert(0);
			}

			case Accept: {
				break loop;
			}
		}
	}
	
	return buffer;
}