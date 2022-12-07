﻿using Nancy;

namespace OmniSharp.Build
{
    public class BuildModule : NancyModule
    {
        public BuildModule(BuildHandler buildHandler)
        {
            Post["/build"] = x => Response.AsJson(buildHandler.Build());
        }
    }
} 
