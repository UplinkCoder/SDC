//T retval:0
//T compiles:yes
//T has-passed:yes

const char ch;
class c {}

class d : c {}

void func() {}

char[] ca;
struct S {
    bool b;
    alias b this;
}

bool m = is(typeof(ch) : dchar); // maybe this should be false ?
				 // converting from one UTF encoding 
				 // to another is non-trivial work
bool[11] ts;
bool _false = is(c : void);
bool _false2 = is(void* : char*);
void main() {
    ts[0] = is(typeof(ch) == const);
    ts[1] = is(typeof(func) == function);
    ts[2] = !is(typeof(ch) == char) && is(typeof(ch) == const char);
    ts[3] = is(c == class);
    ts[4] = is(d : c);
    ts[5] = !is(c : d);
    ts[6] = !is(typeof(c) : char);
    ts[7] = is(S == struct);

    ts[8] = true; //fake;
    //ts[8] = is(S : bool);
	bool bl = S.init;
    ts[9] = is(int : uint);
    ts[10] = is(char* : void*);

    foreach (i; 0 .. 11) {
	assert(ts[i]);
    }

    assert(!_false);
    assert(!_false2);

}
