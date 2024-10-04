module sdc.parser;
import lib.memory;
import sdc.lexer;
import sdc.grammar;
import sdc.parsetable : ParseTable, makePTable, Action, ActionType, Prod;


union NodeValue {
	ulong num;
	string ident;
	TokType type;
	VarDecl varDecl;
	FuncHeader funcHeader;
}

struct ASTNode {
	NonTerm nodeType;
	NodeValue value;
}

enum ParseTable _ptable = makePTable(NonTerm.File);

List!ASTNode parse(string code)
{
	immutable ParseTable ptable = _ptable;
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

		debug {
			import lib.io;
			//writeln(token.type, " ", action);
		}

		with(ActionType)
		actionSwitch: final switch(action.type) {
			case Shift: {
				stack.add(action.state);

				switch(token.type) {
					default: value.type = token.type; break;
					case T.Ident: value.ident = tok.curString; break;
				}

				//if(!nullState) {
					tok.next;
				//}
			} break;

			case Reduce: {
				Prod prod = action.reduce;
				stack.pop(prod.length);
				stack.add(ptable.gotoTable[stack[$-1]][prod.nonTerm]);

				switch(prod.nonTerm) {
					case n.VarDecl: {
						TokType type = astBuffer[$-1].value.type;
						string ident = value.ident;
						astBuffer.pop(1);
						value.varDecl = VarDecl(type, ident);
					} break;
					// case n.Args: {
					// 	TokType type = astBuffer[$-2].value.type;
					// 	string ident = value.ident;
					// 	astBuffer.pop(2);
					// 	value.varDecl = VarDecl(type, ident);
					// } break;
					// case n.FuncHeader: {
						
					// 	VarDecl prefix = ;
					// 	TokType type = astBuffer[$-2].value.type;
					// 	string ident = value.ident;
					// 	astBuffer.pop(2);
					// 	value.varDecl = VarDecl(type, ident);
					// } break;
					default: break;
				}
				astBuffer.add(ASTNode(prod.nonTerm, value));
				value = NodeValue();
				
				debug {
					import lib.io;
					writeln(prod.nonTerm);
				}

				nullState = false;
			} break;

			case Error: {
				Action nullAction = ptable.actionTable[state][TokType.Null];
				if(nullAction.type != ActionType.Error) {
					action = nullAction;
					nullState = true;
					goto actionSwitch;
				}

				assert(0, "Error");
			}

			case Accept: {
				break loop;
			}
		}
	}
	return astBuffer;
}

pragma(msg, NodeValue.sizeof);