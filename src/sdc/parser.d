module sdc.parser;
import lib.memory;
import sdc.lexer;
import sdc.grammar;
import sdc.parsetable;

union NodeValue {
	ulong num;
	string text;
}
struct ASTNode {
	NonTerm nodeType;
	NodeValue value;
	p_size childrenIndex;
}

enum ParseTable _ptable = makePTable(NonTerm.File);
immutable ParseTable ptable = _ptable;

List!ASTNode parse(string code)
{
	List!ASTNode astBuffer;
	List!p_size stack;
	stack.add(0);

	Tokenizer tok = Tokenizer(code);
	tok.next;

	bool nullState;
	NodeValue value;
	loop: while(true)
	{
		Token token = tok.current;
		p_size state = stack[$-1];
		Action action = ptable.actionTable[state][token];

		version(ParserDEBUG) {
			import lib.io;
			writeln(action);
			writeln(cast(ulong)tok.current);
		}

		with(ActionType)
		actionSwitch: final switch(action.type) {
			case Shift: {
				stack.add(action.state);

				switch(tok.current) {
					default: break;

					case Token.Ident: {
						value.text = tok.curString;
					} break;
				}

				if(!nullState) {
					tok.next;
				}
			} break;

			case Reduce: {
				Prod prod = action.reduce;
				stack.pop(prod.length);
				stack.add(ptable.gotoTable[stack[$-1]][prod.nonTerm]);

				astBuffer.add(ASTNode(prod.nonTerm, value, prod.length));

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
	return astBuffer;
}