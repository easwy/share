//
// ConvertIfStatementToConditionalTernaryExpressionActionTests.cs
//
// Author:
//       Mike Krüger <mkrueger@xamarin.com>
//
// Copyright (c) 2013 Xamarin Inc. (http://xamarin.com)
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
using NUnit.Framework;
using ICSharpCode.NRefactory.CSharp.Refactoring;

namespace ICSharpCode.NRefactory.CSharp.CodeActions
{
	[TestFixture]
	public class ConvertIfStatementToConditionalTernaryExpressionActionTests : ContextActionTestBase
	{
		[Test]
		public void TestAssignment ()
		{
			Test<ConvertIfStatementToConditionalTernaryExpressionAction> (@"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		$if (i > 0)
			a = 0;
		else {
			a = 1;
		}
	}
}", @"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		a = i > 0 ? 0 : 1;
	}
}");
		}

		[Test]
		public void TestAddAssignment ()
		{
			Test<ConvertIfStatementToConditionalTernaryExpressionAction> (@"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		$if (i > 0)
			a += 0;
		else {
			a += 1;
		}
	}
}", @"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		a += i > 0 ? 0 : 1;
	}
}");
		}

		[Test]
		public void TestIfElse ()
		{
			TestWrongContext<ConvertIfStatementToConditionalTernaryExpressionAction> (@"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		$if (i > 0)
			a = 0;
		else if (i < 5) {
			a = 1;
		} else {
			a = 2;
		}
	}
}");
		}

		[Test]
		public void MultipleStatementsInIf ()
		{
			TestWrongContext<ConvertIfStatementToConditionalTernaryExpressionAction> (@"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		$if (i > 0) {
			a = 0;
			a = 2;
		} else {
			a = 2;
		}
	}
}");
		}

		[Test]
		public void TestDifferentAssignmentOperator ()
		{

			TestWrongContext<ConvertIfStatementToConditionalTernaryExpressionAction> (@"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		$if (i > 0)
			a += 0;
		else {
			a -= 1;
		}
	}
}");
		}

		[Ignore("Are there any cases where this is needed ?")]
		[Test]
		public void TestInsertNecessaryParentheses ()
		{
			Test<ConvertIfStatementToConditionalTernaryExpressionAction> (@"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		int b;
		$if (i > 0)
			a = b = 0;
		else {
			a = 1;
		}
	}
}", @"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		int b;
		a = i > 0 ? (b = 0) : 1;
	}
}");
		}

		[Test]
		public void TestInvalidImplicitElse ()
		{

			TestWrongContext<ConvertIfStatementToConditionalTernaryExpressionAction> (@"
class TestClass
{
	void TestMethod (int i)
	{
		int a;
		$if (i > 0)
			a = 0;
		a = 1;
	}
}");
		}
	}
}

