module bear.ast;

import std.conv;

struct ASTNode {
	enum NodeType {
		Invalid,

		StatementList, // list = [statement*]
		Assignment, // left = ident or subscript, right = expr
		Declaration, // left = ident, right = expr

		FunctionDeclaration, // left = ident, typeinfo
		FunctionDefinition, // left = ident, right = block, typeinfo
		FunctionCall, // left = ident, right = arg list
		FunctionArgumentList, // list = [nontuple expr*]
		FunctionParameterList, // list = [funcparameter*]
		FunctionParameter, // left = [ident], right = type

		Sequence, // list = [nontuple expr*] 
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

		// left = expr
		PreIncrement, PreDecrement,
		PostIncrement, PostDecrement,

		ReturnStatement, // left = expr
		ArraySubscript, // left = ident, right = expr

		ConditionalStatement, // ifinfo
		Loop, // left = expr or null, right = statement, loopinfo

		Break, Continue, // name = label or null

		Identifier, // name
		Number, // literalinfo
		String, // literalinfo
		Type, // typeinfo

		TypeDecl, // name, typeinfo

		TrueConstant,
		FalseConstant,
		NullConstant,
	}

	NodeType type;
	ASTNode* left = null;
	ASTNode* right = null;

	ASTNode*[] list = null;

	char[] name = null;
	ASTTypeInfo* typeinfo = null;
	ASTLiteralInfo* literalinfo = null;
	ASTLoopInfo* loopinfo = null;
	ASTIfInfo* ifinfo = null;

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

		if(name){
			s ~= " \"" ~ to!string(name) ~ "\"";
		}else if(loopinfo && loopinfo.label){
			s ~= " \"" ~ to!string(loopinfo.label) ~ "\"";
		}

		if(typeinfo){
			s ~= " <" ~ typeinfo.toString ~ ">";
		}

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

enum ASTPrimitiveType {
	Void,
	Bool,
	Short,
	Int,
	Long,
	Float,
	Double,
	Extended,
	Character,

	String, // Character array
	Function,

	Array, // Pointer + const length // on stack or heap allocated
	DynamicArray, // Pointer + length // heap only
	Pointer,

	Struct,
	Custom, // should be replaced with struct or class or whatever in later stage
}

struct ASTTypeInfo {
	ASTPrimitiveType type;
	
	union {
		NumberType numberType;
		UserType userType;
		PointerType pointerType;
		ArrayType arrayType;
		PointerType dynArrayType; // Pointer type because they're identical anyway
		FunctionType functionType;
		AggregateType aggregateType;
	}

	static struct NumberType {
		bool isUnsigned;
	}

	static struct UserType {
		char[] name;
	}

	static struct AggregateType {
		ASTTypeInfo*[] fieldTypes;
	}

	static struct PointerType {
		ASTTypeInfo* pointedType;
	}

	static struct ArrayType {
		ASTTypeInfo* pointedType;
		ASTNode* numOfElementsExpr;
	}

	static struct FunctionType {
		ASTNode* parameterList;
		ASTTypeInfo* returnType;
	}

	string toString(){
		if(type == ASTPrimitiveType.Custom){
			return userType.name.idup;
		}else if(type == ASTPrimitiveType.Pointer){
			return pointerType.pointedType.toString ~ "^";
		}else if(type == ASTPrimitiveType.Array){
			return pointerType.pointedType.toString ~ "[static]";
		}else if(type == ASTPrimitiveType.DynamicArray){
			return pointerType.pointedType.toString ~ "[dyn]";
		}else if(type == ASTPrimitiveType.Struct){
			string s = "struct { ";

			foreach(ti; aggregateType.fieldTypes){
				s ~= ti.toString ~ "; ";
			}

			return s ~ "}";
		}

		return to!string(type);
	}
}

struct ASTLiteralInfo {
	char[] text;
}

struct ASTLoopInfo {
	char[] label = null;

	ASTNode* initStmt = null; // for, foreach (under the hood)
	ASTNode* condition = null;
	ASTNode* postStmt = null; // for, foreach (under the hood)

	bool isPostCondition = false; // do while
}

struct ASTIfInfo {
	ASTNode* condition = null;
	ASTNode* truePath = null;
	ASTNode* falsePath = null; // optional
}