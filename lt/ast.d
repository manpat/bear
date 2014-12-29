module lt.ast;

import std.stdio, std.conv;

struct ASTNode {
	enum NodeType {
		Invalid,

		StatementList,
		Assignment,
		Declaration,

		FunctionDeclaration,
		FunctionDefinition,
		FunctionCall,
		FunctionArgumentList,

		Tuple,
		Block,

		Plus, Minus,
		Times, Divide,

		Negate,	Deref, 
		AddressOf, Not,

		Identifier,
		Type,
		Number,
		String,
	}

	NodeType type;
	ASTNode* left = null;
	ASTNode* right = null;

	ASTNode*[] list = null;

	char[] name = null;
	ASTTypeInfo* typeinfo = null;
	ASTLiteralInfo* literalinfo = null;

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

struct ASTLiteralInfo {
	char[] text;
}

struct ASTFunctionInfo {

}