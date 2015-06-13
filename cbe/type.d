struct CType {
	CTypeEnum type;

	union {
		CArrayType *carray;
		CStructType *cstruct;
		CPointerType *cpointer;
		CFunctionType *cfunction;
	} 
	
}

struct Symbol {
	enum SymbolType {
		Unknown,
		Variable,
		Function,
	}

	string name;
	CType type;
	
}

struct CPointerType {
	CType type;
}

struct CFunctionType {
	string name;
	CType returnType;

	CType[] parameters;
}

struct CStruct {
	string name;
	struct Member {
		string name;
		CType type;
	}

	Member[] members;
}

struct CArray {
	uint length; // 0 means unkown e.g. Pointer
	CType type;
	
}

enum CTypeEnum {
	none,
	
	cchar,
	cshort,
	cint,
	clong,
	clonglong,

	// UDA
	cstruct,

	//Composite
	cpointer,
	carray,
	cfunction,

}
