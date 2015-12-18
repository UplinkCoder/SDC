//T compiles:yes
//T has-passed:yes
//T retval:13
// Tests IFTI overloads with constraints


auto handle(int v)() if (v == 1) {
	return 6;	
}

auto handle(int v)() if (v != 3 && v != 1) {
	return 2;
}

auto handle(int v)() if (v == 3) {
	return 3;
}


int main() {
	return 
		handle!1() + // 6
		handle!2() + // 8
		handle!3() + // 11
		handle!4();  // 13	
}
