module main;

import std.stdio, std.file;
import lt;

void main(){
	try{
		writeln("Language Test");

		auto tok = new Tokeniser();
		auto tokens = tok.Parse(cast(char[]) read("test.lt"));

		writeln("Tokenising done\n");
		foreach(ref t; tokens){
			writeln(t.type, "\t\t", t.text);
		}
		writeln("\n");

		auto parser = new Parser();
		auto ast = parser.Parse(tokens);

		writeln("Syntactic analysis done\n");
		writeln(ast.toString);

	}catch(std.exception.Exception e){
		writeln(e);
	}
}