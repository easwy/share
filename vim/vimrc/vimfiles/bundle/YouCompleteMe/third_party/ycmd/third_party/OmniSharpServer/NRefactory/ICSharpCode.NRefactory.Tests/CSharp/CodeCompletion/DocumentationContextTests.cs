//
// DocumentationContextTests.cs
//
// Author:
//       Mike Krüger <mkrueger@xamarin.com>
//
// Copyright (c) 2012 Xamarin Inc. (http://xamarin.com)
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

namespace ICSharpCode.NRefactory.CSharp.CodeCompletion
{
	[TestFixture]
	public class DocumentationContextTests
	{
		[Test]
		public void TestClosingTag()
		{
			CodeCompletionBugTests.CombinedProviderTest(
@"using System;

public class Test
{
	///<summary>Foo$<$
	void TestFoo()
	{
	}
}
", provider => {
				Assert.IsNotNull(provider.Find("/summary>"));
			});
		}

		[Test]
		public void TestClosingTagMultiLine()
		{
			CodeCompletionBugTests.CombinedProviderTest(
				@"using System;

public class Test
{
	///<summary>
	///Foo
	///$<$
	void TestFoo()
	{
	}
}
", provider => {
				Assert.IsNotNull(provider.Find("/summary>"));
			});
		}

		/// <summary>
		/// Bug 9998 - Doc comments completion offers </para> as end tag for <param>
		/// </summary>
		[Test]
		public void TestBug9998()
		{
			CodeCompletionBugTests.CombinedProviderTest(
				@"using System;

public class Test
{
		/// <summary>
		/// </summary>
		/// <param name=""args""> $<$
		public static void Main(string[] args)
		{
	
		}
}
", provider => {
				Assert.IsNotNull(provider.Find("/param>"));
			});
		}
	}
}

