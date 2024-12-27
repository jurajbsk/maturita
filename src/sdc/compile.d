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

union ParseData {
	Variable var;
	FuncHeader func;
	struct {
		Variable _v;
		Expression expr;
	}
}

void compile(char* code)
{
	Parser parser = Parser(code);
	ParseData codeData;
	List!Variable argBuffer;

	SymbolTable symTable;
	CodeGen gen;
	gen.initialize();

	Semantic sem;

	loop: while(true) {
		Action action = parser.next();
		string curStr = parser.curString;
		Token token = parser.curToken;
		with(ActionType)
		final switch(action.type) {
			case Shift: {
				switch(token) {
					default: break;
					case T.Ident:
						codeData.var.ident = curStr;
					break;
					case T.tVoid, T.i32, T.i64:
						codeData.var.type = token;
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
						expr.value = gen.toValue(num, expr.type);
						codeData.expr = expr;
					break;
				}

				debug {
					import lib.io;
					//writeln(parser.tokenizer.locs, ": ", token);
				}

				parser.shift(action.state);
			} break;

			case Reduce: {
				Prod prod = action.reduce;
				parser.reduce(prod);

				switch(prod.nonTerm) {
					case n.Args, n.ArgsHead: {
						if(prod.length <= 1) {
							break;
						}
						Variable var = codeData.var;
						argBuffer.add(var);
						codeData.func.args++;
					} break;
					case n.FuncHeader: {
						FuncHeader fh;
						fh.decl = sem.lastFunc.decl;
						fh.args = codeData.func.args;
						if(symTable.search(fh.decl.ident)) {
							assert(0, "Duplicate name");
						}

						Variable[] args = argBuffer[$-fh.args..$];
						sem.lastFunc = fh;
						void* funcRef = gen.addFunc(fh.decl, args);
						SymbolData symData = SymbolData(fh.decl.ident, funcRef, fh.decl.type, args);
						symTable.add(symData);
					} break;
					case n.VarDecl: {
						Variable var = codeData.var;
						if(symTable.search(var.ident)) {
							assert(0, "Error: Declaration shadows previous symbol");
						}
						void* varRef = gen.addVar(var);
						SymbolData data = SymbolData(var.ident, varRef, var.type);
						symTable.add(data);
					} break;
					case n.AssignStmnt: {
						Expression expr = codeData.expr;
						string ident = codeData.var.ident;

						SymbolData* var = symTable.search(ident);
						if(!var) {
							assert(0, "Error: undefined identifier");
						}
						var.valueRef = gen.addAssign(expr.value, var.valueRef);

					} break;
					case n.ReturnStmnt: {
						switch(prod.length) {
							case 1: {
								sem.checkRet(T.tVoid);
								gen.addRetVoid();
							} break;
							case 2: {
								Expression expr = codeData.expr;
								sem.checkRet(expr.type);
								gen.addRet(expr.value);
							} break;
							default: assert(0);
						}
					} break;
					case n.Variable: {
						if(sem.lastFunc == FuncHeader()) {
							sem.lastFunc = codeData.func;
						}
					} break;
					case n.FuncDecl: {
						sem.lastFunc = FuncHeader();
						codeData = ParseData();
					} break;
					default: break;
				}

				debug {
					import lib.io;
					writeln(parser.tokenizer.locs, ": ", prod.nonTerm);
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