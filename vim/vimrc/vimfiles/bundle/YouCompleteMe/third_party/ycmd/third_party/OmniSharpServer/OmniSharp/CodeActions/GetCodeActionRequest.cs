﻿using OmniSharp.Common;

namespace OmniSharp.CodeActions
{
    public class CodeActionRequest : Request
    {
        public int  CodeAction           { get; set; }
        public int? SelectionStartColumn { get; set; }
        public int? SelectionStartLine   { get; set; }
        public int? SelectionEndColumn   { get; set; }
        public int? SelectionEndLine     { get; set; }
    }
}
