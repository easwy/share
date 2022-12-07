﻿// Copyright (c) 2010-2013 AlphaSierraPapa for the SharpDevelop Team
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
// to whom the Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

using System;
using System.Collections.Generic;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.CSharp.TypeSystem;

namespace ICSharpCode.NRefactory.TypeSystem
{
	public static class TypeSystemHelper
	{
		public static ICompilation CreateCompilation()
		{
			return CreateCompilation(new IUnresolvedFile[0]);
		}
		
		public static ICompilation CreateCompilation(params IUnresolvedTypeDefinition[] unresolvedTypeDefinitions)
		{
			var unresolvedFile = new CSharpUnresolvedFile();
			foreach (var typeDef in unresolvedTypeDefinitions)
				unresolvedFile.TopLevelTypeDefinitions.Add(typeDef);
			return CreateCompilation(unresolvedFile);
		}
		
		public static ICompilation CreateCompilation(params IUnresolvedFile[] unresolvedFiles)
		{
			var pc = new CSharpProjectContent().AddOrUpdateFiles(unresolvedFiles);
			pc = pc.AddAssemblyReferences(new [] { CecilLoaderTests.Mscorlib, CecilLoaderTests.SystemCore });
			return pc.CreateCompilation();
		}
		
		public static ITypeDefinition CreateCompilationAndResolve(IUnresolvedTypeDefinition unresolvedTypeDefinition)
		{
			var compilation = CreateCompilation(unresolvedTypeDefinition);
			return compilation.MainAssembly.GetTypeDefinition(unresolvedTypeDefinition.FullTypeName);
		}
		
		public static ICompilation CreateCompilationWithoutCorlib(params IUnresolvedTypeDefinition[] unresolvedTypeDefinitions)
		{
			var unresolvedFile = new CSharpUnresolvedFile();
			foreach (var typeDef in unresolvedTypeDefinitions)
				unresolvedFile.TopLevelTypeDefinitions.Add(typeDef);
			return CreateCompilation(unresolvedFile);
		}
		
		public static ICompilation CreateCompilationWithoutCorlib(params IUnresolvedFile[] unresolvedFiles)
		{
			var pc = new CSharpProjectContent().AddOrUpdateFiles(unresolvedFiles);
			return pc.CreateCompilation();
		}
		
		public static ITypeDefinition CreateCompilationWithoutCorlibAndResolve(IUnresolvedTypeDefinition unresolvedTypeDefinition)
		{
			var compilation = CreateCompilationWithoutCorlib(unresolvedTypeDefinition);
			return compilation.MainAssembly.GetTypeDefinition(unresolvedTypeDefinition.FullTypeName);
		}
	}
}
