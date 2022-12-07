﻿// 
// CastExpressionOfIncompatibleTypeIssueTests.cs
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

using ICSharpCode.NRefactory.CSharp.Refactoring;
using NUnit.Framework;

namespace ICSharpCode.NRefactory.CSharp.CodeIssues
{
	[TestFixture]
	public class CastExpressionOfIncompatibleTypeIssueTests : InspectionActionTestBase
	{
		[Test]
		public void Test ()
		{
			var input = @"
class TestClass
{
	void TestMethod (int i)
	{
		var x = (string)i;
		var y = i as string;
	}
}";
			Test<CastExpressionOfIncompatibleTypeIssue> (input, 2);
		}

		[Test]
		public void TestCompatibleTypes ()
		{
			var input = @"
class TestClass
{
	void TestMethod ()
	{
		var x1 = (int)123;
		var x2 = (short)123;
		var x3 = (int)System.ConsoleKey.A;
	}
}";
			Test<CastExpressionOfIncompatibleTypeIssue> (input, 0);
		}
		
		[Test]
		public void UnknownIdentifierDoesNotCauseIncompatibleCastIssue ()
		{
			var input = @"
class TestClass
{
	void TestMethod ()
	{
		var x1 = unknown as string;
		var x2 = (string)unknown;
	}
}";

			Test<CastExpressionOfIncompatibleTypeIssue> (input, 0);
		}
		
		[Test]
		public void UnknownTargetTypeDoesNotCauseIncompatibleCastIssue ()
		{
			var input = @"
class TestClass
{
	void TestMethod (int p)
	{
		var x1 = (unknown)p;
		var x2 = p as unknown;
	}
}";

			Test<CastExpressionOfIncompatibleTypeIssue> (input, 0);
		}

		[Test]
		public void CheckTemplates ()
		{
			var input = @"
class TestClass
{
	void TestMethod<T> (TestClass t)
	{
		var o = t as T;
	}
}";

			Test<CastExpressionOfIncompatibleTypeIssue> (input, 0);
		}
	}
}
