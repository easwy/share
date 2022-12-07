﻿using Nancy;
using Nancy.ModelBinding;

namespace OmniSharp.ProjectManipulation.AddReference
{
    public class AddReferenceModule : NancyModule
    {
        public AddReferenceModule(AddReferenceHandler handler)
        {
            Post["AddReference", "/addreference"] = x =>
                {
                    var req = this.Bind<AddReferenceRequest>();
                    var res = handler.AddReference(req);
                    return Response.AsJson(res);
                };
        }
    }
}
