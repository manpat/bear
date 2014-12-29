module bear.parserdebug;

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

		if(tablvl > 100) throw new Exception("I think there's been an infinite loop");
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