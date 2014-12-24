module lt.syntaxanalyser;

import std.stdio;
import std.conv;
import lt.tokeniser : Token;

//	expression ::= equality-expression
//	equality-expression ::= additive-expression ( ( '==' | '!=' ) additive-expression ) *
//	additive-expression ::= multiplicative-expression ( ( '+' | '-' ) multiplicative-expression ) *
//	multiplicative-expression ::= primary ( ( '*' | '/' ) primary ) *
//	primary ::= '(' expression ')' | NUMBER | VARIABLE | '-' primary

//	parse_expression_1 (lhs, min_precedence = 0)
//		lookahead := peek next token
//		while lookahead is a binary operator whose precedence is >= min_precedence
//			op := lookahead
//			advance to next token
//			rhs := parse_primary ()
//			lookahead := peek next token
//			while lookahead is a binary operator whose precedence is greater
//					 than op's, or a right-associative operator
//					 whose precedence is equal to op's
//				rhs := parse_expression_1 (rhs, lookahead's precedence)
//				lookahead := peek next token
//			lhs := the result of applying op with operands lhs and rhs
//		return lhs

struct TypeInfo {
	enum Primitive {
		Void,
		Integer,
		Float,
		Character,
		Function,
	}

	Primitive primitive;
	uint width;
	uint pointerLevel;
	bool unsigned;
}

struct ASTNode {
	enum Type {
		Invalid,
		Root,

		Statement,
		Expression,
		Assignment,
		Declaration,

		FunctionDeclaration,
		FunctionDefinition,
		FunctionCall,

		Block,

		Plus, Minus,
		Times, Divide,

		Deref, AddressOf,

		Identifier,
		Type,
		LiteralNumber,
		LiteralString,
	}

	this(Type _type){
		type = _type;
	}

	Type type;
	char[] name = null;
	ASTNode* left = null;
	ASTNode* right = null;

	TypeInfo* typeinfo = null;
	ASTNode*[] statements;

	string toString(){
		string s = "(" ~ to!string(type);

		if(name){
			s ~= " \"" ~ name ~ "\"";
		}

		if(statements.length != 0){
			s ~= " [";
			foreach(st; statements){
				s ~= "\n" ~ st.toString;
			}
			s ~= "\n]";
		}

		if(left){
			s ~= " " ~ left.toString;
		}
		if(right){
			s ~= " " ~ right.toString;
		}
		s ~= ")";

		return s;
	}
}

class SyntaxAnalyser {
	private alias TT = Token.Type;
	private alias AT = ASTNode.Type;
	private Token[] tokens;
	private ulong pos;
	private ulong prevpos = 0;
	private ulong recursionCount = 0;

	private Token* current;
	private Token* lookahead;

	ASTNode* Analyse(Token[] _tokens){
		tokens = _tokens;
		pos = 0;

		current = null;
		lookahead = &tokens[0];
		return ParseProgram();
	}

private:
	ASTNode* InvalidToken(){
		return new ASTNode(AT.Invalid);
	}

	void Error(string e){
		writeln("error: ", e);
	}

	void InternalError(string e){
		throw new Exception("internal error: ", e);
	}

	bool Check(Token.Type type){
		if(!lookahead) InternalError("Lookahead null");

		if(lookahead.type != type){
			return false;
		}

		return true;
	}

	bool Accept(Token.Type type){
		if(!Check(type)) return false;
		Advance();

		return true;
	}

	bool Expect(Token.Type type){
		if(!Accept(type)){
			Error("Expected " ~ to!string(type) 
				~ ", got " ~ to!string(lookahead.type));

			return false;
		}

		return true;
	}

	Token* Advance(){
		current = lookahead;
		return lookahead = &tokens[++pos];
	}

	ASTNode* ParseProgram(){
		auto node = new ASTNode();
		node.type = AT.Root;

		while(lookahead.type != TT.EOF){
			node.statements ~= ParseStatement();
			if(!Expect(TT.SemiColon)) break;
		}

		return node;
	}

	ASTNode* ParseStatement(){
		ASTNode* node = null;

		if(Accept(TT.Identifier)){
			if(Check(TT.Type)){
				auto decl = new ASTNode(AT.Declaration);
				decl.left = IdentifierNode(current.text);
				decl.right = ParseType();

				if(Accept(TT.Assign)){
					auto ass = new ASTNode(AT.Assignment);
					ass.left = decl;
					ass.right = ParseExpression();
					node = ass;
				}else{
					node = decl;
				}
			}else{
				auto ass = new ASTNode(AT.Assignment);
				ass.left = IdentifierNode(current.text);

				if(!Expect(TT.Assign)){
					return InvalidToken();
				}
				ass.right = ParseExpression();

				node = ass;
			}

		}else{
			node = InvalidToken();
		}

		return node;
	}

	ASTNode* ParseExpression(){
		ASTNode* node;

		if(Accept(TT.Deref)){
			node = new ASTNode(AT.Deref);
			node.left = ParseExpression();

		}else if(Accept(TT.Pointer)){
			node = new ASTNode(AT.AddressOf);
			node.left = ParseExpression();

		}else if(Accept(TT.LeftParen)){
			node = ParseExpression();
			Expect(TT.RightParen);

		}else if(Accept(TT.Identifier)){
			auto factor = IdentifierNode(current.text);
			if(CheckBinaryOperator()){
				node = ParseBinaryOp();
			}else{
				node = factor;
			}

		}else if(Accept(TT.Number)){
			auto factor = LiteralNumberNode(current.text);
			if(CheckBinaryOperator()){
				node = ParseBinaryOp();
			}else{
				node = factor;
			}

		}else if(Accept(TT.String)){
			auto factor = LiteralStringNode(current.text);

			node = factor;
		}

		return node;
	}

	ASTNode* ParseType(){
		if(!Expect(TT.Type)) return InvalidToken();

		auto node = new ASTNode(AT.Type);
		node.name = current.text;

		// Loop through and get pointer stuff

		return node;
	}

	ASTNode* ParseBinaryOp(){
		ASTNode* f1 = null;
		ASTNode* op = null;
		ASTNode* f2 = null;

		switch(current.type){
			case TT.Identifier:
				f1 = IdentifierNode(current.text);
				break;
			case TT.Number:
				f1 = LiteralNumberNode(current.text);
				break;
			case TT.String:
				f1 = LiteralStringNode(current.text);
				break;

			default:
				f1 = InvalidToken();
				Error("Expected something to do math to");
		}

		switch(lookahead.type){
			case TT.Plus:
				op = new ASTNode(AT.Plus);
				break;

			case TT.Minus:
				op = new ASTNode(AT.Minus);
				break;

			case TT.Star:
				op = new ASTNode(AT.Times);
				break;

			case TT.Divide:
				op = new ASTNode(AT.Divide);
				break;

			default:
				op = InvalidToken();
				Error("Expected a binary operator");
		}
		Advance();

		f2 = ParseExpression();
		op.left = f1;
		op.right = f2;

		return op;
	}

	ASTNode* IdentifierNode(char[] name){
		auto node = new ASTNode(AT.Identifier);
		node.name = name;
		return node;
	}

	ASTNode* LiteralNumberNode(char[] name){
		auto node = new ASTNode(AT.LiteralNumber);
		node.name = name;
		return node;
	}

	ASTNode* LiteralStringNode(char[] name){
		auto node = new ASTNode(AT.LiteralString);
		node.name = name[1..$-1];
		return node;
	}

	bool CheckBinaryOperator(){
		return Check(TT.Plus) || Check(TT.Minus) || Check(TT.Star) || Check(TT.Divide);
	}
}