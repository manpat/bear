module main;

import std.stdio, std.file;
import bear;

void main(){
	try{
		writeln("Language Test");

		auto tok = new Tokeniser();
		auto tokens = tok.Parse(cast(char[]) read("test.bear"));

		writeln("Tokenising done\n");
		foreach(ref t; tokens){
			writeln(t.type, "\t\t", t.text);
		}
		writeln("\n");

		auto parser = new Parser();
		auto ast = parser.Parse(tokens);

		writeln("Syntactic analysis done\n");
		writeln(ast.toString);
		stdout.flush();

		auto analyser = new Analyser();
		analyser.Analyse(ast);

	}catch(std.exception.Exception e){
		writeln("\n");
		writeln("error: ", e.msg);
	}
}