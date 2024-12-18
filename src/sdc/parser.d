module sdc.parser;
import lib.memory;
import sdc.lexer : Tokenizer;
import sdc.grammar;
import sdc.parsetable : ParseTable, makePTable, Action, Prod;

enum ParseTable _ptable = makePTable(NonTerm.File);

struct Parser {
	List!p_size stateStack;
	Tokenizer tokenizer;
	immutable ParseTable ptable = _ptable;

	string curString() => tokenizer.curString;
	Token curToken() => tokenizer.current;
	this(char* code)
	{
		stateStack.add(0); // start state
		tokenizer = Tokenizer(code);
		tokenizer.next;
	}
	Action next()
	{
		p_size state = stateStack[$-1];
		Action action = ptable.actionTable[state][curToken];
		return action;
	}
	void shift(p_size state)
	{
		stateStack.add(state);
		tokenizer.next;
	}
	void reduce(Prod prod)
	{
		stateStack.pop(prod.length);
		stateStack.add(ptable.gotoTable[stateStack[$-1]][prod.nonTerm]);
	}
}