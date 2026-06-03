using Documenter
using MorkServer

DocMeta.setdocmeta!(MorkServer, :DocTestSetup, :(using MorkServer); recursive=true)

makedocs(;
    modules=[MorkServer],
    authors="CognitiveSubstrates AI",
    repo=Remotes.GitHub("CognitiveSubstratesAI", "MorkServer"),
    sitename="MorkServer.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cognitivesubstratesai.github.io/MorkServer/stable/",
        edit_link="main",
        assets=String[]
    ),
    pages=["Home" => "index.md"],
    warnonly=true
)

deploydocs(; repo="github.com/CognitiveSubstratesAI/MorkServer", devbranch="main")
