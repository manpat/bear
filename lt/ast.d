module lt.ast;

import std.stdio, std.conv;

struct ASTNode {
	enum Type {
		Invalid,
		Root,

		Statement,
		StatementList,
		Assignment,
		Declaration,

		FunctionDeclaration,
		FunctionDefinition,
		FunctionCall,

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

	Type type;
	ASTNode* left = null;
	ASTNode* right = null;

	char[] name = null;
	TypeInfo* typeinfo = null;
	LiteralInfo* literalinfo = null;

	this(Type _type){
		type = _type;
	}

	string toString(){
		if((type == Type.Number || type == Type.String) 
			&& literalinfo){

			return to!string(literalinfo.text);
		}else if(type == Type.Identifier && name){
			return to!string(name);
		}

		string s = "(" ~ to!string(type);

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

struct LiteralInfo {
	char[] text;
}
