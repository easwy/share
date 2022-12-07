﻿// 
// ConvertAsToCastTests.cs
//  
// Author:
//       Mansheng Yang <lightyang0@gmail.com>
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
using NUnit.Framework;
using ICSharpCode.NRefactory.CSharp.Refactoring;

namespace ICSharpCode.NRefactory.CSharp.CodeActions
{
	[TestFixture]
	public class ConvertAsToCastTests : ContextActionTestBase
	{
		[Test]
		public void Test ()
		{
			Test<ConvertAsToCastAction> (@"
using System;
class TestClass
{
	void Test (object a)
	{
		var b = a $as Exception;
	}
}", @"
using System;
class TestClass
{
	void Test (object a)
	{
		var b = (Exception)a;
	}
}");
		}

		[Test]
		public void TestRemoveParentheses ()
		{
			string input = @"
class TestClass {
	void TestMethod (object o)
	{
		var b = 1 + (o $as TestClass);
	}
}";
			string output = @"
class TestClass {
	void TestMethod (object o)
	{
		var b = 1 + (TestClass)o;
	}
}";
			Test<ConvertAsToCastAction> (input, output);
		}

		[Test]
		public void TestInsertParentheses ()
		{
			string input = @"
class TestClass {
	void TestMethod (object o)
	{
		var b = 1 + o $as TestClass;
	}
}";
			string output = @"
class TestClass {
	void TestMethod (object o)
	{
		var b = (TestClass)(1 + o);
	}
}";
			Test<ConvertAsToCastAction> (input, output);
		}
	}
}
