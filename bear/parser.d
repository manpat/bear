module bear.parser;

import std.stdio;
import std.conv;
import bear.tokeniser : Token;
import bear.ast;
import bear.parserdebug;

class Parser {
	private alias TT = Token.Type;
	private alias AT = ASTNode.NodeType;
	private Token[] tokens;
	private Token* next;
	private Token* matched;

	ASTNode* Parse(Token[] _tokens){
		tokens = _tokens;

		return ParseProgram();
	}

private:
	void Error(ST)(ST e){
		throw new Exception("parser: " ~ to!string(e));
	}

	void InternalError(ST)(ST e){
		throw new Exception("parser internal: " ~ to!string(e));
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
				Error("Unexpected EOF");
			}
		}else{
			if(next.type != type){
				Error("Expected " ~ to!string(type) ~ ", got " ~ to!string(next.type));
			}else{
				matched = next;
				ReadNext();
				ScopeDebug.Write("matched " ~ to!string(matched.type));

				return matched;
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

	Token* Accept(TT type){
		if(Check(type)){
			return Match(type); 
		}

		return null;
	}

	//////////////////////////////////////////////////////

	// Start /////////////////////////////////////////////

	ASTNode* ParseProgram(){
		auto __sd = ScopeDebug("ParseProgram");
		ASTNode* node = null;
		ReadNext();

		if(!Check(TT.EOF)){
			node = ParseStatementList();
		}

		Match(TT.EOF);

		return node;
	}

	// Statements ////////////////////////////////////////

	ASTNode* ParseStatementList(){
		auto __sd = ScopeDebug("ParseStatementList");
		ASTNode* node = null;

		while(Accept(TT.SemiColon)) {}
		if(Check(TT.EOF) || Check(TT.RightBrace)) return null;

		auto first = ParseStatement();
		if(matched.type != TT.RightBrace) Match(TT.SemiColon);

		if(first){
			if(!Check(TT.EOF) && !Check(TT.RightBrace)){
				node = new ASTNode(AT.StatementList);
				node.list ~= first;

				do{
					if(!Accept(TT.SemiColon)){
						node.list ~= ParseStatement();
						if(matched.type != TT.RightBrace) 
							Match(TT.SemiColon);
					}
				
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
			node = ParseIdentifierStatement();

		}else if(Check(TT.Function)){
			node = ParseFuncDeclOrDef();

		}else if(Check(TT.Return)){
			node = ParseReturn();

		}else if(Check(TT.LeftBrace)){
			node = ParseBlock();

		}else if(Check(TT.If)){
			node = ParseConditionalStatement();

		}else if(Check(TT.For) || Check(TT.While)
			|| Check(TT.Do) || Check(TT.Foreach)){ // foreach is v2
			node = ParseLoop();

		}else if(Check(TT.Break)){
			node = ParseBreak();

		}else if(Check(TT.Continue)){
			node = ParseContinue();

		}else if(Check(TT.TypeDecl)){
			node = ParseTypeDeclaration();

		}else{
			if(!Check(TT.RightBrace))
				Error("Statements cannot begin with " ~ to!string(next.type));
		}

		return node;
	}

	// Declarations and Assignments //////////////////////

	ASTNode* ParseIdentifierStatement(){
		auto __sd = ScopeDebug("ParseIdentifierStatement");
		auto id = ParseIdentifier();
		ASTNode* node = null;

		if(Check(TT.LeftParen)){
			node = ParseFuncCall(id);

		}else if(Check(TT.LeftSquare)){
			node = new ASTNode(AT.Assignment);
			node.left = ParseArraySubscript(id);
			node.right = ParseAssignmentStub();

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
			}

			if(!node){
				Error("An identifier at the beginning of a statement must form either a type or an assignment");
			}

			node.left = id;
		}

		return node;
	}

	ASTNode* ParseOptionalType(){
		auto __sd = ScopeDebug("ParseOptionalType");

		if(Check(TT.Type) || Check(TT.Identifier)){
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

		Match(TT.LeftBrace);
		auto node = ParseStatementList();
		Match(TT.RightBrace);

		return node;
	}

	ASTNode* ParseDeclaration(){
		auto __sd = ScopeDebug("ParseDeclaration");

		auto id = ParseIdentifier();
		auto type = ParseType();
		auto assign = ParseOptionalAssign();

		auto node = new ASTNode(AT.Declaration);
		node.typeinfo = type.typeinfo;
		node.left = id;
		node.right = assign;

		return node;
	}

	ASTNode* ParseDeclarationList(){
		auto __sd = ScopeDebug("ParseDeclarationList");
		auto node = new ASTNode(AT.StatementList);

		while(!Check(TT.EOF) && !Check(TT.RightBrace)){
			while(Accept(TT.SemiColon)) {}; // Ignore semicolons

			node.list ~= ParseDeclaration();
			if(matched.type != TT.RightBrace) Match(TT.SemiColon);
		}

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
			node.list ~= ParseNonSequenceExpression();

			while(Accept(TT.Comma)){
				node.list ~= ParseNonSequenceExpression();
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
		auto typeinfo = new ASTTypeInfo(ASTPrimitiveType.Function);

		node.left = ParseIdentifier(); // Remove for lambdas?

		typeinfo.functionType.parameterList = ParseFuncDeclParam();

		auto returnType = ParseFuncDeclType();
		if(returnType)
			typeinfo.functionType.returnType = returnType.typeinfo;

		if(Check(TT.LeftBrace)){
			node.type = AT.FunctionDefinition;
			node.right = ParseBlock();
		}

		node.typeinfo = typeinfo;

		return node;
	}

	ASTNode* ParseFuncDeclParam(){
		auto __sd = ScopeDebug("ParseFuncDeclParam");
		ASTNode* node = null;

		if(Accept(TT.LeftParen)){
			node = ParseParameterList();
			Match(TT.RightParen);
		}

		return node;
	}

	ASTNode* ParseFuncDeclType(){
		auto __sd = ScopeDebug("ParseFuncDeclType");

		if(Accept(TT.Returns)){
			return ParseType();
		}

		return null;
	}

	ASTNode* ParseParameterList(){
		auto __sd = ScopeDebug("ParseParameterList");

		if(Check(TT.Identifier)){
			auto first = ParseParameter();

			if(Check(TT.Comma) && first){
				auto plist = new ASTNode(AT.FunctionParameterList);
				plist.list ~= first;

				do{
					Match(TT.Comma);
					plist.list ~= ParseParameter();

				} while(Check(TT.Comma));

				return plist;
			}

			return first;
		}

		return null;
	}

	ASTNode* ParseParameter(){
		auto __sd = ScopeDebug("ParseParameter");
		auto param = new ASTNode(AT.FunctionParameter);

		if(Check(TT.Identifier)){
			param.left = ParseIdentifier();
		}

		param.typeinfo = ParseType().typeinfo;

		return param;
	}

	ASTNode* ParseReturn(){
		auto __sd = ScopeDebug("ParseReturn");

		Match(TT.Return);
		auto node = new ASTNode(AT.ReturnStatement);
		node.left = ParseExpression();

		return node;
	}

	// Expressions ///////////////////////////////////////

	ASTNode* ParseExpression(){
		auto __sd = ScopeDebug("ParseExpression");
		auto node = ParseNonSequenceExpression();

		node = ParseSequence(node);

		return node;
	}

	ASTNode* ParseSequence(ASTNode* node){
		auto __sd = ScopeDebug("ParseExpressionR");

		if(Check(TT.Comma)){
			auto first = node;
			node = new ASTNode(AT.Sequence);
			node.list ~= first;

			do{
				Match(TT.Comma);
				node.list ~= ParseNonSequenceExpression();
				
			}while(Check(TT.Comma));
		}

		return node;
	}

	// Just for convenience
	alias ParseNonSequenceExpression = ParseComparisonOpPrecedence;

	ASTNode* ParseComparisonOpPrecedence(){
		auto __sd = ScopeDebug("ParseComparisonOpPrecedence");
		auto node = ParseBinOpAddPrecedence();

		node = ParseComparisonOpPrecedenceR(node);

		return node;
	}

	ASTNode* ParseComparisonOpPrecedenceR(ASTNode* node){
		auto __sd = ScopeDebug("ParseComparisonOpPrecedenceR");
		ASTNode* op = null;

		if(Accept(TT.Equals)){
			op = new ASTNode(AT.Equals);

		}else if(Accept(TT.NEquals)){
			op = new ASTNode(AT.NEquals);

		}else if(Accept(TT.LEquals)){
			op = new ASTNode(AT.LEquals);

		}else if(Accept(TT.GEquals)){
			op = new ASTNode(AT.GEquals);

		}else if(Accept(TT.LessThan)){
			op = new ASTNode(AT.LessThan);

		}else if(Accept(TT.GreaterThan)){
			op = new ASTNode(AT.GreaterThan);
		}

		if(op){
			op.left = node;
			op.right = ParseBinOpAddPrecedence();
			node = op;

			// Non associative so no recurse
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
		ASTNode* op = null;

		if(Accept(TT.Plus)){
			op = new ASTNode(AT.Plus);

		}else if(Accept(TT.Minus)){
			op = new ASTNode(AT.Minus);
		}

		if(op){
			op.left = node;
			op.right = ParseBinOpMulPrecedence();
			node = op;

			// Left associative so recurse
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
		ASTNode* op = null;

		if(Accept(TT.Star)){
			op = new ASTNode(AT.Times);

		}else if(Accept(TT.Divide)){
			op = new ASTNode(AT.Divide);
		}

		if(op){
			op.left = node;
			node = op;
			node.right = ParseUnaryOp();

			// Left associative so recurse
			node = ParseBinOpMulPrecedenceR(node);
		}

		return node;
	}

	ASTNode* ParseUnaryOp(){
		auto __sd = ScopeDebug("ParseUnaryOp");
		ASTNode* op = null;

		if(Accept(TT.Minus)){
			op = new ASTNode(AT.Negate);

		}else if(Accept(TT.At)){
			op = new ASTNode(AT.AddressOf);
			
		}else if(Accept(TT.Pointer)){
			op = new ASTNode(AT.Deref);
			
		}else if(Accept(TT.Not)){
			op = new ASTNode(AT.Not);

		}else if(Accept(TT.Increment)){
			op = new ASTNode(AT.PreIncrement);

		}else if(Accept(TT.Decrement)){
			op = new ASTNode(AT.PreDecrement);
		}

		if(op){
			op.left = ParseUnaryOp();
			return op;
		}

		return ParseExpressionTerm();
	}

	ASTNode* ParseExpressionTerm(){
		auto __sd = ScopeDebug("ParseExpressionTerm");
		ASTNode* node = null;

		if(Accept(TT.LeftParen)){
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
			}else if(Check(TT.LeftSquare)){
				node = ParseArraySubscript(node);
			}

		}else if(Check(TT.String)){
			node = ParseString();

		}else if(Check(TT.LanguageConstant)){
			node = ParseLanguageConstant();
		}

		return node;
	}

	ASTNode* ParseArraySubscript(ASTNode* id){
		Match(TT.LeftSquare);
		auto node = new ASTNode(AT.ArraySubscript);
		node.left = id;
		node.right = ParseExpression();
		Match(TT.RightSquare);

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

		if(Accept(TT.Pointer)){
			auto typeinfo = new ASTTypeInfo(ASTPrimitiveType.Pointer);
			typeinfo.pointerType.pointedType = base.typeinfo;
			base.typeinfo = typeinfo;

			base = ParseTypeModifiers(base);
		}else if(Accept(TT.LeftSquare)){
			auto typeinfo = new ASTTypeInfo;

			if(!Check(TT.RightSquare)){
				typeinfo.type = ASTPrimitiveType.Array;
				typeinfo.arrayType.numOfElementsExpr = ParseExpression();
			}else{
				typeinfo.type = ASTPrimitiveType.DynamicArray;
			}

			typeinfo.arrayType.pointedType = base.typeinfo;
			base.typeinfo = typeinfo;
			Match(TT.RightSquare);

			base = ParseTypeModifiers(base);
		}

		return base;
	}
	
	ASTNode* ParseBaseType(){
		auto __sd = ScopeDebug("ParseBaseType");

		if(Check(TT.Struct)){
			return ParseStruct();
		}

		auto tok = Accept(TT.Identifier);
		if(!tok){
			tok = Match(TT.Type);
		}

		auto base = tok.text;
		auto node = new ASTNode(AT.Type);
		auto typeinfo = new ASTTypeInfo;

		if(base[0] == 'u'){
			import std.algorithm : canFind;
			if(canFind(["short", "int", "long", "char"], base[1..$])){
				typeinfo.numberType.isUnsigned = true;
				base = base[1..$];
			}
		}

		switch(base){
			case "void": typeinfo.type = ASTPrimitiveType.Void; break;
			case "short": typeinfo.type = ASTPrimitiveType.Short; break;
			case "int": typeinfo.type = ASTPrimitiveType.Int; break;
			case "long": typeinfo.type = ASTPrimitiveType.Long; break;
			case "char": typeinfo.type = ASTPrimitiveType.Character; break;
			case "bool": typeinfo.type = ASTPrimitiveType.Bool; break;
			case "float": typeinfo.type = ASTPrimitiveType.Float; break;
			case "double": typeinfo.type = ASTPrimitiveType.Double; break;
			case "extended": typeinfo.type = ASTPrimitiveType.Extended; break;
			case "string": typeinfo.type = ASTPrimitiveType.String; break;
			// Function ptrs need to go here somewhere

			default: // classes/structs/typedefs
				typeinfo.type = ASTPrimitiveType.Custom;
				typeinfo.userType.name = base;
				break;
		}

		node.typeinfo = typeinfo;

		return node;
	}

	ASTNode* ParseStruct(){
		auto __sd = ScopeDebug("ParseStruct");
		Match(TT.Struct);
		Match(TT.LeftBrace);
		auto decls = ParseDeclarationList();
		Match(TT.RightBrace);

		auto typeinfo = new ASTTypeInfo;
		typeinfo.type = ASTPrimitiveType.Struct;

		foreach(ty; decls.list){
			typeinfo.aggregateType.fieldTypes ~= ty.typeinfo;
		}

		auto node = new ASTNode(AT.Type);
		node.typeinfo = typeinfo;
		node.left = decls;

		return node;
	}

	// Conditional Statements ////////////////////////////

	ASTNode* ParseConditionalStatement(){
		auto __sd = ScopeDebug("ParseConditionalStatement");
		Match(TT.If);
		auto node = new ASTNode(AT.ConditionalStatement);
		auto ifinfo = new ASTIfInfo;
		ifinfo.condition = ParseCondition();
		ifinfo.truePath = ParseStatement();

		if(Accept(TT.Else)){
			ifinfo.falsePath = ParseStatement();
		}

		node.ifinfo = ifinfo;

		return node;
	}

	ASTNode* ParseCondition(){
		auto __sd = ScopeDebug("ParseCondition");
		Match(TT.LeftParen);
		auto cond = ParseExpression();
		Match(TT.RightParen);

		return cond;
	}

	// Loops /////////////////////////////////////////////

	ASTNode* ParseLoop(){
		auto __sd = ScopeDebug("ParseLoop");
		ASTNode* node = null;
		
		if(Check(TT.For)){
			node = ParseForLoop();

		}else if(Check(TT.While)){
			node = ParseWhileLoop();

		}else if(Check(TT.Do)){
			node = ParseDoLoop();

		}else if(Check(TT.Foreach)){
			node = ParseForeachLoop();

		}else{
			Error("Tried to parse a loop that wasn't a loop " ~ next.text);
		}

		return node;
	}

	ASTNode* ParseForLoop(){
		auto __sd = ScopeDebug("ParseForLoop");
		auto node = new ASTNode(AT.Loop);
		auto loopinfo = new ASTLoopInfo;
		Match(TT.For);

		if(Accept(TT.LeftParen)){
			loopinfo.initStmt = ParseStatement(); // TODO: make this declaration only, maybe
			// assume semicolon
			loopinfo.condition = ParseExpression();
			Match(TT.SemiColon);
			loopinfo.postStmt = ParseExpression();

			Match(TT.RightParen);
		}

		loopinfo.label = ParseLoopLabel();

		node.left = ParseStatement();

		node.loopinfo = loopinfo;
		return node;
	}

	ASTNode* ParseWhileLoop(){
		auto __sd = ScopeDebug("ParseWhileLoop");
		auto node = new ASTNode(AT.Loop);
		auto loopinfo = new ASTLoopInfo;
		Match(TT.While);
		Match(TT.LeftParen);
		loopinfo.condition = ParseExpression();
		Match(TT.RightParen);

		loopinfo.label = ParseLoopLabel();

		node.left = ParseStatement();

		node.loopinfo = loopinfo;
		return node;
	}

	ASTNode* ParseDoLoop(){
		auto __sd = ScopeDebug("ParseDoLoop");
		auto node = new ASTNode(AT.Loop);
		auto loopinfo = new ASTLoopInfo;
		loopinfo.isPostCondition = true;

		Match(TT.Do);

		loopinfo.label = ParseLoopLabel();

		node.left = ParseStatement();
		Match(TT.While);
		Match(TT.LeftParen);
		loopinfo.condition = ParseExpression();
		Match(TT.RightParen);

		node.loopinfo = loopinfo;
		return node;
	}

	ASTNode* ParseForeachLoop(){
		auto __sd = ScopeDebug("ParseForeachLoop");
		auto node = new ASTNode(AT.Loop);
		auto loopinfo = new ASTLoopInfo;
		Match(TT.Foreach);

		Error("foreach is v2 feature");
		node.loopinfo = loopinfo;
		return node;
	}

	char[] ParseLoopLabel(){
		if(auto tok = Accept(TT.Assign)){
			return Match(TT.Identifier).text;
		}

		return null;
	}

	ASTNode* ParseBreak(){
		auto __sd = ScopeDebug("ParseBreak");
		auto node = new ASTNode(AT.Break);
		Match(TT.Break);

		if(auto t = Accept(TT.Identifier)){
			node.name = t.text;
		}

		Match(TT.SemiColon);
		return node;
	}

	ASTNode* ParseContinue(){
		auto __sd = ScopeDebug("ParseContinue");
		auto node = new ASTNode(AT.Continue);
		Match(TT.Continue);

		if(auto t = Accept(TT.Identifier)){
			node.name = t.text;
		}

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
		node.literalinfo.text = tok.text[1..$-1]; // strip quotation marks

		return node;
	}
	
	ASTNode* ParseLanguageConstant(){
		auto __sd = ScopeDebug("ParseLanguageConstant");
		auto tok = Match(TT.LanguageConstant);
		ASTNode* node = null;

		switch(tok.text){
			case "true":
				node = new ASTNode(AT.TrueConstant);
				break;
			case "false":
				node = new ASTNode(AT.FalseConstant);
				break;
			case "null":
				node = new ASTNode(AT.NullConstant);
				break;

			default:
				Error("Unknown language constant " ~ tok.text);
		}

		// Language constants are literals too
		node.literalinfo = new ASTLiteralInfo;
		node.literalinfo.text = tok.text;

		return node;
	}

	// Typedecls, structs, etc... ////////////////////////

	ASTNode* ParseTypeDeclaration(){
		auto __sd = ScopeDebug("ParseTypeDeclaration");

		Match(TT.TypeDecl);
		auto id = ParseIdentifier();
		auto type = ParseType();

		auto node = new ASTNode(AT.TypeDecl);
		node.name = id.name;
		node.typeinfo = type.typeinfo;

		return node;
	}
}