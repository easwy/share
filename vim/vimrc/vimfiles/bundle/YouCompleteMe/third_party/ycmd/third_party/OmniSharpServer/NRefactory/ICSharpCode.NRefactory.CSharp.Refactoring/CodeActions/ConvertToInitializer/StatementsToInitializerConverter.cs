//
// StatementsToInitializerConverter.cs
//
// Author:
//       Simon Lindgren <simon.n.lindgren@gmail.com>
//
// Copyright (c) 2012 Simon Lindgren
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
using ICSharpCode.NRefactory.CSharp.Refactoring;
using System.Collections.Generic;
using ICSharpCode.NRefactory.TypeSystem;
using ICSharpCode.NRefactory.Semantics;
using System.Linq;
using ICSharpCode.NRefactory.CSharp.Resolver;
using System.Threading;
using System.Diagnostics;

namespace ICSharpCode.NRefactory.CSharp.Refactoring
{
	public class StatementsToInitializerConverter
	{
		IDictionary<AccessPath, Expression> accessPaths = new Dictionary<AccessPath, Expression>();
		IList<Comment> comments = new List<Comment>();
		AccessPath mainAccessPath;
		RefactoringContext context;

		public StatementsToInitializerConverter(RefactoringContext context)
		{
			this.context = context;
		}

		bool Initialize(AstNode targetNode)
		{
			var target = context.Resolve(targetNode);
			var targetInitializerPath = AccessPath.FromResolveResult(target);
			if (targetInitializerPath == null)
				return false;

			mainAccessPath = targetInitializerPath;
			return true;
		}

		public VariableInitializer ConvertToInitializer(VariableInitializer variableInitializer, ref IList<AstNode> statements)
		{
			if (variableInitializer == null)
				throw new ArgumentNullException("variableInitializer");
			if (statements == null)
				throw new ArgumentNullException("statements");

			if (!Initialize(variableInitializer))
				return null;
			accessPaths [mainAccessPath] = variableInitializer.Initializer.Clone();

			Convert(statements);
			statements = ReplacementNodeHelper.GetReplacedNodes(accessPaths [mainAccessPath]);
			return new VariableInitializer(mainAccessPath.RootName, accessPaths [mainAccessPath]);
		}

		public AssignmentExpression ConvertToInitializer(AssignmentExpression assignmentExpression, ref IList<AstNode> statements)
		{
			if (assignmentExpression == null)
				throw new ArgumentNullException("assignmentExpression");
			if (statements == null)
				throw new ArgumentNullException("statements");
			if (!(assignmentExpression.Right is ObjectCreateExpression))
				throw new ArgumentException("assignmentExpression.Right must be an ObjectCreateExpression", "assignmentExpression");

			if (!Initialize(assignmentExpression.Left))
				return null;
			accessPaths [mainAccessPath] = assignmentExpression.Right.Clone();

			Convert(statements);
			statements = ReplacementNodeHelper.GetReplacedNodes(accessPaths [mainAccessPath]);
			return new AssignmentExpression(new IdentifierExpression(mainAccessPath.RootName), accessPaths [mainAccessPath]);
		}

		void Convert(IList<AstNode> originalStatements)
		{
			foreach (var node in originalStatements) {
				var comment = node as Comment;
				if (comment != null) {
					comments.Add((Comment)ReplacementNodeHelper.CloneWithReplacementAnnotation(comment, node));
					continue;
				}
				var success = TryHandleInitializer(node);
				if (success) {
					continue;
				}
				var expressionStatement = node as ExpressionStatement;
				if (expressionStatement == null)
					break;
				success = TryHandleAssignmentExpression(expressionStatement);
				if (success) {
					continue;
				}
				success = TryHandleAddCall(expressionStatement);
				if (success) {
					continue;
				}
				break;
			}
		}

		bool TryHandleInitializer(AstNode node)
		{
			VariableInitializer variableInitializer;
			var variableDeclarationStatement = node as VariableDeclarationStatement;
			if (variableDeclarationStatement == null) {
				return false;
			}
			variableInitializer = variableDeclarationStatement.Variables.FirstOrNullObject();
			if (variableInitializer.IsNull || variableInitializer.Initializer.IsNull)
				return false;
			var sourceResolveResult = context.Resolve(variableInitializer.Initializer) as LocalResolveResult;
			if (HasDependency(variableInitializer.Initializer) && !CanReplaceDependent(sourceResolveResult))
				return false;
			var targetResolveResult = context.Resolve(variableInitializer) as LocalResolveResult;
			if (targetResolveResult == null)
				return false;
			AddNewVariable(targetResolveResult.Variable, variableInitializer.Initializer, node);
			return true;
		}

