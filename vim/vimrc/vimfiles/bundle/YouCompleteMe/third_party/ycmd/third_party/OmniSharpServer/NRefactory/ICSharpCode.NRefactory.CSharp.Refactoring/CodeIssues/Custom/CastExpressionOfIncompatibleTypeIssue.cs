﻿// 
// CastExpressionOfIncompatibleTypeIssue.cs
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

using System.Collections.Generic;
using ICSharpCode.NRefactory.TypeSystem;
using ICSharpCode.NRefactory.CSharp.Resolver;
using ICSharpCode.NRefactory.Semantics;
using ICSharpCode.NRefactory.Refactoring;

namespace ICSharpCode.NRefactory.CSharp.Refactoring
{
	[IssueDescription("Type cast expression of incompatible type",
		Description = "Type cast expression of incompatible type",
		Category = IssueCategories.CodeQualityIssues,
		Severity = Severity.Warning)]
	public class CastExpressionOfIncompatibleTypeIssue : GatherVisitorCodeIssueProvider
	{
		protected override IGatherVisitor CreateVisitor(BaseRefactoringContext context)
		{
			return new GatherVisitor(context);
		}

		class GatherVisitor : GatherVisitorBase<CastExpressionOfIncompatibleTypeIssue>
		{
			readonly CSharpConversions conversion;

			public GatherVisitor(BaseRefactoringContext ctx)
				: base(ctx)
			{
				conversion = new CSharpConversions(ctx.Compilation);
			}

			public override void VisitCastExpression(CastExpression castExpression)
			{
				base.VisitCastExpression(castExpression);

				VisitTypeCastExpression(castExpression, ctx.Resolve(castExpression.Expression).Type,
					ctx.ResolveType(castExpression.Type));
			}

			public override void VisitAsExpression(AsExpression asExpression)
			{
				base.VisitAsExpression(asExpression);

				VisitTypeCastExpression(asExpression, ctx.Resolve(asExpression.Expression).Type,
					ctx.ResolveType(asExpression.Type));
			}

			void VisitTypeCastExpression(Expression expression, IType exprType, IType castToType)
			{
				if (exprType.Kind == TypeKind.Unknown || castToType.Kind == TypeKind.Unknown || castToType.Kind == TypeKind.TypeParameter)
					return;
				var foundConversion = conversion.ExplicitConversion(exprType, castToType);
				if (foundConversion == Conversion.None)
					AddIssue(new CodeIssue(expression, ctx.TranslateString("Type cast expression of incompatible type")));
			}
		}
	}
}
