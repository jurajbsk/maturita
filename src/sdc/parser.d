module sdc.parser;
import lib.memory;
import sdc.lexer : Tokenizer;
import sdc.grammar;
import sdc.parsetable : ParseTable, makePTable, Action, ActionType, Prod;
import sdc.codegen : CodeGen;

alias T = Token;
alias n = NonTerm;

enum ParseTable _ptable = makePTable(NonTerm.File);

void parse(string code)
{
	immutable ParseTable ptable = _ptable;

	List!ubyte dataStack;
	List!VarDecl argBuffer;
	CodeGen gen;
	gen.initialize();

	List!p_size stateStack;
	stateStack.add(0); // start state

	Tokenizer tok = Tokenizer(code);
	tok.next;

	ushort counter;
	loop: while(true)
	{
		Token token = tok.current;
		p_size state = stateStack[$-1];
		Action action = ptable.actionTable[state][token];

		with(ActionType)
		final switch(action.type) {
			case Shift: {
				stateStack.add(action.state);

				ubyte[] value;
				switch(token) {
					default: break;
					case T.Ident:
						string[1] curString = [tok.curString];
						value = cast(ubyte[])curString;
					break;
					case T.tVoid, T.i32, T.i64:
						value = cast(ubyte[])(&token)[0..1];
					break;
					case T.NumLiteral:
						import lib.string;
						ulong num = strToNum(tok.curString);
						value = cast(ubyte[])(&num)[0..1];
					break;
				}
				dataStack.add(value);
				tok.next;
			} break;

			case Reduce: {
				Prod prod = action.reduce;
				stateStack.pop(prod.length);
				stateStack.add(ptable.gotoTable[stateStack[$-1]][prod.nonTerm]);

				switch(prod.nonTerm) {
					case n.Args, n.ArgsHead:
					{
						if(prod.length < 2) {
							counter = 0;
							break;
						}
						VarDecl var = *cast(VarDecl*)&dataStack[$-VarDecl.sizeof];
						dataStack.pop(VarDecl.sizeof);
						argBuffer.add(var);
						ubyte args;
						if(counter) {
							args = dataStack.pop();
						}
						counter++;
						dataStack.add(cast(ubyte)(args+1));
					} break;
					case n.FuncHeader: {
						FuncHeader fh = *cast(FuncHeader*)&dataStack[$-FuncHeader.sizeof];
						dataStack.pop(FuncHeader.sizeof);
						VarDecl[] args = argBuffer[$-fh.args..$];
						import lib.io;
						writeln(fh.decl);
						gen.addFunc(fh.decl, args);
					} break;
					case n.ReturnStmnt: {
						switch(prod.length) {
							case 1: {
								gen.addRetVoid();
							} break;
							case 2: {
								ulong num = *cast(ulong*)&dataStack[$-ulong.sizeof];
								dataStack.pop(ulong.sizeof);
								gen.addRet(cast(uint)num);
							} break;
							default: assert(0);
						}
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
						case n.Args: {
							writeln(argBuffer._array);
						} break;
						case n.Expr: {
							writeln(*cast(ulong*)&dataStack[$-ulong.sizeof]);
						} break;
					}
					// writeln(prod.nonTerm, ' ', prod.length, ' ', argBuffer._array);
				}
			} break;

			case Error: {
				import lib.io;
				write("Expected: ");
				p_size[1] startState = [state];
				List!p_size stateList = startState;
				for(ubyte i; i < stateList.length; i++) {
					foreach(Token i_tok, Action ac; ptable.actionTable[stateList[i]])
					{
						if(ac.type == ActionType.Error) {
							continue;
						}
						if(ac.type == ActionType.Reduce) {
							//stateList.add(_ptable.gotoTable[state][ac.reduce.nonTerm]);
							//continue;
						}
						write(i_tok, ' ');
					}
				}
				writeln("NOT: ", tok.current);
				assert(0, "Parsing error");
			}

			case Accept: {
				gen.dumpIR("test.ll");
				break loop;
			}
		}
	}
}