		bool TryHandleAddCall(ExpressionStatement expressionStatement)
		{
			var invocationExpression = expressionStatement.Expression as InvocationExpression;
			if (invocationExpression == null)
				return false;
			var invocationResolveResult = context.Resolve(invocationExpression) as InvocationResolveResult;
			if (invocationResolveResult == null)
				return false;
			if (invocationResolveResult.Member.Name != "Add")
				return false;
			var targetResult = invocationResolveResult.TargetResult;
			if (targetResult is MemberResolveResult)
				return false;

			var tuple = new ArrayInitializerExpression();
			foreach (var argument in invocationExpression.Arguments) {
				var argumentLocalResolveResult = context.Resolve(argument) as LocalResolveResult;
				if (argumentLocalResolveResult != null) {
					var initializerPath = AccessPath.FromResolveResult(argumentLocalResolveResult);
					if (initializerPath == null || !accessPaths.ContainsKey(initializerPath))
						return false;
					// Add a clone, since we do not yet know if this is where the initializer will be used
					var initializerClone = accessPaths[initializerPath].Clone();
					tuple.Elements.Add(initializerClone);
				} else {
					tuple.Elements.Add(argument.Clone());
				}
			}
			ReplacementNodeHelper.AddReplacementAnnotation(tuple, expressionStatement);

			var targetPath = AccessPath.FromResolveResult(targetResult);
			if (targetPath == null || !accessPaths.ContainsKey(targetPath))
				return false;
			InsertImplicitInitializersForPath(targetPath);
			var targetInitializer = accessPaths [targetPath];
			AddToInitializer(targetInitializer, tuple);
			return true;
		}

		bool TryHandleAssignmentExpression(ExpressionStatement expressionStatement)
		{
			var assignmentExpression = expressionStatement.Expression as AssignmentExpression;
			if (assignmentExpression == null || assignmentExpression.Operator != AssignmentOperatorType.Assign)
				return false;
			var resolveResult = context.Resolve(assignmentExpression.Right);
			if (HasDependency(assignmentExpression.Right) && !CanReplaceDependent(resolveResult))
				return false;
			var success = PushAssignment(assignmentExpression.Left, assignmentExpression.Right, expressionStatement);
			return success;
		}

		bool CanReplaceDependent(ResolveResult resolveResult)
		{
			return resolveResult is LocalResolveResult;
		}

		void AddNewVariable(IVariable variable, Expression initializer, AstNode node)
		{
			var variablePath = new AccessPath(variable);
			var rightResolveResult = context.Resolve(initializer) as LocalResolveResult;
			if (rightResolveResult != null) {
				var rightPath = AccessPath.FromResolveResult(rightResolveResult);
				if (rightPath != null && accessPaths.ContainsKey(rightPath)) {
					var rightInitializer = accessPaths [rightPath];
					ReplacementNodeHelper.AddReplacementAnnotation(rightInitializer, node);
					accessPaths.Remove(rightPath);
					accessPaths [variablePath] = rightInitializer;
					if (rightPath == mainAccessPath) {
						mainAccessPath = variablePath;
					}
				}
			} else {
				accessPaths [variablePath] = ReplacementNodeHelper.CloneWithReplacementAnnotation(initializer, node);
			}
		}

		void AddOldAnnotationsToInitializer(AccessPath targetPath, IAnnotatable initializer)
		{
			if (targetPath != null) {
				if (accessPaths.ContainsKey(targetPath)) {
					foreach (var astNode in ReplacementNodeHelper.GetAllReplacementAnnotations(accessPaths[targetPath])) {
						initializer.AddAnnotation(astNode);
					}
				}
			}
		}

		bool PushAssignment(Expression left, Expression right, AstNode node)
		{
			var rightResolveResult = context.Resolve(right) as LocalResolveResult;
			var leftResolveResult = context.Resolve(left);
			Expression initializer;
			if (rightResolveResult != null) {
				var rightPath = AccessPath.FromResolveResult(rightResolveResult);
				if (accessPaths.ContainsKey(rightPath)) {
					initializer = accessPaths [rightPath];
				} else {
					initializer = right.Clone();
				}
			} else {
				initializer = right.Clone();
			}
			var leftPath = AccessPath.FromResolveResult(leftResolveResult);
			if (leftPath == null) {
				return false;
			}

			// Move replacement annotations over, in case this is the second assignment
			// to the same variable/member.
			AddOldAnnotationsToInitializer(leftPath, initializer);

			if (leftPath.PartCount == 1) {
				ReplacementNodeHelper.AddReplacementAnnotation(initializer, node);
				accessPaths [leftPath] = initializer;
				return true;
			}
			if (!(leftResolveResult is MemberResolveResult))
				return false;

			Debug.Assert(leftPath.PartCount > 1, "No top level assignment should get here.");

			var parentKey = leftPath.GetParentPath();
			var member = leftPath.MemberPath.Last();

			var success = InsertImplicitInitializersForPath(parentKey);
			if (!success)
				return false;

			var parentInitializer = accessPaths [parentKey];
			AddToInitializer(parentInitializer, comments.ToArray());
			comments.Clear();

			AddToInitializer(parentInitializer, new NamedExpression(member.Name, initializer));
			ReplacementNodeHelper.AddReplacementAnnotation(initializer, node);
			accessPaths [leftPath] = initializer;
			return true;
		}

