/// Part of a 'mock' phobos used for testing. Not intended for real use.
module std.stdio;


	
void writeln(string s) {
	if (s.ptr[s.length] != '\0') {
		assert(0,"NO NULL TERMINATION! you are crazy!");
	}
	printf("%s\n".ptr,s.ptr);
}

void writeln (char c) {
	printf("%c\n".ptr,c);
}

void writeln(int i) {
	printf("%d\n".ptr,i);
}
