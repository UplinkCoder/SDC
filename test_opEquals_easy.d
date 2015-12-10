

//T compiles:yes
//T has-passed:yes
//T retval:99

struct S1 {
	int a;
	bool opEquals(S1 rhs) {
		return a == rhs.a;
	}

	bool opEquals(const S2 rhs) {
		return a == rhs.a;	
	}

	this(int b) {
		a = b;
	}

}

struct S2 {
	uint a;
	this(uint a) {
		this.a = a;
	}

	bool opEquals(const uint a) {
		return this.a == a;
	}

}

int main() {

	int a = 44;
	auto s1 = S1(a);
	auto s1_2 = S1(10);
	auto s2 = S2(a);
	auto s2_2 = S2(12);
	assert (s1.opEquals(s1) == (s1 == s1));
	bool t2 = s1 == s1;
	if (s1 != s1_2) {
		a *= 2; // 88
	}
// sdc cannot find the opEquals overload here ???
//	if (s2_2 == 12) {
//		a+= 12;
//	}

	if (s1 != s2_2) {
		a -= 1; 
	}

	return a;

}


