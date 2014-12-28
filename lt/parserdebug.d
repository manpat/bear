module lt.parserdebug;

import std.stdio;

struct ScopeDebug {
	static uint tablvl = 0;
	string name;

	this(string f){
		name = f;
		foreach(i; 0..tablvl){
			write("\t");
		}

		writeln(name ~ " {");

		tablvl++;
	}
	~this(){
		tablvl--;
		foreach(i; 0..tablvl){
			write("\t");
		}
		writeln("}");
	}

	static void Write(string thing){
		foreach(i; 0..tablvl){
			write("\t");
		}
		writeln(thing);
	}
}

mixin template FunctionStart(string name) {
	auto __sd = ScopeDebug(name);
}