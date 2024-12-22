module sdc.compile;
import lib.memory;
import sdc.grammar;
import sdc.parsetable : Action, ActionType, Prod;
import sdc.parser;
import sdc.symtable;
import sdc.semantic;
import sdc.codegen : CodeGen;

alias T = Token;
alias n = NonTerm;

void compile(char* code)
{
	Parser parser = Parser(code);
	List!ubyte dataStack;
	List!Variable argBuffer;
	SymbolTable symTable;
	CodeGen gen;
	gen.initialize();

	Semantic semant;
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
						StrNum num = strToNum(curStr);
						Expression expr;
						final switch(num.sign) {
							case 0: {
								if(num <= uint.max) {
									expr.type = T.i32;
								}
								else {
									expr.type = T.i64;
								}
							} break;
							case 1: {
								if(num <= byte.max) {

								}
							} break;
							case 2: assert(0, "Error: Number overflows - too large");
							case -1: assert(0, "Corrupt NumLiteral");
						}
						value = cast(ubyte[])(&expr)[0..1];
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
						Variable var = *cast(Variable*)&dataStack[$-Variable.sizeof];
						dataStack.pop(Variable.sizeof);
						argBuffer.add(var);
						ubyte args;
						if(argCounter) {
							args = dataStack.pop();
						}
						argCounter++;
						dataStack.add(cast(ubyte)(args+1));
					} break;
					case n.FuncHeader:
					{
						if(dataStack.length < FuncHeader.sizeof) {
							dataStack.add(0);
						}
						FuncHeader fh = *cast(FuncHeader*)&dataStack[$-FuncHeader.sizeof];
						dataStack.pop(FuncHeader.sizeof);
						if(symTable.search(fh.decl.ident)) {
							assert(0, "Duplicate name");
						}

						Variable[] args = argBuffer[$-fh.args..$];
						semant.lastFunc = fh;
						SymbolData symData = SymbolData(fh.decl.ident, fh.decl.type, args);
						symTable.add(symData);
						gen.addFunc(fh.decl, args);
					} break;
					case n.VarDecl: {
						Variable var = *cast(Variable*)&dataStack[$-Variable.sizeof];
						dataStack.pop(Variable.sizeof);
						if(symTable.search(var.ident)) {
							assert(0, "Error: Declaration shadows previous symbol");
						}
						gen.addVar(var);
						SymbolData data = SymbolData(var.ident, var.type);
						symTable.add(data);
					} break;
					case n.ReturnStmnt:
					{
						switch(prod.length) {
							case 2: {
								semant.checkRet(T.tVoid);
								gen.addRetVoid();
							} break;
							case 3: {
								Expression expr = *cast(Expression*)&dataStack[$-Expression.sizeof];
								dataStack.pop(Expression.sizeof);
								semant.checkRet(expr.type);
								gen.addRet(cast(uint)expr.num);
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
						case n.Variable: {
							writeln(*cast(Variable*)&dataStack[$-Variable.sizeof]);
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
				write("Line ", parser.tokenizer.locs, ", Expected: ");
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