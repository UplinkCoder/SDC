module d.semantic.dpragma;

import d.ast.declaration;
import d.ast.dpragma;
import d.ast.statement;

import d.context.context;
import d.context.location;
import d.context.name;

import d.ir.expression;

import d.ir.symbol;
import d.ir.type;

import d.semantic.declaration;
import d.semantic.identifier;
import d.semantic.evaluator;
import d.semantic.expression;
import d.semantic.statement;
import d.semantic.semantic;

import d.exception;

private bool isCompileTimeValue(Variable v) {
	auto tq = v.type.qualifier;
	return (tq == TypeQualifier.Immutable && v.storage == Storage.Static)
		|| v.storage == Storage.Enum;
}

struct PragmaMsgVisitor {
	private SemanticPass pass;
	private Location pragmaLocation;
	alias pass this;

	this(SemanticPass pass, Location pragmaLocation) {
		this.pass = pass;
		this.pragmaLocation = pragmaLocation;
	}

	string visit(Variable v) {
		scheduler.require(v, Step.Populated);

		if (isCompileTimeValue(v)) {
			return visit(v.value);
		} else {
			throw new CompileException(pragmaLocation,
					"variable '" ~ v.name.toString(context) ~ "' cannot be read at compile time");
		}
	}

	string visit(Expression e) {
		return this.dispatch!((e) {
			return evaluate(e).toString(context);
			/+
                throw new CompileException(
                    e.location,
                    typeid(e).toString() ~ " is not supported",
                    );
+/
		})(e);
	}

	string visit(StringLiteral s) {
		return pass.evalString(s);
	}

	string visit(Symbol s) {
		return this.dispatch!((s) {
			throw new CompileException(s.location, typeid(s).toString() ~ " is not supported",);
		})(s);
	}
}

void handlePragma(P)(P dpragma, SemanticPass pass) {
	static assert(is(P == Pragma!Statement) || is(P == Pragma!Declaration));

	if (dpragma.id == BuiltinName!"msg") {
		import std.conv;

		foreach (i, a; dpragma.args) {
			import d.semantic.expression : ExpressionVisitor;

			string str;
			final switch (a.tag) with (typeof(a.tag)) {
			case AstExpression:
				auto ae = a.get!AstExpression;
				auto e = ExpressionVisitor(pass).visit(ae);
				str = PragmaMsgVisitor(pass, dpragma.location).visit(e);
				break;

			case Identifier:
				auto id = a.get!Identifier;
				auto s = IdentifierResolver(pass).resolve(id);
				bool failed = false;
				str = s.apply!((sym) {
					static if (is(typeof(sym) : Type)) {
						return sym.getCanonical().toString(pass.context);
					} else static if (is(typeof(sym) : Symbol)) {
						return PragmaMsgVisitor(pass, dpragma.location).visit(sym);
					} else {
						failed = true;
						return ("Compiler Error: " ~ typeof(sym).stringof
							~ " isn't handled as of now\n");
					}
				});
				if (failed) {
					throw new CompileException(dpragma.location, str);
				}
				break;

			case AstType:
				auto at = a.get!AstType;
				import d.semantic.type;

				auto t = TypeVisitor(pass).visit(at);
				str = t.getCanonical().toString(pass.context);
			}
			import core.stdc.stdio;

			fprintf(stderr, "%.*s", cast(int) str.length, str.ptr); //TODO is there a better way to write to stderr in SDC?
		}
		if (dpragma.args.length) {
			import core.stdc.stdio;

			fprintf(stderr, "\n"); // TODO how do we write to stderr in SDC?
		}
	} else {
		import d.exception;

		throw new CompileException(dpragma.location,
				"Unsupported pragma: " ~ dpragma.id.toString(pass.context));
	}

}
