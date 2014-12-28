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

		ReadNext();
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
	//////////////////////////////////////////////////////

	// Start /////////////////////////////////////////////

	ASTNode* ParseProgram(){
		mixin FunctionStart!"ParseProgram";

		return null;
	}

	// Statements ////////////////////////////////////////

	ASTNode* ParseStatementList(){
		mixin FunctionStart!"ParseStatementList";

		return null;
	}

	ASTNode* ParseStatement(){
		mixin FunctionStart!"ParseStatement";

		return null;
	}

	// Declarations and Assignments //////////////////////

	ASTNode* ParseDeclOrAssign(){
		mixin FunctionStart!"ParseDeclOrAssign";

		return null;
	}

	ASTNode* ParseOptionalType(){
		mixin FunctionStart!"ParseOptionalType";

		return null;
	}

	ASTNode* ParseOptionalAssign(){
		mixin FunctionStart!"ParseOptionalAssign";

		return null;
	}

	ASTNode* ParseAssignmentStub(){
		mixin FunctionStart!"ParseAssignmentStub";

		return null;
	}

	ASTNode* ParseBlock(){
		mixin FunctionStart!"ParseBlock";

		return null;
	}

	// Function calls ////////////////////////////////////

	ASTNode* ParseFuncCall(){
		mixin FunctionStart!"ParseFuncCall";

		return null;
	}

	ASTNode* ParseArgumentList(){
		mixin FunctionStart!"ParseArgumentList";

		return null;
	}

	// Function Declarations and Definitions /////////////

	ASTNode* ParseFuncDeclOrDef(){
		mixin FunctionStart!"ParseFuncDeclOrDef";

		return null;
	}

	ASTNode* ParseFuncDecl(){
		mixin FunctionStart!"ParseFuncDecl";

		return null;
	}

	ASTNode* ParseFuncDeclParam(){
		mixin FunctionStart!"ParseFuncDeclParam";

		return null;
	}

	ASTNode* ParseFuncDeclType(){
		mixin FunctionStart!"ParseFuncDeclType";

		return null;
	}

	ASTNode* ParseParameterList(){
		mixin FunctionStart!"ParseParameterList";

		return null;
	}

	ASTNode* ParseParameter(){
		mixin FunctionStart!"ParseParameter";

		return null;
	}

	ASTNode* ParseReturn(){
		mixin FunctionStart!"ParseReturn";

		return null;
	}

	// Expressions ///////////////////////////////////////

	ASTNode* ParseExpression(){
		mixin FunctionStart!"ParseExpression";

		return null;
	}

	ASTNode* ParseExpressionR(){
		mixin FunctionStart!"ParseExpressionR";

		return null;
	}

	ASTNode* ParseBinOpAddPrecedence(){
		mixin FunctionStart!"ParseBinOpAddPrecedence";

		return null;
	}

	ASTNode* ParseBinOpAddPrecedenceR(){
		mixin FunctionStart!"ParseBinOpAddPrecedenceR";

		return null;
	}

	ASTNode* ParseBinOpMulPrecedence(){
		mixin FunctionStart!"ParseBinOpMulPrecedence";

		return null;
	}

	ASTNode* ParseBinOpMulPrecedenceR(){
		mixin FunctionStart!"ParseBinOpMulPrecedenceR";

		return null;
	}

	ASTNode* ParseUnaryOp(){
		mixin FunctionStart!"ParseUnaryOp";

		return null;
	}

	ASTNode* ParseExpressionTerm(){
		mixin FunctionStart!"ParseExpressionTerm";

		return null;
	}

	// Types /////////////////////////////////////////////

	ASTNode* ParseType(){
		mixin FunctionStart!"ParseType";

		return null;
	}

	ASTNode* ParseTypeModifiers(){
		mixin FunctionStart!"ParseTypeModifiers";

		return null;
	}
	
	ASTNode* ParseBaseType(){
		mixin FunctionStart!"ParseBaseType";

		return null;
	}

	// Terminals /////////////////////////////////////////

	ASTNode* ParseIdentifier(){
		mixin FunctionStart!"ParseIdentifier";

		return null;
	}
	
	ASTNode* ParseNumber(){
		mixin FunctionStart!"ParseNumber";

		return null;
	}
}