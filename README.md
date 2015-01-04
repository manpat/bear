Bear
====

Bear is an experiment in language parsing and compilation. It's loosely based on Go, D, and C. Syntax analysis has been implemented with an LL(1) parser. Structures haven't been added to the language yet but will be added after semantic analysis has been done and when something runnable has been added (either an interpretation or code generation stage). A lot of semantic related things are still to be determined.

Here's a preview of the intended syntax

```Go
anInt int = 123;
anIntPointer int^ = @anInt;

func aFunctionWithNoParameters -> int^ {
    return anIntPointer;
}

func withNoReturn(aStringPointer string^, anArray char[]) {
    ^aStringPointer = anArray;
}

func main {
	// This is where things go
	anInt = ^aFunctionWithNoParameters();
	/* more comments */

	if(anInt > 314){
		// ...
	}else{
		// ...
	}

	for somethingToDoForever();
	for(i int; i < 10; ++i) somethingToDo10Times();
	while(cond) somethingToDoWhileCondIsTrue();
	do aLoopWithAPostCondition(); while(postCondition);

	if(a)
		if(b) aThing();
		else someOtherThing(); // elses bind to the nearest unbound if

	else yetAnotherThing();
}
```
