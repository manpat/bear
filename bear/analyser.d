module bear.analyser;

import std.stdio;
import std.conv;
import std.algorithm;
import bear.ast;

class Analyser {
	alias AT = ASTNode.NodeType;

	ASTNode* ast;
	Scope globalScope;

	void Analyse(ASTNode* root){
		globalScope = new Scope();
		ast = root;

		if(ast.type == AT.StatementList){
			foreach(stmt; ast.list){				
				switch(stmt.type){
					case AT.FunctionDeclaration:
					case AT.FunctionDefinition:
					case AT.Declaration:
						HandleDeclaration(globalScope, stmt);
						break;

					default:
						break;
				}
			}
		}
	}

private:
	void HandleDeclaration(Scope currentScope, ASTNode* decl){
		auto name = decl.left.name;

		if(!currentScope) assert(0, "currentScope is fucked");

		if(currentScope.symbols.Lookup(name)){
			throw new Exception("Declaration of name " ~ name.idup ~ " already exists in scope");
		}

		auto sym = new Symbol;
		sym.parentScope = currentScope;
		sym.typeinfo = decl.typeinfo;
		sym.astnode = decl;

		currentScope.symbols.Insert(name, sym);
	}
}

class Scope {
	Scope parentScope = null;
	SymbolTable symbols;

	this(){
		symbols = new SymbolTable();
	}
}

class SymbolTable {
	struct Node {
		char[] name;
		Symbol symbol;
		Node* next = null;
	}

	struct Bucket{
		Node* first = null;
		Node* last = null;
	}

	Bucket[ulong] buckets;

	void Insert(char[] name, Symbol symbol){
		ulong hash = GetHash(name);
		if(hash !in buckets){
			buckets[hash] = Bucket.init;
		}

		auto node = new Node;
		node.name = name;
		node.symbol = symbol;

		auto bucket = &buckets[hash];
		Insert(bucket, node);

		writeln("new symbol: ", name);
	}

	void Remove(char[] name){
		ulong hash = GetHash(name);
		if(hash !in buckets){
			return;
		}

		auto bucket = &buckets[hash];
		Remove(bucket, name);
	}

	Symbol Lookup(char[] name){
		ulong hash = GetHash(name);
		if(hash !in buckets){
			return null;
		}

		auto bucket = &buckets[hash];
		return Lookup(bucket, name);	
	}

	private {
		void Insert(Bucket* bucket, Node* node){
			if(!bucket.first){
				bucket.first = node;
			}
			if(bucket.last){
				bucket.last.next = node;
			}

			bucket.last = node;
		}

		void Remove(Bucket* bucket, char[] name){
			Node* it = bucket.first;
			Node* prev = null;
			bool found = false;

			while(it.next){
				if(it.name == name) {
					found = true;
					break;
				}

				prev = it;
				it = it.next;
			}

			if(!found) return;

			if(prev) prev.next = it.next;
			// GC will do the rest. Jeez this feels wrong
		}

		Symbol Lookup(Bucket* bucket, char[] name){
			for(auto it = bucket.first; it; it = it.next){
				if(it.name == name) {
					return it.symbol;
				}
			}

			return null;
		}

		static ulong GetHash(char[] name){
			ulong hash = 0;

			foreach(i; 0..min(name.length, 8)){
				hash <<= 8;
				hash |= name[i];
			}

			return hash;
		}
	}
}

class Symbol {
	Scope parentScope = null;
	ASTTypeInfo* typeinfo = null;
	ASTNode* astnode = null; // not sure if I need this
}