//
// ExtensionMethodInvocationToStaticMethodInvocationTests.cs
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
using NUnit.Framework;

namespace ICSharpCode.NRefactory.CSharp.CodeActions
{
	[TestFixture]
	public class ExtensionMethodInvocationToStaticMethodInvocationTests : ContextActionTestBase
	{

		[Test]
		public void HandlesBasicCase()
		{
			Test<ExtensionMethodInvocationToStaticMethodInvocationAction>(@"
class A { }
static class B
{
	public static void Ext (this A a, int i);
}
class C
{
	void F()
	{
		A a = new A();
		a.$Ext (1);
	}
}", @"
class A { }
static class B
{
	public static void Ext (this A a, int i);
}
class C
{
	void F()
	{
		A a = new A();
		B.Ext (a, 1);
	}
}");
		}

		[Test]
		public void HandlesReturnValueUsage()
		{
			Test<ExtensionMethodInvocationToStaticMethodInvocationAction>(@"
class A { }
static class B
{
	public static bool Ext (this A a, int i)
	{
		return false;
	}
}
class C
{
	void F()
	{
		A a = new A();
		if (a.$Ext (1))
			return;
	}
}", @"
class A { }
static class B
{
	public static bool Ext (this A a, int i)
	{
		return false;
	}
}
class C
{
	void F()
	{
		A a = new A();
		if (B.Ext (a, 1))
			return;
	}
}");
		}

		[Test]
		public void IgnoresStaticMethodCalls()
		{
			TestWrongContext<ExtensionMethodInvocationToStaticMethodInvocationAction>(@"
class A { }
static class B
{
	public static void Ext (this A a);
}
class C
{
	void F()
	{
		B.Ext (a, 1);
	}
}");
		}

		[Test]
		public void IgnoresRegularMemberMethodCalls()
		{
			TestWrongContext<ExtensionMethodInvocationToStaticMethodInvocationAction>(@"
class A
{
	public void Ext (int i);
}
class C
{
	void F()
	{
		A a = new A();
		a.Ext (1);
	}
}");
		}
	}
}