		static void AddNodesToInitializer(Expression initializer, params AstNode[] nodes)
		{
			foreach (var node in nodes) {
				if (node is Expression) {
					initializer.AddChild((Expression)node, Roles.Expression);
				} else if (node is Comment) {
					initializer.AddChild((Comment)node, Roles.Comment);
				}
			}
		}

		void AddToInitializer(Expression initializer, params AstNode[] nodes)
		{
			if (initializer is ArrayInitializerExpression) {
				var arrayInitializerExpression = (ArrayInitializerExpression)initializer;
				AddNodesToInitializer(arrayInitializerExpression, nodes);
			} else if (initializer is ObjectCreateExpression) {
				var objectCreateExpression = (ObjectCreateExpression)initializer;

				if (objectCreateExpression.Initializer.IsNull)
					objectCreateExpression.Initializer = new ArrayInitializerExpression();

				AddNodesToInitializer(objectCreateExpression.Initializer, nodes);
			}
		}

		bool HasDependency(Expression expression)
		{
			var referenceFinder = new FindReferences();
			return HasDependency(referenceFinder, expression);
		}

		bool HasDependency(FindReferences referenceFinder, Expression expression)
		{
			if (HasDependencyCheck(referenceFinder, expression))
				return true;
			var queue = new Queue<ResolveResult>();
			queue.Enqueue(context.Resolve(expression));
			do {
				var result = queue.Dequeue();
				if (result is LocalResolveResult && HasDependencyCheck(referenceFinder, (LocalResolveResult)result)) {
					return true;
				}
				foreach (var childResult in result.GetChildResults()) {
					queue.Enqueue(childResult);
				}
			} while (queue.Count > 0);
			return false;
		}

		bool HasDependencyCheck(FindReferences referenceFinder, LocalResolveResult localResolveResult)
		{
			bool result = false;
			referenceFinder.FindLocalReferences(localResolveResult.Variable, context.UnresolvedFile,
			                                    (SyntaxTree)context.RootNode, context.Compilation,
			                                    (node, resolveResult) => {
				result |= VariableHasBeenConverted(localResolveResult.Variable);
			}, CancellationToken.None);
			return result;
		}

		bool HasDependencyCheck(FindReferences referenceFinder, Expression expression)
		{
			var memberReferences = from exp in expression.DescendantsAndSelf
				let memberReference = exp as MemberReferenceExpression
				where memberReference != null
				select memberReference;
			foreach (var memberReference in memberReferences) {
				var resolveResult = context.Resolve(memberReference) as MemberResolveResult;
				if (resolveResult == null)
					continue;
				var initializerPath = AccessPath.FromResolveResult(resolveResult);
				if (initializerPath != null && accessPaths.ContainsKey(initializerPath))
					return true;
			}
			return false;
		}

		bool VariableHasBeenConverted(IVariable variable)
		{
			if (variable == null)
				throw new ArgumentNullException("variable");
			return accessPaths.Any(item => item.Key != null && item.Key.VariableRoot != null && item.Key.VariableRoot.Equals(variable));
		}

		bool InsertImplicitInitializersForPath(AccessPath path)
		{
			if (accessPaths.ContainsKey(path))
				return true;

			if (path.MemberPath.Count == 0)
				return false;
			var parentPath = path.GetParentPath();
			var success = InsertImplicitInitializersForPath(parentPath);
			if (!success)
				return false;

			var parentInitializer = accessPaths [parentPath];
			var initializer = new ArrayInitializerExpression();
			var namedExpression = new NamedExpression(path.MemberPath [path.MemberPath.Count - 1].Name, initializer);
			AddToInitializer(parentInitializer, namedExpression);
			accessPaths [path] = initializer;
			return true;
		}

	}

	class ReplacementNodeAnnotation
	{
		public AstNode ReplacedNode { get; set; }
	}

	class ReplacementNodeHelper
	{
		public static void AddReplacementAnnotation(AstNode node, AstNode replacedNode)
		{
			node.AddAnnotation(new ReplacementNodeAnnotation {
				ReplacedNode = replacedNode
			});
		}

		public static AstNode CloneWithReplacementAnnotation(AstNode node, AstNode replacedNode)
		{
			var newNode = node.Clone();
			AddReplacementAnnotation(newNode, replacedNode);
			return newNode;
		}

		public static Expression CloneWithReplacementAnnotation(Expression expression, AstNode replacedNode)
		{
			var newExpression = expression.Clone();
			AddReplacementAnnotation(newExpression, replacedNode);
			return newExpression;
		}

		public static IEnumerable<ReplacementNodeAnnotation> GetAllReplacementAnnotations(AstNode node)
		{
			return
				from n in node.DescendantsAndSelf
				from replacementAnnotation in n.Annotations.OfType<ReplacementNodeAnnotation>()
				select replacementAnnotation;
		}

		public static IList<AstNode> GetReplacedNodes(AstNode expression)
		{
			return GetAllReplacementAnnotations(expression)
				.Select(a => a.ReplacedNode)
				.ToList();
		}
	}
}
