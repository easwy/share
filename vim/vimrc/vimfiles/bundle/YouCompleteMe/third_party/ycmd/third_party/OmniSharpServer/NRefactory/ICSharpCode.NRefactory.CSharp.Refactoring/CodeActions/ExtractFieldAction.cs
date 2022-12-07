// 
// ExtractFieldAction.cs
//  
// Author:
//       Nieve <>
// 
// Copyright (c) 2012 Nieve
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
using System.Linq;
using ICSharpCode.NRefactory.PatternMatching;
using Mono.CSharp;
using ICSharpCode.NRefactory.TypeSystem;

namespace ICSharpCode.NRefactory.CSharp.Refactoring
{
	[ContextAction("Extract field", Description = "Extracts a field from a local variable declaration.")]
	public class ExtractFieldAction : CodeActionProvider
	{
		public override IEnumerable<CodeAction> GetActions(RefactoringContext context)
		{
			//TODO: implement variable assignment & ctor param
			var varInit = context.GetNode<VariableInitializer>();
			if (varInit != null) {
				var selectedNode = varInit.GetNodeAt(context.Location);
				if (selectedNode != varInit.NameToken)
					yield break;

				AstType type = varInit.GetPrevNode() as AstType;
				if (type == null) yield break;
				if (varInit.Parent is FieldDeclaration) yield break;
				if (CannotExtractField(context, varInit)) yield break;
				
				yield return new CodeAction(context.TranslateString("Assign to new field"), s=>{
					var name = varInit.Name;

					AstType extractedType;
					if (type.IsVar()) {
						IType resolvedType = context.Resolve(varInit.Initializer).Type;
						extractedType = context.CreateShortType(resolvedType);
					}
					else {
						extractedType = (AstType) type.Clone();
					}

					AstNode entityDeclarationNode = varInit.Parent;
					while (!(entityDeclarationNode is EntityDeclaration) || (entityDeclarationNode is Accessor)) {
						entityDeclarationNode = entityDeclarationNode.Parent;
					}
					var entity = (EntityDeclaration) entityDeclarationNode;
					bool isStatic = entity.HasModifier(Modifiers.Static);

					FieldDeclaration field = new FieldDeclaration(){
						Modifiers = isStatic ? Modifiers.Static : Modifiers.None,
						ReturnType = extractedType,
						Variables = { new VariableInitializer(name) }
					};
					AstNode nodeToRemove = RemoveDeclaration(varInit) ? varInit.Parent : type;
					s.Remove(nodeToRemove, true);
					s.InsertWithCursor(context.TranslateString("Insert new field"),Script.InsertPosition.Before,field);
					s.FormatText(varInit.Parent);
				}, selectedNode);
			}
			
			var idntf = context.GetNode<Identifier>();
			if (idntf == null) yield break;
			var paramDec = idntf.Parent as ParameterDeclaration;
			if (paramDec != null) {
				var ctor = paramDec.Parent as ConstructorDeclaration;
				if (ctor == null) yield break;
				MemberReferenceExpression thisField = new MemberReferenceExpression(new ThisReferenceExpression(), idntf.Name, new AstType[]{});
				var assign = new AssignmentExpression(thisField, AssignmentOperatorType.Assign, new IdentifierExpression(idntf.Name));
				var statement = new ExpressionStatement(assign);
				var type = (idntf.GetPrevNode() as AstType).Clone();
				FieldDeclaration field = new FieldDeclaration(){
					ReturnType = type.Clone(),
					Variables = { new VariableInitializer(idntf.Name) }
				};
				yield return new CodeAction(context.TranslateString("Assign to new field"), s=>{
					s.InsertWithCursor(context.TranslateString("Insert new field"),Script.InsertPosition.Before,field);
					s.AddTo(ctor.Body, statement);
				}, paramDec.NameToken);
			}
		}
		
		static bool RemoveDeclaration (VariableInitializer varInit){
			var result = varInit.Parent as VariableDeclarationStatement;
			return result.Variables.First ().Initializer.IsNull;
		}
		
		static bool CannotExtractField (RefactoringContext context, VariableInitializer varInit)
		{
			var result = varInit.Parent as VariableDeclarationStatement;
			return result == null || result.Variables.Count != 1 || ContainsAnonymousType(context.Resolve(varInit.Initializer).Type);
		}

		static bool ContainsAnonymousType (IType type)
		{
			if (type.Kind == TypeKind.Anonymous)
				return true;

			var arrayType = type as ArrayType;
			return arrayType != null && ContainsAnonymousType (arrayType.ElementType);
		}
	}
}

