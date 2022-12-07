//
// UnusedLabelIssueTests.cs
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
	public class UnusedLabelIssueTests : InspectionActionTestBase
	{
		[Test]
		public void TestUnusedLabelInMethod ()
		{
			Test<UnusedLabelIssue>(@"
class Foo
{
	void Test()
	{
		bar: ;
	}
}
", @"
class Foo
{
	void Test()
	{
		;
	}
}
");
		}

		[Test]
		public void TestInvalidCase ()
		{
			TestWrongContext<UnusedLabelIssue>(@"
class Foo
{
	void Test()
	{
		bar:
		goto bar;
	}
}
");
		}

		[Test]
		public void TestDisable ()
		{
			TestWrongContext<UnusedLabelIssue>(@"
class Foo
{
	void Test()
	{
		// ReSharper disable once UnusedLabel
		bar: ;
	}
}
");
		}

		[Test]
		public void TestPragmaDisable ()
		{
			TestWrongContext<UnusedLabelIssue>(@"
class Foo
{
	void Test()
	{
#pragma warning disable 164
		bar: ;
#pragma warning restore 164
	}
}
");
		}
	}
}

