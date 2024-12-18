module sdc.compile;
import lib.memory;
import sdc.grammar;
import sdc.parsetable : Action, ActionType, Prod;
import sdc.codegen : CodeGen;
import sdc.parser;

alias T = Token;
alias n = NonTerm;

void compile(char* code)
{
	List!ubyte dataStack;
	List!VarDecl argBuffer;
	Parser parser = Parser(code);
	CodeGen gen;
	gen.initialize();
	ushort argCounter;

	loop: while(true) {
		Action action = parser.next();
		string curStr = parser.curString;
		Token token = parser.curToken;
		with(ActionType)
		final switch(action.type) {
			case Shift: {
				ubyte[] value;
				switch(token) {
					default: break;
					case T.Ident:
						string[1] curString = [curStr];
						value = cast(ubyte[])curString;
					break;
					case T.tVoid, T.i32, T.i64:
						value = cast(ubyte[])(&token)[0..1];
					break;
					case T.NumLiteral:
						import lib.string;
						ulong num = strToNum(curStr);
						value = cast(ubyte[])(&num)[0..1];
					break;
				}
				dataStack.add(value);
				parser.shift(action.state);
			} break;

			case Reduce: {
				Prod prod = action.reduce;
				parser.reduce(prod);

				switch(prod.nonTerm) {
					case n.Args, n.ArgsHead:
					{
						if(prod.length <= 1) {
							argCounter = 0;
							break;
						}
						VarDecl var = *cast(VarDecl*)&dataStack[$-VarDecl.sizeof];
						dataStack.pop(VarDecl.sizeof);
						argBuffer.add(var);
						ubyte args;
						if(argCounter) {
							args = dataStack.pop();
						}
						argCounter++;
						dataStack.add(cast(ubyte)(args+1));
					} break;
					case n.FuncHeader: {
						import lib.io;
						if(dataStack.length < FuncHeader.sizeof) {
							dataStack.add(0);
						}
						FuncHeader fh = *cast(FuncHeader*)&dataStack[$-FuncHeader.sizeof];
						dataStack.pop(FuncHeader.sizeof);
						VarDecl[] args = argBuffer[$-fh.args..$];
						writeln(args.length);
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
				}
			} break;

			case Error: {
				import lib.io;
				write("Expected: ");
				p_size[1] startState = [action.state];
				List!p_size stateList = startState;
				for(ubyte i; i < stateList.length; i++) {
					foreach(Token i_tok, Action ac; parser.ptable.actionTable[stateList[i]])
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
				writeln("NOT: ", parser.curString);
				assert(0, "Parsing error");
			}

			case Accept: {
				gen.dumpIR("test.ll");
				break loop;
			}
		}
	}
}