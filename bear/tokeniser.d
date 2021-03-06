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

		// Comparison ops
		Equals, NEquals,
		LEquals, GEquals,
		LessThan, GreaterThan,

		Plus, Minus,
		Star, Divide,

		Increment, Decrement,

		Not,
		Assign,

		If, Else,
		For, While,
		Do, 

		Break, Continue,

		Foreach, In, // Ver 2

		TypeDecl, Struct,
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
			(?P<SemiColon>;)				|
			(?P<String>".*?(?<!\\)")		|

			(?P<LeftParen>\()				|
			(?P<RightParen>\))				|

			(?P<LeftBrace>\{)				|
			(?P<RightBrace>\})				|

			(?P<LeftSquare>\[)				|
			(?P<RightSquare>\])				|

			(?P<Equals>==)					|
			(?P<NEquals>!=)					|
			(?P<LEquals><=)					|
			(?P<GEquals>>=)					|

			(?P<Function>\bfunc\b)			|
			(?P<Returns>->)					|
			(?P<Return>\breturn\b)			|
			(?P<Pointer>\^)					|
			(?P<At>@)						|
			(?P<Assign>=)					|

			(?P<Increment>\+\+)				|
			(?P<Decrement>--)				|
			(?P<Plus>\+)					|
			(?P<Minus>-)					|
			(?P<Star>\*)					|
			(?P<Divide>/)					|
			(?P<Not>!)						|
			(?P<LessThan><)					|
			(?P<GreaterThan>>)				|

			(?P<If>\bif\b)					|
			(?P<Else>\belse\b)				|

			(?P<For>\bfor\b)				|
			(?P<While>\bwhile\b)			|
			(?P<Do>\bdo\b)					|
			(?P<In>\bin\b)					|
			(?P<Foreach>\bforeach\b)		|

			(?P<Break>\bbreak\b)			|
			(?P<Continue>\bcontinue\b)		|

			(?P<Type>
				\b(?:void|u?short|u?int|
					u?long|float|double|
					extended|
					u?char|string|
					bool))\b				|

			(?P<LanguageConstant>
				\b(?:true|false|null)\b)	|

			(?P<TypeDecl>\btype\b)				|
			(?P<Struct>\bstruct\b)			|

			(?P<Comma>,)					|

			(?P<Identifier>[a-zA-Z_]\w*)	|
			(?P<Number>[0-9][0-9_]*
				(?:\.[0-9][0-9_]*)?)		|

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

			}else if(m["Increment"].length != 0){
				tok.type = Token.Type.Increment;
			}else if(m["Decrement"].length != 0){
				tok.type = Token.Type.Decrement;

			}else if(m["LessThan"].length != 0){
				tok.type = Token.Type.LessThan;
			}else if(m["GreaterThan"].length != 0){
				tok.type = Token.Type.GreaterThan;

			}else if(m["Equals"].length != 0){
				tok.type = Token.Type.Equals;
			}else if(m["NEquals"].length != 0){
				tok.type = Token.Type.NEquals;
			}else if(m["LEquals"].length != 0){
				tok.type = Token.Type.LEquals;
			}else if(m["GEquals"].length != 0){
				tok.type = Token.Type.GEquals;

			}else if(m["Comma"].length != 0){
				tok.type = Token.Type.Comma;

			}else if(m["If"].length != 0){
				tok.type = Token.Type.If;
			}else if(m["Else"].length != 0){
				tok.type = Token.Type.Else;

			}else if(m["For"].length != 0){
				tok.type = Token.Type.For;
			}else if(m["While"].length != 0){
				tok.type = Token.Type.While;
			}else if(m["Do"].length != 0){
				tok.type = Token.Type.Do;
				
			}else if(m["Foreach"].length != 0){
				tok.type = Token.Type.Foreach;
			}else if(m["In"].length != 0){
				tok.type = Token.Type.In;
			
			}else if(m["Break"].length != 0){
				tok.type = Token.Type.Break;
			}else if(m["Continue"].length != 0){
				tok.type = Token.Type.Continue;
			
			}else if(m["TypeDecl"].length != 0){
				tok.type = Token.Type.TypeDecl;
			}else if(m["Struct"].length != 0){
				tok.type = Token.Type.Struct;


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