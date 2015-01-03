module bear.tokeniser;

import std.string;
import std.regex;
import std.stdio;

struct Token {
	enum Type {
		Unknown,
		EOF,
		Comment, // discarded immediately

		LanguageConstant,
		Identifier,
		String,
		Number,

		SemiColon,
		LeftParen,
		RightParen,
		LeftBrace,
		RightBrace,
		LeftSquare,
		RightSquare,

		Type,

		Pointer,
		At,
		Returns,
		Function,
		Return,
		Comma,

		Plus, Minus,
		Star, Divide,

		Not,
		Assign,

		If, Else,
		For, 
		In, // Ver 2
	}
	
	Type type;
	char[] text;

	DebugInfo* debuginfo;
	// filename, line number, pre analysis line
}

class Tokeniser {
	private char[] data;
	private ulong pos;

	static private {
		auto tokenRegex = ctRegex!(`
			(?P<Comment>(?://[^\n]*|
				/\*.*\*/))					|
			(?P<SemiColon>(?:;)+)			|
			(?P<String>".*?(?<!\\)")		|

			(?P<LeftParen>\()				|
			(?P<RightParen>\))				|

			(?P<LeftBrace>\{)				|
			(?P<RightBrace>\})				|

			(?P<LeftSquare>\[)				|
			(?P<RightSquare>\])				|

			(?P<Function>\bfunc\b)			|
			(?P<Returns>->)					|
			(?P<Return>\breturn\b)			|
			(?P<Pointer>\^)					|
			(?P<At>@)						|
			(?P<Assign>=)					|

			(?P<Plus>\+)					|
			(?P<Minus>-)					|
			(?P<Star>\*)					|
			(?P<Divide>/)					|
			(?P<Not>!)						|

			(?P<If>if)						|
			(?P<Else>else)					|
			(?P<For>for)					|
			(?P<In>in)						|

			(?P<Type>
				void|u?short|u?int|u?long|
				float|double|u?char|
				string|bool)				|
			(?P<LanguageConstant>
				true|false|null)			|

			(?P<Comma>,)					|

			(?P<Identifier>[a-zA-Z_]\w*)	|
			(?P<Number>[0-9][0-9_]*)		|

			(?P<SomethingElse>.)
			`, "xsm");

		auto startingWhitespaceRegex = ctRegex!(`^\s*`);
	}

	auto Parse(char[] _data){
		data = _data;
		pos = 0;
		ulong prevpos = 0;
		Token[] tokens;

		int i = 0;
		while(!IsEOF()){
			EatWhiteSpace();
			char[] text;

			auto tok = ParseToken();
 
 			if(tok.type != Token.Type.Comment)
				tokens ~= tok;

			if(prevpos == pos){
				i++;
				if(i == 20) {
					writeln("Infinite loop in tokeniser");
					break;
				}
			}

			prevpos = pos;
		}

		tokens ~= Token(Token.Type.EOF, cast(char[])"EOF");

		return tokens;
	}

private:
	// Returns false if eof
	bool Advance(ulong amt = 1){
		pos += amt;
		return pos < data.length;
	}

	bool IsEOF(){
		return pos >= data.length;
	}

	char[] Data(){
		return data[pos..$];
	}

	void Error(string msg){
		throw new Exception("error: " ~ msg);
	}

	bool EatWhiteSpace(){
		auto cs = matchFirst(Data(), startingWhitespaceRegex);
		if(cs){
			Advance(cs.front.length);
			return true;
		}

		return false;
	}

	Token ParseToken(){
		Token tok;
		auto m = matchFirst(Data(), tokenRegex);

		if(m){
			tok.type = Token.Type.Unknown;
			tok.text = m.front;

			auto di = new DebugInfo;
			di.fileName = "<filename>"; // TODO: Actually get file name
			di.lineNumber = 123; // TODO: Actually get line number
			di.tokenText = tok.text;
			tok.debuginfo = di;

			if(m["Comment"].length != 0){
				tok.type = Token.Type.Comment;

			}else if(m["Identifier"].length != 0){
				tok.type = Token.Type.Identifier;
			}else if(m["LanguageConstant"].length != 0){
				tok.type = Token.Type.LanguageConstant;
			}else if(m["Number"].length != 0){
				tok.type = Token.Type.Number;
			}else if(m["String"].length != 0){
				tok.type = Token.Type.String;

			}else if(m["SemiColon"].length != 0){
				tok.type = Token.Type.SemiColon;

			}else if(m["LeftBrace"].length != 0){
				tok.type = Token.Type.LeftBrace;
			}else if(m["RightBrace"].length != 0){
				tok.type = Token.Type.RightBrace;
			}else if(m["LeftParen"].length != 0){
				tok.type = Token.Type.LeftParen;
			}else if(m["RightParen"].length != 0){
				tok.type = Token.Type.RightParen;
			}else if(m["LeftSquare"].length != 0){
				tok.type = Token.Type.LeftSquare;
			}else if(m["RightSquare"].length != 0){
				tok.type = Token.Type.RightSquare;

			}else if(m["Type"].length != 0){
				tok.type = Token.Type.Type;

			}else if(m["Function"].length != 0){
				tok.type = Token.Type.Function;
			}else if(m["Returns"].length != 0){
				tok.type = Token.Type.Returns;
			}else if(m["Return"].length != 0){
				tok.type = Token.Type.Return;
			}else if(m["Pointer"].length != 0){
				tok.type = Token.Type.Pointer;
			}else if(m["At"].length != 0){
				tok.type = Token.Type.At;

			}else if(m["Assign"].length != 0){
				tok.type = Token.Type.Assign;
			}else if(m["Not"].length != 0){
				tok.type = Token.Type.Not;

			}else if(m["Plus"].length != 0){
				tok.type = Token.Type.Plus;
			}else if(m["Minus"].length != 0){
				tok.type = Token.Type.Minus;
			}else if(m["Star"].length != 0){
				tok.type = Token.Type.Star;
			}else if(m["Divide"].length != 0){
				tok.type = Token.Type.Divide;

			}else if(m["Comma"].length != 0){
				tok.type = Token.Type.Comma;


			}else if(m["If"].length != 0){
				tok.type = Token.Type.If;
			}else if(m["Else"].length != 0){
				tok.type = Token.Type.Else;
			}else if(m["For"].length != 0){
				tok.type = Token.Type.For;
			}else if(m["In"].length != 0){
				tok.type = Token.Type.In;


			}else if(m["SomethingElse"].length != 0){
				tok.type = Token.Type.Unknown;
				Error(cast(immutable (char[])) ("Unknown token " ~ tok.text));
			}

			Advance(m.front.length);
		}else{
			tok.type = Token.Type.Unknown;
			Error("Unable to tokenise");
		}

		return tok;
	}
}

struct DebugInfo {
	string fileName;
	ulong lineNumber;
	char[] tokenText;
}