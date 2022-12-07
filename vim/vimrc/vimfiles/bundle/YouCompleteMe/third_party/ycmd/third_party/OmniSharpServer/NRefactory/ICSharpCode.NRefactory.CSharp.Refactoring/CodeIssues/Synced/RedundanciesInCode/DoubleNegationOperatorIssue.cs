﻿// 
// DoubleNegationOperatorIssue.cs
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
using ICSharpCode.NRefactory.Refactoring;

namespace ICSharpCode.NRefactory.CSharp.Refactoring
{
	[IssueDescription ("Double negation operator",
						Description = "Double negation is meaningless.",
						Category = IssueCategories.RedundanciesInCode,
						Severity = Severity.Warning,
                        AnalysisDisableKeyword = "DoubleNegationOperator")]
    public class DoubleNegationOperatorIssue : GatherVisitorCodeIssueProvider
	{
		protected override IGatherVisitor CreateVisitor(BaseRefactoringContext context)
		{
			return new GatherVisitor(context);
		}

		class GatherVisitor : GatherVisitorBase<DoubleNegationOperatorIssue>
		{
			public GatherVisitor (BaseRefactoringContext ctx)
				: base (ctx)
			{
			}

			static Expression RemoveParentheses (Expression expr)
			{
				while (expr is ParenthesizedExpression)
					expr = ((ParenthesizedExpression) expr).Expression;
				return expr;
			}

			public override void VisitUnaryOperatorExpression (UnaryOperatorExpression unaryOperatorExpression)
			{
				base.VisitUnaryOperatorExpression (unaryOperatorExpression);

				if (unaryOperatorExpression.Operator != UnaryOperatorType.Not)
					return;

				var innerUnaryOperatorExpr = 
					RemoveParentheses (unaryOperatorExpression.Expression) as UnaryOperatorExpression;
				if (innerUnaryOperatorExpr == null || innerUnaryOperatorExpr.Operator != UnaryOperatorType.Not)
					return;

				var expression = RemoveParentheses (innerUnaryOperatorExpr.Expression);
				if (expression.IsNull)
					return;
				AddIssue(new CodeIssue(unaryOperatorExpression, ctx.TranslateString ("Double negation is redundant"), ctx.TranslateString ("Remove '!!'"),
					script => script.Replace (unaryOperatorExpression, expression.Clone ())));
			}
		}
	}
}
