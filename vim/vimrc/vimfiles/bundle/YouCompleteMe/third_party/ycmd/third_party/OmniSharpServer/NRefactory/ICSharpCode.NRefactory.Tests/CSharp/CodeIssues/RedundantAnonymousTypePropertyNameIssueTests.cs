//
// RedundantAnonymousTypePropertyNameIssueTests.cs
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
using ICSharpCode.NRefactory.CSharp.Refactoring;
using NUnit.Framework;

namespace ICSharpCode.NRefactory.CSharp.CodeIssues
{
	[TestFixture]
	public class RedundantAnonymousTypePropertyNameIssueTests : InspectionActionTestBase
	{
		[Test]
		public void TestSimpleCase()
		{
			Test<RedundantAnonymousTypePropertyNameIssue>(@"
class FooBar
{
	public int Foo;
	public int Bar;
}
class TestClass
{
	public void Test(FooBar f)
	{
		var n = new { Foo = f.Foo, b = 12 };
	}
}", @"
class FooBar
{
	public int Foo;
	public int Bar;
}
class TestClass
{
	public void Test(FooBar f)
	{
		var n = new { f.Foo, b = 12 };
	}
}");
		}

		[Test]
		public void TestDisable()
		{
			TestWrongContext<RedundantAnonymousTypePropertyNameIssue>(@"
class FooBar
{
	public int Foo;
	public int Bar;
}
class TestClass
{
	public void Test(FooBar f)
	{
		// ReSharper disable once RedundantAnonymousTypePropertyName
		var n = new { Foo = f.Foo, b = 12 };
	}
}");
		}


	}
}

