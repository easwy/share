﻿// 
// HelpService.cs
//  
// Author:
//       Michael Hutchinson <mhutchinson@novell.com>
// 
// Copyright (c) 2010 Novell, Inc. (http://www.novell.com)
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

//using MonoDevelop.Core;
//using Mono.Addins;
//using MonoDevelop.Projects.Extensions;
using System.Collections.Generic;
using System.Text;
using System.Xml;
using ICSharpCode.NRefactory.Documentation;
using ICSharpCode.NRefactory.TypeSystem;

namespace MonoDevelop.Projects
{
    public static class HelpExtension
    {
        static void AppendTypeReference(StringBuilder result, ITypeReference type)
        {
            if (type is ArrayTypeReference)
            {
                var array = (ArrayTypeReference)type;
				
                AppendTypeReference(result, array.ElementType);
                result.Append("[");
                result.Append(new string(',', array.Dimensions));
                result.Append("]");
                return;
            }

            if (type is PointerTypeReference)
            {
                var ptr = (PointerTypeReference)type;
                AppendTypeReference(result, ptr.ElementType);
                result.Append("*");
                return;
            }

            if (type is IType)
                result.Append(((IType)type).FullName);
        }


        static void AppendHelpParameterList(StringBuilder result, IList<IParameter> parameters)
        {
            result.Append('(');
            if (parameters != null)
            {
                for (int i = 0; i < parameters.Count; i++)
                {
                    if (i > 0)
                        result.Append(',');
                    var p = parameters[i];
                    if (p == null)
                        continue;
                    if (p.IsRef || p.IsOut)
                        result.Append("&");
                    AppendTypeReference(result, p.Type.ToTypeReference());
                }
            }
            result.Append(')');
        }

        static void AppendHelpParameterList(StringBuilder result, IList<IUnresolvedParameter> parameters)
        {
            result.Append('(');
            if (parameters != null)
            {
                for (int i = 0; i < parameters.Count; i++)
                {
                    if (i > 0)
                        result.Append(',');
                    var p = parameters[i];
                    if (p == null)
                        continue;
                    if (p.IsRef || p.IsOut)
                        result.Append("&");
                    AppendTypeReference(result, p.Type);
                }
            }
            result.Append(')');
        }

        static XmlNode FindMatch(IMethod method, XmlNodeList nodes)
        {
            foreach (XmlNode node in nodes)
            {
                XmlNodeList paramList = node.SelectNodes("Parameters/*");
                if (method.Parameters.Count == 0 && paramList.Count == 0)
                    return node;
                if (method.Parameters.Count != paramList.Count)
                    continue;

                /*				bool matched = true;
                                for (int i = 0; i < p.Count; i++) {
                                    if (p [i].ReturnType.FullName != paramList [i].Attributes ["Type"].Value) {
                                        matched = false;
                                        break;
                                    }
                                }
                                if (matched)*/
                return node;
            }
            return null;
        }

        public static XmlNode GetMonodocDocumentation(this IEntity member)
        {
			if (member.SymbolKind == SymbolKind.TypeDefinition)
            {
#pragma warning disable 612,618
                var helpXml = HelpService.HelpTree != null ? HelpService.HelpTree.GetHelpXml(member.GetIdString()) : null;
#pragma warning restore 612,618
                if (helpXml == null)
                    return null;
                return helpXml.SelectSingleNode("/Type/Docs");
            }

#pragma warning disable 612,618
            var declaringXml = HelpService.HelpTree != null && member.DeclaringTypeDefinition != null ? HelpService.HelpTree.GetHelpXml(member.DeclaringTypeDefinition.GetIdString()) : null;
#pragma warning restore 612,618
            if (declaringXml == null)
                return null;

			switch (member.SymbolKind)
            {
			case SymbolKind.Method:
                    {
                        var nodes = declaringXml.SelectNodes("/Type/Members/Member[@MemberName='" + member.Name + "']");
                        XmlNode node = nodes.Count == 1 ? nodes[0] : FindMatch((IMethod)member, nodes);
                        if (node != null)
                        {
                            System.Xml.XmlNode result = node.SelectSingleNode("Docs");
                            return result;
                        }
                        return null;
                    }
			case SymbolKind.Constructor:
                    {
                        var nodes = declaringXml.SelectNodes("/Type/Members/Member[@MemberName='.ctor']");
                        XmlNode node = nodes.Count == 1 ? nodes[0] : FindMatch((IMethod)member, nodes);
                        if (node != null)
                        {
                            System.Xml.XmlNode result = node.SelectSingleNode("Docs");
                            return result;
                        }
                        return null;
                    }
                default:
                    return declaringXml.SelectSingleNode("/Type/Members/Member[@MemberName='" + member.Name + "']/Docs");
            }
        }

    }
}
