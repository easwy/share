//
// RedundantToStringCallForValueTypesForValueTypesIssue.cs
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
using ICSharpCode.NRefactory.CSharp.CodeActions;
using ICSharpCode.NRefactory.CSharp.Refactoring;

namespace ICSharpCode.NRefactory.CSharp.CodeIssues
{
	[TestFixture]
	public class RedundantToStringCallForValueTypesIssueTests : InspectionActionTestBase
	{

		[Test]
		public void ConcatenationOperator ()
		{
			var input = @"
class Foo
{
	void Bar (int i)
	{
		string s = """" + i.ToString() + """" + i.ToString();
	}
}";

			TestRefactoringContext context;
			var issues = GetIssues (new RedundantToStringCallForValueTypesIssue (), input, out context);
			Assert.AreEqual (2, issues.Count);
			CheckFix (context, issues, @"
class Foo
{
	void Bar (int i)
	{
		string s = """" + i + """" + i;
	}
}");
		}

		[Test]
		public void TestReferenceTypes ()
		{
			TestWrongContext<RedundantToStringCallForValueTypesIssue>(@"
class Foo
{
	void Bar (object i)
	{
		string s = """" + i.ToString() + """" + i.ToString();
	}
}");
		}

		[Test]
		public void ConcatenationOperatorWithToStringAsOnlyString ()
		{
			var input = @"
class Foo
{
	void Bar (int i)
	{
		string s = i.ToString() + i + i + i + 1.3;
	}
}";

			TestRefactoringContext context;
			var issues = GetIssues (new RedundantToStringCallForValueTypesIssue (), input, out context);
			Assert.AreEqual (0, issues.Count);
		}

		[Test]
		public void IgnoresCallsToIFormattableToString ()
		{
			var input = @"
class Foo
{
	void Bar (System.DateTime dt)
	{
		string s = dt.ToString("""", CultureInfo.InvariantCulture) + string.Empty;
	}
}";

			TestRefactoringContext context;
			var issues = GetIssues (new RedundantToStringCallForValueTypesIssue (), input, out context);
			Assert.AreEqual (0, issues.Count);
		}

		[Test]
		public void FormatStringTests ()
		{
			var input = @"
class Foo
{
	void Bar (int i)
	{
		string s = string.Format(""{0}"", i.ToString());
	}
}";

			TestRefactoringContext context;
			var issues = GetIssues (new RedundantToStringCallForValueTypesIssue (), input, out context);
			Assert.AreEqual (1, issues.Count);
			CheckFix (context, issues, @"
class Foo
{
	void Bar (int i)
	{
		string s = string.Format (""{0}"", i);
	}
}");
		}

		[Test]
		public void HandlesNonLiteralFormatParameter ()
		{
			var input = @"
class Foo
{
	void Bar (int i)
	{
		string format = ""{0}"";
		string s = string.Format(format, i.ToString());
	}
}";

			TestRefactoringContext context;
			var issues = GetIssues (new RedundantToStringCallForValueTypesIssue (), input, out context);
			Assert.AreEqual (1, issues.Count);
			CheckFix (context, issues, @"
class Foo
{
	void Bar (int i)
	{
		string format = ""{0}"";
		string s = string.Format (format, i);
	}
}");
		}

		[Test]
		public void FormatStringWithNonObjectParameterTests ()
		{
			var input = @"
class Foo
{
	void Bar (int i)
	{
		string s = FakeFormat(""{0} {1}"", i.ToString(), i.ToString());
	}

	void FakeFormat(string format, string arg0, object arg1)
	{
	}
	void FakeFormat(string format, params object[] args)
	{
	}
}";

			TestRefactoringContext context;
			var issues = GetIssues (new RedundantToStringCallForValueTypesIssue (), input, out context);
			Assert.AreEqual (1, issues.Count);
			CheckFix (context, issues, @"
class Foo
{
	void Bar (int i)
	{
		string s = FakeFormat (""{0} {1}"", i.ToString (), i);
	}

	void FakeFormat(string format, string arg0, object arg1)
	{
	}
	void FakeFormat(string format, params object[] args)
	{
	}
}");
		}

		[Test]
		public void FormatMethodWithObjectParamsArray ()
		{
			var input = @"
class Foo
{
	void Bar (int i)
	{
		string s = FakeFormat(""{0} {1}"", i.ToString(), i.ToString());
	}

	void FakeFormat(string format, params object[] args)
	{
	}
}";

			TestRefactoringContext context;
			var issues = GetIssues (new RedundantToStringCallForValueTypesIssue (), input, out context);
			Assert.AreEqual (2, issues.Count);
			CheckFix (context, issues, @"
class Foo
{
	void Bar (int i)
	{
		string s = FakeFormat (""{0} {1}"", i, i);
	}

	void FakeFormat(string format, params object[] args)
	{
	}
}");
		}

		[Test]
		public void DetectsBlacklistedCalls ()
		{
			var input = @"
class Foo
{
	void Bar (int i)
	{
		var w = new System.IO.StringWriter ();
		w.Write (i.ToString());
		w.WriteLine (i.ToString());
	}
}";

			TestRefactoringContext context;
			var issues = GetIssues (new RedundantToStringCallForValueTypesIssue (), input, out context);
			Assert.AreEqual (2, issues.Count);
			CheckFix (context, issues, @"
class Foo
{
	void Bar (int i)
	{
		var w = new System.IO.StringWriter ();
		w.Write (i);
		w.WriteLine (i);
	}
}");
		}
	}
}

