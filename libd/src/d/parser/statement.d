module d.parser.statement;

import d.ast.declaration;
import d.ast.expression;
import d.ast.statement;
import d.ast.type;

import d.ir.statement;

import d.parser.ambiguous;
import d.parser.base;
import d.parser.conditional;
import d.parser.declaration;
import d.parser.expression;
import d.parser.type;

AstStatement parseStatement(ref TokenRange trange) {
	Location location = trange.front.location;
	
	switch(trange.front.type) with(TokenType) {
		case OpenBrace :
			return trange.parseBlock();
		
		case Identifier :
			auto lookahead = trange.save;
			lookahead.popFront();
			
			if (lookahead.front.type == Colon) {
				goto case Default;
			}
			
			// If it is not a labeled statement, then it is a declaration or an expression.
			goto default;
		
		case If :
			trange.popFront();
			trange.match(OpenParen);
			
			auto condition = trange.parseExpression();
			
			trange.match(CloseParen);
			
			auto then = trange.parseStatement();
			
			AstStatement elseStatement;
			if (trange.front.type == Else) {
				trange.popFront();
				
				elseStatement = trange.parseStatement();
				
				location.spanTo(elseStatement.location);
			} else {
				location.spanTo(then.location);
			}
			
			return new AstIfStatement(location, condition, then, elseStatement);
		
		case While :
			trange.popFront();
			trange.match(OpenParen);
			auto condition = trange.parseExpression();
			
			trange.match(CloseParen);
			
			auto statement = trange.parseStatement();
			
			location.spanTo(statement.location);
			return new WhileStatement(location, condition, statement);
		
		case Do :
			trange.popFront();
			
			auto statement = trange.parseStatement();
			
			trange.match(While);
			trange.match(OpenParen);
			auto condition = trange.parseExpression();
			
			trange.match(CloseParen);
			trange.match(Semicolon);
			
			location.spanTo(trange.previous);
			return new DoWhileStatement(location, condition, statement);
		
		case For :
			trange.popFront();
			
			trange.match(OpenParen);
			
			AstStatement init;
			if (trange.front.type != Semicolon) {
				init = trange.parseStatement();
			} else {
				init = new AstBlockStatement(trange.front.location, []);
				trange.popFront();
			}
			
			AstExpression condition;
			if (trange.front.type != Semicolon) {
				condition = trange.parseExpression();
			}
			
			trange.match(Semicolon);
			
			AstExpression increment;
			if (trange.front.type != CloseParen) {
				increment = trange.parseExpression();
			}
			
			trange.match(CloseParen);
			
			auto statement = trange.parseStatement();
			
			location.spanTo(statement.location);
			return new ForStatement(location, init, condition, increment, statement);
		
		case Foreach, ForeachReverse :
			bool reverse = (trange.front.type == ForeachReverse);
			trange.popFront();
			trange.match(OpenParen);
			
			ParamDecl parseForeachListElement() {
				Location elementLocation = trange.front.location;
				
				bool isRef = trange.front.type == Ref;
				if (isRef) {
					trange.popFront();
				}
				
				bool parseType = true;
				// If we have an idientifer, check if the type is implicit.
				if (trange.front.type == Identifier) {
						auto lookahead = trange.save;
						lookahead.popFront();
						if (lookahead.front.type == Comma || lookahead.front.type == Semicolon) {
							parseType = false;
						}
				}
				
				auto type = parseType
					? trange.parseType()
					: AstType.getAuto();
				
				auto name = trange.front.name;
				elementLocation.spanTo(trange.front.location);
				
				trange.match(Identifier);
				
				return ParamDecl(elementLocation, type.getParamType(isRef, false), name, null);
			}
			
			ParamDecl[] tupleElements = [parseForeachListElement()];
			while(trange.front.type == Comma) {
				trange.popFront();
				tupleElements ~= parseForeachListElement();
			}
			
			trange.match(Semicolon);
			auto iterrated = trange.parseExpression();
			
			bool isRange = trange.front.type == DotDot;
			
			AstExpression endOfRange;
			if (isRange) {
				trange.popFront();
				endOfRange = trange.parseExpression();
			}
			
			trange.match(CloseParen);
			
			auto statement = trange.parseStatement();
			location.spanTo(statement.location);
			
			return isRange
				? new ForeachRangeStatement(
					location,
					tupleElements,
					iterrated,
					endOfRange,
					statement,
					reverse,
				)
				: new ForeachStatement(
					location,
					tupleElements,
					iterrated,
					statement,
					reverse,
				);
		
		case Return :
			trange.popFront();
			
			AstExpression value;
			if (trange.front.type != Semicolon) {
				value = trange.parseExpression();
			}
			
			trange.match(Semicolon);
			
			location.spanTo(trange.previous);
			return new AstReturnStatement(location, value);
		
		case Break :
			trange.popFront();
			
			if (trange.front.type == Identifier) {
				trange.popFront();
			}
			
			trange.match(Semicolon);
			
			location.spanTo(trange.previous);
			return new BreakStatement(location);
		
		case Continue :
			trange.popFront();
			
			if (trange.front.type == Identifier) {
				trange.popFront();
			}
			
			trange.match(Semicolon);
			
			location.spanTo(trange.previous);
			return new ContinueStatement(location);
		
		case Switch :
			trange.popFront();
			trange.match(OpenParen);
			
			auto expression = trange.parseExpression();
			
			trange.match(CloseParen);
			
			auto statement = trange.parseStatement();
			location.spanTo(statement.location);
			
			return new AstSwitchStatement(location, expression, statement);
		
		case Case :
			trange.popFront();
			
			AstExpression[] cases = trange.parseArguments();
			
			trange.match(Colon);
			
			location.spanTo(trange.previous);
			return new AstCaseStatement(location, cases);
		
		case Default :
			// Other labeled statement will jump here !
			auto label = trange.front.name;
			trange.popFront();
			trange.match(Colon);
			
			AstStatement statement;
			if (trange.front.type != CloseBrace) {
				statement = trange.parseStatement();
				location.spanTo(statement.location);
			} else {
				location.spanTo(trange.front.location);
				statement = new AstBlockStatement(location, []);
			}
			
			return new AstLabeledStatement(location, label, statement);
		
		case Goto :
			trange.popFront();
			
			import d.context.name;
			Name label;
			switch(trange.front.type) {
				case Identifier :
				case Default :
				case Case :
					label = trange.front.name;
					trange.popFront();
					break;
				
				default :
					trange.match(Identifier);
			}
			
			trange.match(Semicolon);
			
			location.spanTo(trange.previous);
			return new GotoStatement(location, label);
		
		case Scope :
			trange.popFront();
			trange.match(OpenParen);
			
			auto name = trange.front.name;
			trange.match(Identifier);
			
			import d.context.name;
			ScopeKind kind;
			if (name == BuiltinName!"exit") {
				kind = ScopeKind.Exit;
			} else if (name == BuiltinName!"success") {
				kind = ScopeKind.Success;
			} else if (name == BuiltinName!"failure") {
				kind = ScopeKind.Failure;
			} else {
				assert(0, name.toString(trange.context) ~ " is not a valid scope identifier.");
			}
			
			trange.match(CloseParen);
			
			auto statement = trange.parseStatement();
			location.spanTo(statement.location);
			
			return new AstScopeStatement(location, kind, statement);
		
		case Assert :
			trange.popFront();
			trange.match(OpenParen);
			
			auto condition = trange.parseAssignExpression();
			AstExpression message;
			if (trange.front.type == Comma) {
				trange.popFront();
				message = trange.parseAssignExpression();
				
				// Trailing comma
				if (trange.front.type == Comma) {
					trange.popFront();
				}
			}
			
			trange.match(CloseParen);
			trange.match(Semicolon);
			
			location.spanTo(trange.previous);
			return new AstAssertStatement(location, condition, message);
		
		case Throw :
			trange.popFront();
			auto value = trange.parseExpression();
			
			trange.match(Semicolon);
			
			location.spanTo(trange.previous);
			return new AstThrowStatement(location, value);
		
		case Try :
			trange.popFront();
			
			auto statement = trange.parseStatement();
			
			AstCatchBlock[] catches;
			while(trange.front.type == Catch) {
				auto catchLocation = trange.front.location;
				trange.popFront();
				
				if (trange.front.type == OpenParen) {
					trange.popFront();
					
					import d.parser.identifier;
					auto type = trange.parseIdentifier();
					
					import d.context.name;
					Name name;
					if(trange.front.type == Identifier) {
						name = trange.front.name;
						trange.popFront();
					}
					
					trange.match(CloseParen);
					
					auto catchStatement = trange.parseStatement();
					
					location.spanTo(catchStatement.location);
					catches ~= AstCatchBlock(location, type, name, catchStatement);
				} else {
					// TODO: handle final catches ?
					trange.parseStatement();
					assert(0, "Final catches not implemented");
				}
			}
			
			AstStatement finallyStatement;
			if (trange.front.type == Finally) {
				trange.popFront();
				finallyStatement = trange.parseStatement();
				
				location.spanTo(finallyStatement.location);
			} else {
				location.spanTo(catches[$ - 1].location);
			}
			
			return new AstTryStatement(location, statement, catches, finallyStatement);
		
		case Synchronized :
			trange.popFront();
			if (trange.front.type == OpenParen) {
				trange.popFront();
				trange.parseExpression();
				trange.match(CloseParen);
			}
			
			auto statement = trange.parseStatement();
			location.spanTo(statement.location);
			
			return new AstSynchronizedStatement(location, statement);
		
		case Mixin :
			//could be an expression so if we cannot parse it as a Statement fall back to expression
			trange.popFront();
			trange.match(TokenType.OpenParen);

			auto expr = trange.parseAssignExpression();

			trange.match(TokenType.CloseParen);

			if (trange.front.type == TokenType.Semicolon) {
				location.spanTo(trange.front.location);
				trange.popFront();

				return new d.ast.conditional.Mixin!AstStatement(location, expr);
			}

			location.spanTo(trange.previous);
			auto prev = new d.ast.conditional.Mixin!AstExpression(location, expr);

			AstStatement stmt;
			stmt = new AstExpressionStatement(
				trange.parseAssignExpression(prev)
			);

			trange.match(TokenType.Semicolon);
			
			return stmt;
		
		case Static :
			auto lookahead = trange.save;
			lookahead.popFront();
			
			switch(lookahead.front.type) {
				case If:
					return trange.parseStaticIf!AstStatement();
				
				case Assert:
					return trange.parseStaticAssert!AstStatement();
				
				default:
					auto declaration = trange.parseDeclaration();
					return new DeclarationStatement(declaration);
			}
		
		case Version :
			return trange.parseVersion!AstStatement();
		
		case Debug :
			return trange.parseDebug!AstStatement();
		
		default :
			return trange.parseDeclarationOrExpression!(delegate AstStatement(parsed) {
				alias T = typeof(parsed);
				
				static if (is(T : AstExpression)) {
					trange.match(Semicolon);
					return new AstExpressionStatement(parsed);
				} else static if (is(T : Declaration)) {
					return new DeclarationStatement(parsed);
				} else {
					trange.match(Semicolon);
					auto location = parsed.identifier.location;
					location.spanTo(trange.previous);
					return new IdentifierStarIdentifierStatement(
						location,
						parsed.identifier,
						parsed.name,
						parsed.value,
					);
				}
			})();
	}
	
	assert(0);
}

AstBlockStatement parseBlock(ref TokenRange trange) {
	Location location = trange.front.location;
	
	trange.match(TokenType.OpenBrace);
	
	AstStatement[] statements;
	
	while(trange.front.type != TokenType.CloseBrace) {
		statements ~= trange.parseStatement();
	}
	
	trange.popFront();
	
	location.spanTo(trange.previous);
	return new AstBlockStatement(location, statements);
}

