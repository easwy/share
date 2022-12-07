﻿// 
// UseStringFormatTests.cs
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

namespace ICSharpCode.NRefactory.CSharp.CodeActions
{
	[TestFixture]
	public class UseStringFormatTests : ContextActionTestBase
	{
		[Test]
		public void Test ()
		{
			Test<UseStringFormatAction> (@"
class TestClass
{
	void TestMethod ()
	{
		string str = 1 + $2 + ""test"" + 1 + ""test"" + 1.1;
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
		string str = string.Format (""{0}test{1}test{2}"", 1 + 2, 1, 1.1);
	}
}");
		}

		[Test]
		public void TestVerbatim ()
		{
			Test<UseStringFormatAction> (@"
class TestClass
{
	void TestMethod ()
	{
		string str = $@""
test "" + 1;
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
		string str = string.Format (@""
test {0}"", 1);
	}
}");
		}

		[Test]
		public void TestRepeatedObject ()
		{
			Test<UseStringFormatAction> (@"
class TestClass
{
	void TestMethod ()
	{
		int i = 0;
		string str = $""test"" + i + ""test"" + i;
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
		int i = 0;
		string str = string.Format (""test{0}test{0}"", i);
	}
}");
		}

        [Test]
        public void TestFormatString ()
        {
            Test<UseStringFormatAction>(@"
class TestClass
{
	void TestMethod ()
	{
		int i = 42;
		string res = $""A test number: "" + i.ToString(""N2"");
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
		int i = 42;
		string res = string.Format (""A test number: {0:N2}"", i);
	}
}");
        }

        [Test]
        public void TestFormatBracesRegular()
        {
            Test<UseStringFormatAction>(@"
class TestClass
{
	void TestMethod ()
	{
		int i = 42;
		string res = $""A test number: {"" + i + ""}"";
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
		int i = 42;
		string res = string.Format (""A test number: {{{0}}}"", i);
	}
}");
        }

        /*
        [Test]
        public void TestFormatBracesWithFormat()
        {
            Test<UseStringFormatAction>(@"
class TestClass
{
	void TestMethod ()
	{
		int i = 42;
		string res = $""A test number: {"" + i.ToString(""N2"") + ""}"";
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
		int i = 42;
		string res = string.Format (""A test number: {0}{1:N2}{2}"", '{', i, '}');
	}
}");
        }
         */

        [Test]
        public void TestUnnecessaryStringFormat()
        {
            Test<UseStringFormatAction>(@"
class TestClass
{
	void TestMethod ()
	{
		string res = $""String 1"" + ""String 2"";
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
		string res = ""String 1String 2"";
	}
}");
        }

        [Test]
        public void TestUnnecessaryToString()
        {
            Test<UseStringFormatAction>(@"
class TestClass
{
	void TestMethod ()
	{
        int i = 42;
		string res = $""String 1"" + i.ToString();
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
        int i = 42;
		string res = string.Format (""String 1{0}"", i);
	}
}");
        }
		
		[Test]
		public void EscapeBraces ()
		{
			Test<UseStringFormatAction> (@"
class TestClass
{
	void TestMethod ()
	{
		int i = 0;
		string str = $""{"" + i + ""}"";
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
		int i = 0;
		string str = string.Format (""{{{0}}}"", i);
	}
}");
		}
		
		[Test]
		public void QuotesMixedVerbatim ()
		{
			Test<UseStringFormatAction> (@"
class TestClass
{
	void TestMethod ()
	{
		int i = 0;
		string str = $""\"""" + i + @"""""""";
	}
}", @"
class TestClass
{
	void TestMethod ()
	{
		int i = 0;
		string str = string.Format (@""""""{0}"""""", i);
	}
}");
		}
	}
}
