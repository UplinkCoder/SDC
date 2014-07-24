import std.file;
import std.string;
import std.stdio;
import std.json;
import d.
//import jsonx;

void main() {
	writeln("Reading 'tests.json' ...");
	JSONValue[string] testsJson = readText("tests.json").parseJSON.object;
	writeln("... Done.");
	writeln("Runnig tests now.");
	immutable uint len = cast(immutable uint) testsJson["len"].integer;
	 
	JSONValue[] tests = testsJson["tests"].array;
	
	foreach (i,test;tests) 
		//string command = format("%s -c -o test%04d.o -","../bin/sdc",i);
		string code = test["code"].str;
		//auto pid = spwanProcess(command,codeFile,stdout,stderr);
		
	}
}

int runTest(string code, string[] deps);
