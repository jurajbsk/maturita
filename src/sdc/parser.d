module sdc.parser;
import lib.memory;
import sdc.lexer;
import sdc.grammar;
import sdc.parsetable : ParseTable, makePTable, Action, ActionType, Prod;


union NodeValue {
	ulong num;
	string ident;
	Token type;
	VarDecl varDecl;
	FuncHeader funcHeader;
	p_size args;
}

struct ASTNode {
	NonTerm nodeType;
	NodeValue value;
}

enum ParseTable _ptable = makePTable(NonTerm.File);

List!ASTNode parse(string code)
{
	immutable ParseTable ptable = _ptable;

	ASTNode[5] bufArr;
	List!ASTNode astBuffer = List!ASTNode(bufArr);
	List!VarDecl argBuffer;
	
	List!p_size stack;
	stack.add(0);

	Tokenizer tok = Tokenizer(code);
	tok.next;

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
		final switch(action.type) {
			case Shift: {
				stack.add(action.state);

				switch(token) {
					default: value.type = token; break;
					case T.Ident: value.ident = tok.curString; break;
				}

					tok.next;
			} break;

			case Reduce: {
				Prod prod = action.reduce;
				stack.pop(prod.length);
				stack.add(ptable.gotoTable[stack[$-1]][prod.nonTerm]);

				NodeValue prevValue = value;
				value = NodeValue();

				switch(prod.nonTerm) {
					case n.VarDecl: {
						Token type = astBuffer[$-1].value.type;
						string ident = prevValue.ident;
						astBuffer.pop(1);
						value.varDecl = VarDecl(type, ident);
					} break;
					case n.Args: {
						p_size prevArgs;
						bool prevIsArgs = astBuffer[$-1].nodeType == n.Args;
						if(astBuffer.length < 2+prevIsArgs) {
							break;
						}
						if(prevIsArgs) {
							if(astBuffer.length < 3) {
								break;
							}
							prevArgs = astBuffer.pop().value.args;
						}
						argBuffer.add(astBuffer.pop().value.varDecl);
						value.args = prevArgs+1;
					} break;
					case n.FuncHeader: {
						VarDecl decl = astBuffer[$-2].value.varDecl;
						Token type = decl.type;
						string ident = decl.ident;
						p_size args = astBuffer[$-1].value.args;
						astBuffer.pop(2);
						value.funcHeader = FuncHeader(type, ident, argBuffer[$-args..$]);
					} break;
					default: break;
				}
				astBuffer.add(ASTNode(prod.nonTerm, value));

				debug {
					import lib.io;
					write(prod.nonTerm, " ");//, value);
					// foreach(cur; astBuffer) {
					// 	write(cur.nodeType, ",");
					// }
					// writeln();
					// writeln(astBuffer._array);
				}
				value = NodeValue();
			} break;

			case Error: {
				assert(0, "Parsing error");
			}

			case Accept: {
				break loop;
			}
		}
	}
	return astBuffer;
}

pragma(msg, NodeValue.sizeof);