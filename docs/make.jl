using PovertyAndInequalityMeasures
using Documenter

makedocs(;
    modules=[PovertyAndInequalityMeasures],
    authors="Graham Stark",
    repo="https://github.com/grahamstark/PovertyAndInequalityMeasures.jl/blob/{commit}{path}#L{line}",
    sitename="PovertyAndInequalityMeasures.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://grahamstark.github.io/PovertyAndInequalityMeasures.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/grahamstark/PovertyAndInequalityMeasures.jl",
)
