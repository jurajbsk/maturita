module sdc.parser;
import lib.memory;
import sdc.lexer : Tokenizer;
import sdc.grammar;
import sdc.parsetable : ParseTable, makePTable, Action, ActionType, Prod;

alias T = Token;
alias n = NonTerm;

enum ParseTable _ptable = makePTable(NonTerm.File);

void parse(string code)
{
	immutable ParseTable ptable = _ptable;

	List!ubyte dataStack;
	List!VarDecl argBuffer;
	
	List!p_size stack;
	stack.add(0); // start state

	Tokenizer tok = Tokenizer(code);
	tok.next;

	loop: while(true)
	{
		Token token = tok.current;
		p_size state = stack[$-1];
		Action action = ptable.actionTable[state][token];
		ushort counter;

		with(ActionType)
		final switch(action.type) {
			case Shift: {
				stack.add(action.state);

				ubyte[] value;
				switch(token) {
					default: break;
					case T.tVoid, T.i32, T.i64:
						value = cast(ubyte[])(&token)[0..1];
					break;
					case T.Ident:
						string curString = tok.curString;
						value = cast(ubyte[])(&curString)[0..1];
					break;
				}
				dataStack.add(value);
				tok.next;
			} break;

			case Reduce: {
				Prod prod = action.reduce;
				stack.pop(prod.length);
				stack.add(ptable.gotoTable[stack[$-1]][prod.nonTerm]);

				switch(prod.nonTerm) {
					case n.Args, n.ArgsHead: {
						if(prod.length < 2) {
							counter = 0;
							break;
						}
						VarDecl var = *cast(VarDecl*)&dataStack[$-VarDecl.sizeof];
						argBuffer.add(var);
						dataStack.pop(VarDecl.sizeof);
						ubyte args;
						if(counter) {
							args = dataStack.pop();
						}
						counter++;
						dataStack.add(cast(ubyte)(args+1));
					} break;
					default: break;
				}

				debug {
					import lib.io;
					switch(prod.nonTerm) {
						default: break;
						case n.Type: {
							writeln(*cast(Token*)&dataStack[$-Token.sizeof]);
						} break;
						case n.VarDecl: {
							writeln(*cast(VarDecl*)&dataStack[$-VarDecl.sizeof]);
						} break;
					}
				}
			} break;

			case Error: {
				assert(0, "Parsing error");
			}

			case Accept: {
				break loop;
			}
		}
	}
}