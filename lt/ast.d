module lt.ast;

import std.stdio, std.conv;

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
