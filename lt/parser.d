module lt.parser;

import std.stdio;
import std.conv;
import lt.tokeniser : Token;
import lt.ast;
import lt.parserdebug;

class Parser {
	private alias TT = Token.Type;
	private alias AT = ASTNode.NodeType;
	private Token[] tokens;
	private Token* next;

	ASTNode* Parse(Token[] _tokens){
		tokens = _tokens;

		return ParseProgram();
	}

private:
	void Error(string e){
		throw new Exception("parser: " ~ e);
	}

	void InternalError(string e){
		throw new Exception("parser internal: " ~ e);
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
			node = ParseStatementList();
		}

		Match(TT.EOF);

		return node;
	}

	// Statements ////////////////////////////////////////

	ASTNode* ParseStatementList(){
		auto __sd = ScopeDebug("ParseStatementList");

		if(Check(TT.EOF)) return null;

		ASTNode* node = null;

		auto first = ParseStatement();
		if(first){
			if(!Check(TT.EOF) && !Check(TT.RightBrace)){
				node = new ASTNode(AT.StatementList);
				node.list ~= first;

				do{
					node.list ~= ParseStatement();
				
				}while(!Check(TT.EOF) && !Check(TT.RightBrace));

			}else{
				node = first;
			}
		}

		return node;
	}

	ASTNode* ParseStatement(){
		auto __sd = ScopeDebug("ParseStatement");
		ASTNode* node = null;

		if(Check(TT.Identifier)){
			node = ParseDeclAssignOrFuncCall();

		}else if(Check(TT.Function)){
			node = ParseFuncDeclOrDef();

		}else if(Check(TT.Return)){
			node = ParseReturn();

		}else if(Check(TT.LeftBrace)){
			node = ParseBlock();

		}else{
			if(!Check(TT.RightBrace))
				Error("Statements cannot begin with " ~ to!string(next.type));
		}

		return node;
	}

	// Declarations and Assignments //////////////////////

	ASTNode* ParseDeclAssignOrFuncCall(){
		auto __sd = ScopeDebug("ParseDeclAssignOrFuncCall");
		auto id = ParseIdentifier();
		ASTNode* node = null;

		if(Check(TT.LeftParen)){
			node = ParseFuncCall(id);

		}else{
			auto type = ParseOptionalType();
			if(type) {
				node = new ASTNode(AT.Declaration);
				node.typeinfo = type.typeinfo;

				destroy(type);
				type = null;
			}

			auto assign = ParseOptionalAssign();
			if(assign){
				if(!node) node = new ASTNode(AT.Assignment);
				node.right = assign;

			}else if(!node){
				Error("An identifier at the beginning of a statement must form either a type or an assignment");
			}
		}

		node.left = id;

		Match(TT.SemiColon);
		return node;
	}

	ASTNode* ParseOptionalType(){
		auto __sd = ScopeDebug("ParseOptionalType");

		if(Check(TT.Type)){
			return ParseType();
		}

		return null;
	}

	ASTNode* ParseOptionalAssign(){
		auto __sd = ScopeDebug("ParseOptionalAssign");
		
		if(Check(TT.Assign)){
			return ParseAssignmentStub();
		}

		return null;
	}

	ASTNode* ParseAssignmentStub(){
		auto __sd = ScopeDebug("ParseAssignmentStub");

		Match(TT.Assign);
		return ParseExpression();
	}

	ASTNode* ParseBlock(){
		auto __sd = ScopeDebug("ParseBlock");
		ASTNode* node;

		Match(TT.LeftBrace);
		node = ParseStatementList();
		Match(TT.RightBrace);

		return node;
	}

	// Function calls ////////////////////////////////////

	ASTNode* ParseFuncCall(ASTNode* id){
		auto __sd = ScopeDebug("ParseFuncCall");
		auto node = new ASTNode(AT.FunctionCall);
		node.left = id;

		Match(TT.LeftParen);
		node.right = ParseArgumentList();
		Match(TT.RightParen);

		return node;
	}

	ASTNode* ParseArgumentList(){
		auto __sd = ScopeDebug("ParseArgumentList");

		if(!Check(TT.RightParen)){
			auto node = new ASTNode(AT.FunctionArgumentList);
			node.list ~= ParseNonTupleExpression();

			while(Check(TT.Comma)){
				Match(TT.Comma);
				node.list ~= ParseNonTupleExpression();
			}

			return node;
		}

		return null;
	}

	// Function Declarations and Definitions /////////////

	ASTNode* ParseFuncDeclOrDef(){
		auto __sd = ScopeDebug("ParseFuncDeclOrDef");
		Match(TT.Function);

		auto node = new ASTNode(AT.FunctionDeclaration);
		auto id = ParseIdentifier(); // Remove for lambdas?



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

		node = ParseTuple(node);

		return node;
	}

	ASTNode* ParseTuple(ASTNode* node){
		auto __sd = ScopeDebug("ParseExpressionR");

		if(Check(TT.Comma)){
			auto first = node;
			node = new ASTNode(AT.Tuple);
			node.list ~= first;

			do{
				Match(TT.Comma);
				node.list ~= ParseBinOpAddPrecedence();
				
			}while(Check(TT.Comma));
		}

		return node;
	}

	ASTNode* ParseNonTupleExpression(){
		return ParseBinOpAddPrecedence();
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

			if(Check(TT.Assign)){
				auto left = node;
				node = new ASTNode(AT.Assignment);
				node.left = left;
				node.right = ParseAssignmentStub();
			}

		}else if(Check(TT.String)){
			node = ParseString();
		}

		return node;
	}

	// Types /////////////////////////////////////////////

	ASTNode* ParseType(){
		auto __sd = ScopeDebug("ParseType");
		auto base = ParseBaseType();

		base = ParseTypeModifiers(base);

		return base;
	}

	ASTNode* ParseTypeModifiers(ASTNode* base){
		auto __sd = ScopeDebug("ParseTypeModifiers");

		if(Check(TT.Pointer)){
			Match(TT.Pointer);
			base.typeinfo.pointerLevel++;

			base = ParseTypeModifiers(base);
		}else if(Check(TT.LeftSquare)){
			Match(TT.LeftSquare);

			if(!Check(TT.RightSquare)){
				auto subscript = ParseExpression();
				destroy(subscript);
				// TODO: something here /////////////////////////
			}

			Match(TT.RightSquare);
		}

		return base;
	}
	
	ASTNode* ParseBaseType(){
		auto __sd = ScopeDebug("ParseBaseType");
		auto tok = Match(TT.Type);
		auto node = new ASTNode(AT.Type);
		node.typeinfo = new ASTTypeInfo;

		// TODO: actually do type stuff /////////////////////////

		return node;
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
		node.literalinfo = new ASTLiteralInfo;
		node.literalinfo.text = tok.text;

		return node;
	}
	
	ASTNode* ParseString(){
		auto __sd = ScopeDebug("ParseString");
		auto tok = Match(TT.String);
		auto node = new ASTNode(AT.String);
		node.literalinfo = new ASTLiteralInfo;
		node.literalinfo.text = tok.text[1..$-1];

		return node;
	}
}