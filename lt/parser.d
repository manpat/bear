module lt.parser;

import std.stdio;
import std.conv;
import lt.tokeniser : Token;
import lt.ast;
import lt.parserdebug;

class Parser {
	private alias TT = Token.Type;
	private alias AT = ASTNode.Type;
	private Token[] tokens;
	private Token* next;

	ASTNode* Parse(Token[] _tokens){
		tokens = _tokens;

		return ParseProgram();
	}

private:
	void Error(string e){
		writeln("error: ", e);
	}

	void InternalError(string e){
		throw new Exception("internal error: ", e);
	}

	void ReadNext(){
		static ulong pos = 0;

		if(pos >= tokens.length) {
			next = null;
		}else{
			next = &tokens[pos++];
		}
	}

	Token* Match(TT type){
		if(!next){
			if(type != TT.EOF){
				throw new Exception("Unexpected EOF");
			}
		}else{
			if(next.type != type){
				throw new Exception("Expected " ~ to!string(type) ~ ", got " ~ to!string(next.type));
			}else{
				auto c = next;
				ReadNext();
				ScopeDebug.Write("matched " ~ to!string(c.type));

				return c;
			}
		}

		return null;
	}

	bool Check(TT type){
		if(!next){
			return type == TT.EOF; 
		}

		return next.type == type;
	}

	//////////////////////////////////////////////////////

	// Start /////////////////////////////////////////////

	ASTNode* ParseProgram(){
		auto __sd = ScopeDebug("ParseProgram");
		ReadNext();

		ASTNode* node = null;

		if(!Check(TT.EOF)){
			node = ParseExpression();
		}

		Match(TT.EOF);

		return node;
	}

	// Statements ////////////////////////////////////////

	ASTNode* ParseStatementList(){
		auto __sd = ScopeDebug("ParseStatementList");

		if(Check(TT.EOF)) return null;

		auto node = new ASTNode(AT.StatementList);
		node.left = ParseStatement();
		node.right = ParseStatementList();

		return node;
	}

	ASTNode* ParseStatement(){
		auto __sd = ScopeDebug("ParseStatement");

		return null;
	}

	// Declarations and Assignments //////////////////////

	ASTNode* ParseDeclOrAssign(){
		auto __sd = ScopeDebug("ParseDeclOrAssign");

		return null;
	}

	ASTNode* ParseOptionalType(){
		auto __sd = ScopeDebug("ParseOptionalType");

		return null;
	}

	ASTNode* ParseOptionalAssign(){
		auto __sd = ScopeDebug("ParseOptionalAssign");

		return null;
	}

	ASTNode* ParseAssignmentStub(){
		auto __sd = ScopeDebug("ParseAssignmentStub");

		return null;
	}

	ASTNode* ParseBlock(){
		auto __sd = ScopeDebug("ParseBlock");

		return null;
	}

	// Function calls ////////////////////////////////////

	ASTNode* ParseFuncCall(){
		auto __sd = ScopeDebug("ParseFuncCall");

		return null;
	}

	ASTNode* ParseArgumentList(){
		auto __sd = ScopeDebug("ParseArgumentList");

		return null;
	}

	// Function Declarations and Definitions /////////////

	ASTNode* ParseFuncDeclOrDef(){
		auto __sd = ScopeDebug("ParseFuncDeclOrDef");

		return null;
	}

	ASTNode* ParseFuncDecl(){
		auto __sd = ScopeDebug("ParseFuncDecl");

		return null;
	}

	ASTNode* ParseFuncDeclParam(){
		auto __sd = ScopeDebug("ParseFuncDeclParam");

		return null;
	}

	ASTNode* ParseFuncDeclType(){
		auto __sd = ScopeDebug("ParseFuncDeclType");

		return null;
	}

	ASTNode* ParseParameterList(){
		auto __sd = ScopeDebug("ParseParameterList");

		return null;
	}

	ASTNode* ParseParameter(){
		auto __sd = ScopeDebug("ParseParameter");

		return null;
	}

	ASTNode* ParseReturn(){
		auto __sd = ScopeDebug("ParseReturn");

		return null;
	}

	// Expressions ///////////////////////////////////////

	ASTNode* ParseExpression(){
		auto __sd = ScopeDebug("ParseExpression");
		auto node = ParseBinOpAddPrecedence();

		node = ParseExpressionR(node);

		return node;
	}

	ASTNode* ParseExpressionR(ASTNode* node){
		auto __sd = ScopeDebug("ParseExpressionR");

		if(Check(TT.Comma)){
			Match(TT.Comma);

			auto left = node;
			node = new ASTNode(AT.Tuple);
			node.left = left;
			node.right = ParseBinOpAddPrecedence();

			node = ParseExpressionR(node);
		}

		return node;
	}

