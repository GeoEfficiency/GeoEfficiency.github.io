#**************************************************************************************
# make.jl
# =============== part of the GeoEfficiency.jl package.
#
# script for building documentaion of the GeoEfficiency.jl package.
#
#**************************************************************************************

using  Documenter,  DocumenterMarkdown #, DocumenterLaTeX
using GeoEfficiency

const PAGES = Any[
    #"Home" => "index.md",
    "Home" => "index.md",
    "Manual" => [
		"manual/GeoEfficiency.md",
        "manual/Error.md",
        "manual/Input_Console.md",
        "manual/Physics_Model.md",
        "manual/Input_Batch.md",
        "manual/Calculations.md",
        "manual/Output_Interface.md",
     ],
    "Index" => "list.md",
]

const formats = Any[
    Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://DrKrar.github.io/GeoEfficiency.jl/docs/build/dev/",
        
    ), 
    
]

isdefined(@__MODULE__,:DocumenterMarkdown) &&  push!(formats, Markdown())

if "pdf" in ARGS
    Sys.iswindows() ?   push!(formats, LaTeX(platform = "native")) : 
                        push!(formats, LaTeX(platform = "docker"))
end

makedocs(
    format  = formats,
    modules = [GeoEfficiency],
    clean   = "clean" in ARGS,
    doctest = "doctest" in ARGS,
    sitename= "GeoEfficiency.jl",
    authors = "Mohamed E. Krar",
    pages   = PAGES,
    assets  = ["assets/custom.css"],
)

mktempdir() do tmp
    # Hide the PDF from html-deploydocs
    build = joinpath(@__DIR__, "build")
    files = readdir(build)
    idx = findfirst(f -> startswith(f, "GeoEfficiency.jl") && endswith(f, ".pdf"), files)
    pdf = idx === nothing ? nothing : joinpath(build, files[idx])
    if pdf !== nothing
        pdf = mv(pdf, joinpath(tmp, basename(pdf)))
    end
    # Deploy HTML pages
    @info "Deploying HTML pages"
    deploydocs(
        repo = "github.com/DrKrar/GeoEfficiency.jl.git",
        versions = ["stable" => "v^", "v#.#", "dev" => "dev"],
    )
    if isdefined(@__MODULE__,:DocumenterMarkdown)
        # Deploy Markup pages
        @info "Deploying MarkUp pages"
        deploydocs(
            repo = "github.com/DrKrar/GeoEfficiency.jl.git",
            target = "build/Mrk",
            versions = ["stable" => "v^", "v#.#", "dev" => "dev"],
        )
    end #if
    # Put back PDF into docs/build/pdf
    mkpath(joinpath(build, "pdf"))
    if pdf !== nothing
        pdf = mv(pdf, joinpath(build, "pdf", basename(pdf)))
    end
    # Deploy PDF
    @info "Deploying PDF"
    deploydocs(
        repo = "github.com/DrKrar/GeoEfficiency.jl.git",
        target = "build/pdf",
        branch = "gh-pages-pdf",
        forcepush = true,
    )
end