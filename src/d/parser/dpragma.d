module d.parser.dpragma;

import d.ast.dpragma;
import d.ast.expression;
import d.ast.identifier;
import d.ast.declaration;
import d.ast.statement;

import d.parser.declaration;
import d.parser.statement;
import d.parser.expression;
import d.parser.dtemplate;
import d.parser.base;

Pragma!ItemType parsePragma(ItemType)(ref TokenRange trange) {
	static assert(is(ItemType == Declaration) || is(ItemType == Statement),
			"Item type '" ~ ItemType.stringof ~ "' is not expected."
			~ "Only Declaration and Statement are currently supported");

	Location location = trange.front.location;
	trange.match(TokenType.Pragma);
	trange.match(TokenType.OpenParen);

	auto id = trange.front.name;
	trange.match(TokenType.Identifier);

	AstTemplateArgument[] args;

	while (trange.front.type == TokenType.Comma) {
		trange.popFront();
		args ~= trange.parseTemplateArguments();
	}

	trange.match(TokenType.CloseParen);

	location.spanTo(trange.front.location);
	trange.match(TokenType.Semicolon);

	return new Pragma!ItemType(location, id, args);
}