	ASTNode* ParseBinOpAddPrecedence(){
		auto __sd = ScopeDebug("ParseBinOpAddPrecedence");
		auto node = ParseBinOpMulPrecedence();

		node = ParseBinOpAddPrecedenceR(node);

		return node;
	}

	ASTNode* ParseBinOpAddPrecedenceR(ASTNode* node){
		auto __sd = ScopeDebug("ParseBinOpAddPrecedenceR");

		if(Check(TT.Plus)){
			auto tok = Match(TT.Plus);
			auto op = new ASTNode(AT.Plus);
			op.left = node;
			node = op;
			node.right = ParseBinOpMulPrecedence();

			node = ParseBinOpAddPrecedenceR(node);

		}else if(Check(TT.Minus)){
			auto tok = Match(TT.Minus);
			auto op = new ASTNode(AT.Minus);
			op.left = node;
			node = op;
			node.right = ParseBinOpMulPrecedence();

			node = ParseBinOpAddPrecedenceR(node);
		}

		return node;
	}

	ASTNode* ParseBinOpMulPrecedence(){
		auto __sd = ScopeDebug("ParseBinOpMulPrecedence");
		auto node = ParseUnaryOp();

		node = ParseBinOpMulPrecedenceR(node);

		return node;
	}

	ASTNode* ParseBinOpMulPrecedenceR(ASTNode* node){
		auto __sd = ScopeDebug("ParseBinOpMulPrecedenceR");

		if(Check(TT.Star)){
			auto tok = Match(TT.Star);
			auto op = new ASTNode(AT.Times);
			op.left = node;
			node = op;
			node.right = ParseUnaryOp();

			node = ParseBinOpMulPrecedenceR(node);

		}else if(Check(TT.Divide)){
			auto tok = Match(TT.Divide);
			auto op = new ASTNode(AT.Divide);
			op.left = node;
			node = op;
			node.right = ParseUnaryOp();

			node = ParseBinOpMulPrecedenceR(node);
		}

		return node;
	}

	ASTNode* ParseUnaryOp(){
		auto __sd = ScopeDebug("ParseUnaryOp");

		if(Check(TT.Minus)){
			auto tok = Match(TT.Minus);
			auto op = new ASTNode(AT.Negate);
			op.left = ParseUnaryOp();
			return op;

		}else if(Check(TT.At)){
			auto tok = Match(TT.At);
			auto op = new ASTNode(AT.AddressOf);
			op.left = ParseUnaryOp();
			return op;
			
		}else if(Check(TT.Pointer)){
			auto tok = Match(TT.Pointer);
			auto op = new ASTNode(AT.Deref);
			op.left = ParseUnaryOp();
			return op;
			
		}else if(Check(TT.Not)){
			auto tok = Match(TT.Not);
			auto op = new ASTNode(AT.Not);
			op.left = ParseUnaryOp();
			return op;
		}

		return ParseExpressionTerm();
	}

	ASTNode* ParseExpressionTerm(){
		auto __sd = ScopeDebug("ParseExpressionTerm");
		ASTNode* node = null;

		if(Check(TT.LeftParen)){
			Match(TT.LeftParen);
			node = ParseExpression();
			Match(TT.RightParen);

		}else if(Check(TT.Number)){
			node = ParseNumber();

		}else if(Check(TT.Identifier)){
			node = ParseIdentifier();

		}else if(Check(TT.String)){
			node = ParseString();
		}

		return node;
	}

	// Types /////////////////////////////////////////////

	ASTNode* ParseType(){
		auto __sd = ScopeDebug("ParseType");

		return null;
	}

	ASTNode* ParseTypeModifiers(){
		auto __sd = ScopeDebug("ParseTypeModifiers");

		return null;
	}
	
	ASTNode* ParseBaseType(){
		auto __sd = ScopeDebug("ParseBaseType");

		return null;
	}

	// Terminals /////////////////////////////////////////

	ASTNode* ParseIdentifier(){
		auto __sd = ScopeDebug("ParseIdentifier");
		auto tok = Match(TT.Identifier);
		auto node = new ASTNode(AT.Identifier);
		node.name = tok.text;

		return node;
	}
	
	ASTNode* ParseNumber(){
		auto __sd = ScopeDebug("ParseNumber");
		auto tok = Match(TT.Number);
		auto node = new ASTNode(AT.Number);
		node.literalinfo = new LiteralInfo;
		node.literalinfo.text = tok.text;

		return node;
	}
	
	ASTNode* ParseString(){
		auto __sd = ScopeDebug("ParseString");
		auto tok = Match(TT.String);
		auto node = new ASTNode(AT.String);
		node.literalinfo = new LiteralInfo;
		node.literalinfo.text = tok.text[1..$-1];

		return node;
	}
}