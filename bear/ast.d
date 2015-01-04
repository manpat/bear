module bear.ast;

import std.stdio, std.conv;

struct ASTNode {
	enum NodeType {
		Invalid,

		StatementList, // list = [statement*]
		Assignment, // left = ident or subscript, right = expr
		Declaration, // left = ident, right = expr

		FunctionDeclaration, // left = ident, functioninfo
		FunctionDefinition, // left = ident, right = block, functioninfo
		FunctionCall, // left = ident, right = arg list
		FunctionArgumentList, // list = [nontuple expr*]
		FunctionParameterList, // list = [funcparameter*]
		FunctionParameter, // left = [ident], right = type

		Tuple, // list = [nontuple expr*] 
		Block, // list = [statement*]

		// left = expr, right = expr
		Plus, Minus,
		Times, Divide,

		Equals, NEquals,
		LEquals, GEquals,
		LessThan, GreaterThan,

		// left = expr
		Negate,	Deref, 
		AddressOf, Not,

		PreIncrement, PreDecrement,
		PostIncrement, PostDecrement,

		ReturnStatement, // left = expr
		ArraySubscript, // left = ident, right = expr

		ConditionalStatement, // left = expr, right = statement, third = statement
		Loop, // left = expr or null, right = statement
		PostLoop, // left = expr or null, right = statement

		Identifier, // name
		Type, // typeinfo
		Number, // literalinfo
		String, // literalinfo

		TrueConstant,
		FalseConstant,
		NullConstant,
	}

	NodeType type;
	ASTNode* left = null;
	ASTNode* right = null;
	ASTNode* third = null;

	ASTNode*[] list = null;

	char[] name = null;
	ASTTypeInfo* typeinfo = null;
	ASTLiteralInfo* literalinfo = null;
	ASTFunctionInfo* functioninfo = null;

	this(NodeType _type){
		type = _type;
	}

	string toString(){
		if((type == NodeType.Number || type == NodeType.String) 
			&& literalinfo){

			return to!string(literalinfo.text);
		}else if(type == NodeType.Identifier && name){
			return to!string(name);
		}

		string s = "(" ~ to!string(type);

		if(left){
			s ~= " " ~ left.toString;
		}
		if(right){
			if(type == NodeType.StatementList){
				s ~= "\n";
			}
			s ~= " " ~ right.toString;
		}
		if(third){
			s ~= " " ~ third.toString;
		}

		if(list){
			s ~= " [";

			foreach(i; list){
				s ~= i.toString ~ ", ";
			}
			s = s[0..$-2];
			s ~= "]";
		}

		s ~= ")";
		return s;
	}
}

struct ASTTypeInfo {
	enum Primitive {
		Void, // Maybe
		Short,
		Int,
		Long,
		Float,
		Double,

		Character,
		Function,
	}

	Primitive primitive;
	uint pointerLevel;
	bool unsigned;
}

struct ASTLiteralInfo {
	char[] text;
}

struct ASTFunctionInfo {
	ASTNode* parameterList;
	ASTNode* returnType;
}