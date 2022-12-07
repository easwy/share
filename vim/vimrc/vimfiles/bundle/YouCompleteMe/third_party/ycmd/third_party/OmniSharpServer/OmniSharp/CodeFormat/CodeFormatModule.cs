﻿using Nancy;
using Nancy.ModelBinding;

namespace OmniSharp.CodeFormat
{
    public class CodeFormatModule : NancyModule
    {
        public CodeFormatModule(CodeFormatHandler codeFormatHandler)
        {
            Post["CodeFormat", "/codeformat"] = x =>
                {
                    var request = this.Bind<CodeFormatRequest>();
                    return Response.AsJson(codeFormatHandler.Format(request));
                };
        }
    }
}
