﻿// 
// UnusedTypeParameterIssue.cs
// 
// Author:
//      Mansheng Yang <lightyang0@gmail.com>
// 
// Copyright (c) 2012 Mansheng Yang <lightyang0@gmail.com>
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
using ICSharpCode.NRefactory.CSharp.Resolver;
using ICSharpCode.NRefactory.Semantics;
using ICSharpCode.NRefactory.TypeSystem;
using ICSharpCode.NRefactory.Refactoring;

namespace ICSharpCode.NRefactory.CSharp.Refactoring
{
	[IssueDescription("Unused type parameter",
		Description = "Type parameter is never used.",
		Category = IssueCategories.RedundanciesInDeclarations,
		Severity = Severity.Warning,
		AnalysisDisableKeyword = "UnusedTypeParameter")]
	public class UnusedTypeParameterIssue : GatherVisitorCodeIssueProvider
	{
		static FindReferences refFinder = new FindReferences();

		protected override IGatherVisitor CreateVisitor(BaseRefactoringContext context)
		{
			var unit = context.RootNode as SyntaxTree;
			if (unit == null)
				return null;
			return new GatherVisitor(context, unit);
		}

		protected static bool FindUsage(BaseRefactoringContext context, SyntaxTree unit,
		                                 ITypeParameter typeParameter, AstNode declaration)
		{
			var found = false;
			var searchScopes = refFinder.GetSearchScopes(typeParameter);
			refFinder.FindReferencesInFile(searchScopes, context.Resolver,
				(node, resolveResult) => {
					if (node != declaration)
						found = true;
				}, context.CancellationToken);
			return found;
		}

		class GatherVisitor : GatherVisitorBase<UnusedTypeParameterIssue>
		{
			SyntaxTree unit;

			public GatherVisitor(BaseRefactoringContext ctx, SyntaxTree unit)
				: base(ctx)
			{
				this.unit = unit;
			}

			public override void VisitTypeParameterDeclaration(TypeParameterDeclaration decl)
			{
				base.VisitTypeParameterDeclaration(decl);

				var resolveResult = ctx.Resolve(decl) as TypeResolveResult;
				if (resolveResult == null)
					return;
				var typeParameter = resolveResult.Type as ITypeParameter;
				if (typeParameter == null)
					return;
				var methodDecl = decl.Parent as MethodDeclaration;
				if (methodDecl == null)
					return;

				if (FindUsage(ctx, unit, typeParameter, decl))
					return;

				AddIssue(new CodeIssue(decl.NameToken, ctx.TranslateString("Type parameter is never used")) { IssueMarker = IssueMarker.GrayOut });
			}
		}
	}
}
