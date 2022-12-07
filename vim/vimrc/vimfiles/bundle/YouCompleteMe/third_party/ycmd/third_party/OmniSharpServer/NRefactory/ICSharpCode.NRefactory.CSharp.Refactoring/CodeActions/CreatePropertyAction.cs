﻿// 
// CreateProperty.cs
//  
// Author:
//       Mike Krüger <mkrueger@novell.com>
// 
// Copyright (c) 2011 Novell, Inc (http://www.novell.com)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
using System;
using System.Collections.Generic;
using ICSharpCode.NRefactory.Semantics;
using ICSharpCode.NRefactory.TypeSystem;

namespace ICSharpCode.NRefactory.CSharp.Refactoring
{
	[ContextAction("Create property", Description = "Creates a property for a undefined variable.")]
	public class CreatePropertyAction : CodeActionProvider
	{
		public override IEnumerable<CodeAction> GetActions(RefactoringContext context)
		{
			var identifier = CreateFieldAction.GetCreatePropertyOrFieldNode (context);
			if (identifier == null)
				yield break;
			if (CreateFieldAction.IsInvocationTarget(identifier))
				yield break;

			var propertyName = GetPropertyName(identifier);
			if (propertyName == null)
				yield break;

			var statement = context.GetNode<Statement>();
			if (statement == null)
				yield break;

			if (!(context.Resolve(identifier).IsError))
				yield break;

			var guessedType = TypeGuessing.GuessAstType(context, identifier);
			if (guessedType == null)
				yield break;
			var state = context.GetResolverStateBefore(identifier);
			if (state.CurrentTypeDefinition == null)
				yield break;
			
			bool createInOtherType = false;
			ResolveResult targetResolveResult = null;
			if (identifier is MemberReferenceExpression) {
				targetResolveResult = context.Resolve(((MemberReferenceExpression)identifier).Target);
				if (targetResolveResult.Type.GetDefinition() == null || targetResolveResult.Type.GetDefinition().Region.IsEmpty)
					yield break;
				createInOtherType = !state.CurrentTypeDefinition.Equals(targetResolveResult.Type.GetDefinition());
			}

			bool isStatic = targetResolveResult is TypeResolveResult;
			if (createInOtherType) {
				if (isStatic && targetResolveResult.Type.Kind == TypeKind.Interface || targetResolveResult.Type.Kind == TypeKind.Enum)
					yield break;
			} else {
				if (state.CurrentMember == null)
					yield break;
				isStatic |= state.CurrentTypeDefinition.IsStatic;
				if (targetResolveResult == null)
					isStatic |= state.CurrentMember.IsStatic;
			}
			isStatic &= !(identifier is NamedExpression);

	//			var service = (NamingConventionService)context.GetService(typeof(NamingConventionService));
//			if (service != null && !service.IsValidName(propertyName, AffectedEntity.Property, Modifiers.Private, isStatic)) { 
//				yield break;
//			}

			yield return new CodeAction(context.TranslateString("Create property"), script => {
				var decl = new PropertyDeclaration() {
					ReturnType = guessedType,
					Name = propertyName,
					Getter = new Accessor(),
					Setter = new Accessor()
				};
				if (isStatic)
					decl.Modifiers |= Modifiers.Static;
				
				if (createInOtherType) {
					if (targetResolveResult.Type.Kind == TypeKind.Interface) {
						decl.Modifiers = Modifiers.None;
					} else {
						decl.Modifiers |= Modifiers.Public;
					}
					script.InsertWithCursor(
						context.TranslateString("Create property"),
						targetResolveResult.Type.GetDefinition(),
						(s, c) => decl);

					return;
				}

				script.InsertWithCursor(context.TranslateString("Create property"), Script.InsertPosition.Before, decl);

			}, identifier.GetNodeAt(context.Location) ?? identifier) { Severity = ICSharpCode.NRefactory.Refactoring.Severity.Error };
		}

		internal static string GetPropertyName(Expression expr)
		{
			if (expr is IdentifierExpression) 
				return ((IdentifierExpression)expr).Identifier;
			if (expr is MemberReferenceExpression) 
				return ((MemberReferenceExpression)expr).MemberName;
			if (expr is NamedExpression) 
				return ((NamedExpression)expr).Name;

			return null;
		}
	}
}

