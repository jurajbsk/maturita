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
	ulong num;
	string str;
	struct {
		Token type;
		void* value;
	}
}

struct DataBuffer {
	ParseData[5] array;
	ubyte length;
	void add(ParseData data) {
		array[length] = data;
		length++;
	}
	ParseData pop() {
		length--;
		return array[length];
	}
}

void compile(char* code)
{
	Parser parser = Parser(code);
	DataBuffer dataStack;
	ubyte args;
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
					case T.Ident: {
						dataStack.add(ParseData(str: curStr));
					} break;
					case T.tVoid, T.i32, T.i64: {
						dataStack.add(ParseData(type: token));
					} break;
					case T.NumLiteral:
						import lib.string;
						StrNum num = strToNum(curStr);
						ParseData data;
						final switch(num.sign) {
							case 0: {
								if(num <= uint.max) {
									data.type = T.i32;
								}
								else {
									data.type = T.i64;
								}
							} break;
							case 1: {
								if(num <= byte.max) {

								}
							} break;
							case 2: assert(0, "Error: Number overflows - too large");
							case -1: assert(0, "Corrupt NumLiteral");
						}
						data.value = gen.toValue(num, data.type);
						dataStack.add(data);
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
				debug {
					import lib.io;
					writeln(parser.tokenizer.locs, ": ", prod.nonTerm);
				}

				switch(prod.nonTerm) {
					case n.Args, n.ArgsHead: {
						if(prod.length <= 1) {
							break;
						}
						string name = dataStack.pop().str;
						Token type = dataStack.pop().type;
						argBuffer.add(Variable(type, name));
						args++;
					} break;
					case n.Stmnt: {
						dataStack = DataBuffer();
					} break;
					case n.FuncHeader: {
						FuncHeader fh;
						fh.args = args;
						args = 0;
						fh.decl.ident = dataStack.pop().str;
						fh.decl.type = dataStack.pop().type;
						if(symTable.search(fh.decl.ident)) {
							assert(0, "Duplicate name");
						}

						Variable[] argList = argBuffer[$-fh.args..$];
						sem.lastFunc = fh;
						void* funcRef = gen.addFunc(fh.decl, argList);
						SymbolData symData = SymbolData(fh.decl.ident, funcRef, fh.decl.type, argList);
						symTable.add(symData);
					} break;
					case n.VarDecl: {
						Variable var;
						var.ident = dataStack.pop().str;
						var.type = dataStack.pop().type;
						dataStack.add(ParseData(str: var.ident));
						if(symTable.search(var.ident)) {
							assert(0, "Error: Declaration shadows previous symbol");
						}
						void* varRef = gen.addVar(var);
						SymbolData data = SymbolData(name: var.ident, valueRef: varRef, type: var.type);
						symTable.add(data);
					} break;
					case n.AssignStmnt: {
						ParseData data = dataStack.pop();
						string ident = dataStack.pop().str;

						SymbolData* var = symTable.search(ident);
						if(!var) {
							assert(0, "Error: undefined identifier");
						}
						gen.addAssign(data.value, var.valueRef);

					} break;
					case n.ReturnStmnt: {
						switch(prod.length) {
							case 1: {
								sem.checkRet(T.tVoid);
								gen.addRetVoid();
							} break;
							case 2: {
								ParseData data = dataStack.pop();
								sem.checkRet(data.type);
								gen.addRet(data.value);
							} break;
							default: assert(0);
						}
					} break;
					case n.Plus: {
						ParseData rExpr = dataStack.pop();
						ParseData lExpr = dataStack.pop();
						void* value = gen.addPlus(lExpr.value, rExpr.value);
						dataStack.add(ParseData(type: rExpr.type, value: value));
					} break;
					case n.Var: {
						string ident = dataStack.pop().str;
						SymbolData* var = symTable.search(ident);
						if(!var) {
							assert(0, "Error: undefined identifier");
						}
						void* value = gen.addLoad(var.valueRef, var.type);
						dataStack.add(ParseData(type: var.type, value: value));
					} break;
					case n.FuncDecl: {
						sem.lastFunc = FuncHeader();
					} break;
					default: break;
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
							continue;
						}
						write(i_tok, ' ');
					}
				}
				writeln("NOT: ", parser.curString);
				assert(0, "Parsing error");
			}

			case Accept: {
				gen.dumpObject("test.ll");
				break loop;
			}
		}
	}
}