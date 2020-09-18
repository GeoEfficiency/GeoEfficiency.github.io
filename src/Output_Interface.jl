#**************************************************************************************
# Output_Interface.jl
# =============== part of the GeoEfficiency.jl package.
#
# all the output of the package either to the console or to the csv files is handled here.
#
#**************************************************************************************

#------------------------- consts - globals - imports ----------------

using Compat
using Compat.DelimitedFiles 
import Compat: @info, @error

@compat isconst(@__MODULE__, :resultsFolder) || const resultsFolder = "results";
const resultdir	        = joinpath(dataDir, resultsFolder);	
const resultdir_pnt     = joinpath(resultdir, "Point");		
const resultdir_nonPnt  = joinpath(resultdir, "non-Point");	
global countDetectors = 1;


#------------------ checkResultsDirs ----------------------------------

"""# UnExported

	checkResultsDirs()

make sure that directories for saving the results are already exist or create 
them if necessary.

"""
function checkResultsDirs()
	mkpath(resultdir_pnt)
	mkpath(resultdir_nonPnt)
	return nothing
end
checkResultsDirs()


#--------------------------- calc ---------------------------------------

"""

	calc(detector::Detector = Detector(), aSource::Tuple{Point, Float64, Float64,} = source())

calculate and display on the `console` the `geometrical efficiency` of the 
detector `detector` for the tuple `aSource` describing the source.

**`Throw`** an Error if the source location is inappropriate.

**see also:** [`geoEff(::Detector, ::Tuple{Point, Float64, Float64})`](@ref)

!!! note
     if source description `aSource` alone or even both source description and detector `detect` 
     are missing, the method prompt the user to complete the missing data via the `console`.

"""
function calc(detector::RadiationDetector = RadiationDetector(), aSource::Tuple{Point, Real, Real} = source())
			   
	aPnt, srcRadius, srcLength = aSource
	printstyled("\n<$(countDetectors)> $(id(detector))", color=:yellow)
	println("\n - Source(", id(aPnt), ", srcRadius=",srcRadius, ", srcLength=", srcLength, ")")
    
	calculatedEff::Float64 = geoEff(detector, aPnt, srcRadius, srcLength)
	println("\n - The detector Geometrical Efficiency = ", calculatedEff)

	global countDetectors += 1
	printstyled(repeat(" =",36),"\n\n", color=:red)
	return nothing

end #function

#------------------------ calcN ------------------------------------

"""

    calcN()

calculate and display the `geometrical efficiency` repeatedly. 
Prompt the user to input a `detector` and a `source` from the `console`.
Prompt the user `repeatedly` until it exit (give a choice to use the same 
detector or a new detector).

"""
function calcN(	detector:: RadiationDetector = RadiationDetector())

	while (true)

		try	calc(detector) end
		
		res = input("""\n
    	I- To continue make a choice:
			> using the same detector Press 'd'|'D'
			> using a new detector Press 'n'|'N'\n
    	II- To quit just press return\n
			\n\tyour Choice: """, :red) |> lowercase;
		if res == "n"
            detector = RadiationDetector()

		elseif res == "d"
            continue

		else
			break

		end #if

	end #while
	print("\n\t"); @info("The 'calcN' had terminated, Thank you\n")
end #function

#---------------- writecsv_head -----------------------------

""" # unexported

	writecsv_head(filename::AbstractString, content, head=[])

Write `content` to the comma delimited values file `filename`. 
optionally with header `head`.

"""
function writecsv_head(filename::AbstractString, content, head=[])
	open(filename, "w") do io
		writedlm(io, head, ',')
		writedlm(io, content, ',')
	end #do
end #function


#---------------- batch() ----------------------------------

"""

    batch()

provide batch calculation of the `geometrical efficiency` based on the information provided 
by the **``CSV``** files by default located in **``$(dataDir)``**.

results are saved on a **``CSV``**  file(s) named after the detector(s). the **``CSV``**  file(s) 
by default found in **``$(resultdir)``**, also a log of the results are displayed on the `console`.

**for more information on batch refer to [`batchInfo`](@ref).**

"""
batch() = batch(read_batch_info()...)

"""

    batch(
		detector::Detector,
		srcHeights_array::Vector{S},
		srcRhos_array::Vector{S}=[0.0],
		srcRadii_array::Vector{S}=[0.0],
		srcLengths_array::Vector{S}=[0.0],
		ispoint::Bool=true
	) where S <: Real

provide batch calculation of the `geometrical efficiency` for the detector `detector`. 
results are saved on a **``CSV``**  file named after the detector. 
the **``CSV``**  file by default found in **``$(resultdir)``**. this method return the actual 
path to the **``CSV``** file. 
also a log of the results are displayed on the `console`.

*  `srcHeights_array`: list of source heights to feed to batch.
*  `srcRhos_array`: list of source off-axis distances to feed to batch. 
*  `srcRadii_array`: list of source radii to feed to batch.
*  `srcLengths_array`: list of source lengths to feed to batch.

A set of sources is constructed of every valid **combination** of parameter in the `srcRhos_array`,
`srcRadii_array` and `srcLengths_array` arrays with conjunction with `ispoint`.

!!! warning
    *  If `ispoint` is ``true`` the source type is a point source and the parameters 
       in `srcRadii_array` and `srcLengths_array` arrays is completely ignored.
    *  If `ispoint` is ``false`` the parameters in srcRhos_array is completely ignored.

"""
function batch(	detector::RadiationDetector,
				srcHeights_array::Vector{S},
				srcRhos_array::Vector{S}=[0.0],
				srcRadii_array::Vector{S}=[0.0],
				srcLengths_array::Vector{S}=[0.0],
				ispoint::Bool=true) where S <: Real
				
	return _batch(Val{ispoint},
				detector::RadiationDetector,
				srcHeights_array,
				srcRhos_array,
				srcRadii_array,
				srcLengths_array
				)[3]
end #function

"""

    batch( 
		detectors_array::Vector{<: Detector},
	    srcHeights_array::Vector{S},
	    srcRhos_array::Vector{S}=[0.0],
	    srcRadii_array::Vector{S}=[0.0],
	    srcLengths_array::Vector{S}=[0.0],
		ispoint::Bool=true
	) where S <: Real

**same as [`batch(::Detector, ...)`](@ref)** but accept a list of detectors `detectors_array`.
return a list of paths to the **``CSV``** of files (file for each detector) storing the results.

"""
function batch( detectors_array::Vector{T},
	       srcHeights_array::Vector{S},
	       srcRhos_array::Vector{S}=[0.0],
	       srcRadii_array::Vector{S}=[0.0],
	       srcLengths_array::Vector{S}=[0.0],
	       ispoint::Bool=true) where T <: RadiationDetector where S <: Real
	
	outpaths::Vector{String} = String[]
	for detector = detectors_array
		push!(outpaths ,  
			batch(detector,
					srcHeights_array,
					srcRhos_array,
					srcRadii_array,
					srcLengths_array,
					ispoint))

	end # detectors_array

	print("\n\t"); @info("The program terminated, Thank you >>>>\n")
	return outpaths

end #function

"""

    batch(
		detector_info_array::Matrix{S},
		srcHeights_array::Vector{S},
		srcRhos_array::Vector{S}=[0.0],
		srcRadii_array::Vector{S}=[0.0],
		srcLengths_array::Vector{S}=[0.0],
		ispoint::Bool=true
	) where S <: Real

**same as [`batch(::Vector{<: Detector},...)`](@ref)** but provide batch calculation of the 
`geometrical efficiency` for the detector in the `detector_info_array` after applying `getDetectors`.
return a list of paths to the **``CSV``** of files (file for each detector) storing the results.

"""
function batch(	detector_info_array::Matrix{S},
				srcHeights_array::Vector{S},
				srcRhos_array::Vector{S}=[0.0],
				srcRadii_array::Vector{S}=[0.0],
				srcLengths_array::Vector{S}=[0.0],
				ispoint::Bool=true) where S <: Real

	return  batch(	getDetectors(detector_info_array),
					srcHeights_array,
					srcRhos_array,
					srcRadii_array,
					srcLengths_array,
					ispoint)
end #function


"""# UnExported

    _batch(
		::Val(true),
		detector::RadiationDetector,
		srcHeights_array::Vector{Float64},
		srcRhos_array::Vector{Float64},
		srcRadii_array::Vector{Float64},
		srcLengths_array::Vector{Float64}
		)

batch calculation for specialized for **``point``** sources. 
return a tuple of three arrays the `detector`, the `results`and the path of the **``CSV``** 
file containing results. 

The `results` has columns of headers `Height`, `Rho`, `GeoEfficiency`.

!!! note
     for all arrays `srcHeights_array`, `srcRhos_array`, `srcRadii_array` and `srcLengths_array` 
     element type should be ``Float64``. if any of them have other numerical element type it 
     should converted to ``Float64`` using `float` before passing it to this method.

!!! warning
     both `srcRadii_array`, `srcLengths_array` are completely ignored as this method is for point sources.

"""
function _batch(
		::Type{Val{true}},
		detector::RadiationDetector,
		srcHeights_array::Vector{Float64},
		srcRhos_array::Vector{Float64},
		srcRadii_array::Vector{Float64},
		srcLengths_array::Vector{Float64},
		)

	aPnt::Point = Point(0.0, 0.0)
	calculatedEff::Float64 = 0.0
	out_results::Vector{Float64} = Float64[];
	cellLabel = "\n\n<$(countDetectors)>$(id(detector))\n"
	for srcHeight = srcHeights_array
		for srcRho = srcRhos_array
		aPnt = Point(srcHeight, srcRho)
			
			calculatedEff = try	geoEff(detector, aPnt); catch err;	NaN64 end
			push!(out_results, aPnt.Height, aPnt.Rho, calculatedEff)

			printstyled(cellLabel, color=:yellow)
			println(" - Source: ", id(aPnt))
			println()
			println(" - The detector Geometrical Efficiency = ", calculatedEff)
			printstyled(repeat(" =",36),"\n", color=:red)

		end #for_Rho

	end #for_Height
	results::Matrix{Float64} = reshape(out_results, 3, :) |> transpose
	@info("Saving <$countDetectors> to '$(id(detector)).csv'......\n")
	path = joinpath(resultdir_pnt,  "$(id(detector)).csv")
	try
		writecsv_head(path, results, ["Height" "Rho" "GeoEfficiency"])

	catch err
		@error("'.$(id(detector)).csv': can't be created,\n trying to save results in an alternative file")
		checkResultsDirs() # to make sure the directories do exist
		path = joinpath(resultdir_pnt,  "_$(id(detector)).csv")
		writecsv_head(path, results, ["Height" "Rho" "GeoEfficiency"])

	end #try
	global countDetectors += 1;
	return (detector, results, path) # detector, results are for test purpose

end #function

"""# UnExported

    _batch(
		::Val(false),
		detector::RadiationDetector,
		srcHeights_array::Vector{Float64},
		srcRhos_array::Vector{Float64},
		srcRadii_array::Vector{Float64},
		srcLengths_array::Vector{Float64},
		)

batch calculation for specialized for **``non-point``** sources. 
return a tuple of three arrays the `detector`, the `results`and the path of the **``CSV``** 
file containing results. 

The `results` has columns of headers 
`AnchorHeight`, `AnchorRho`, `srcRadius`, `srcLength`, `GeoEfficiency`.

!!! note 
    for all arrays `srcHeights_array`, `srcRhos_array`, `srcRadii_array` and `srcLengths_array` 
    element type should be ``Float64``. if any of them have other numerical element type it 
    should converted to ``Float64`` using `float` before passing it to this method.

"""
function _batch(
		::Type{Val{false}},
		detector::RadiationDetector,
		srcHeights_array::Vector{Float64},
		srcRhos_array::Vector{Float64},
		srcRadii_array::Vector{Float64},
		srcLengths_array::Vector{Float64},
		)

	aPnt::Point = Point(0.0, 0.0)
	out_results::Vector{Float64} = Float64[];
	calculatedEff::Float64 = 0.0
	cellLabel = "\n\n<$(countDetectors)>$(id(detector))\n"
	for srcHeight = srcHeights_array
		for srcRho = srcRhos_array
		aPnt = Point(srcHeight, srcRho)
			for  srcLength = srcLengths_array;
				for srcRadius = srcRadii_array
					try
						calculatedEff = geoEff(detector, aPnt, srcRadius , srcLength)

					catch err
						#isa(err, AssertionError) && @goto(Next_srcLength)
						calculatedEff = NaN

					end #try
					
					push!(out_results, aPnt.Height, aPnt.Rho, srcRadius, srcLength, calculatedEff)
					
					printstyled(cellLabel, color=:yellow)
					println(" - Source[Anchor_", id(aPnt), ", srcRadius=",srcRadius, ", srcLength=", srcLength, "]")
					println()
					println(" - The detector Geometrical Efficiency = ", calculatedEff)
					printstyled(repeat(" =",36),"\n", color=:red)

				end #for_srcRadius

			@label(Next_srcLength)
			end #for_srcLength

		end #for_Rho

	@label(Next_Height)
	end #for_Height

	results::Matrix{Float64} = reshape(out_results, 5, :) |> transpose
	@info("Saving <$countDetectors> to '$(id(detector)).csv'......\n")
	path = joinpath(resultdir_nonPnt, "$(id(detector)).csv")
	try 
		writecsv_head(path, results, ["AnchorHeight" "AnchorRho" "srcRadius" "srcLength" "GeoEfficiency"])

	catch err
		@error("'$(id(detector)).csv': can't be created,\n trying to save results in an alternative file")
		checkResultsDirs() # to make sue that the directories do exist
		path = joinpath(resultdir_nonPnt, "_$(id(detector)).csv")
		writecsv_head(path, results, ["AnchorHeight" "AnchorRho" "srcRadius" "srcLength" "GeoEfficiency"])

	end #try
	global countDetectors += 1;
	return (detector, results, path) # detector, results are for test purpose

end #function


#------------------- :batchInfo -----------------

"""

The function `batch()` can be called with or without arrangement(s). 
The without argument version relay on previously prepared Comma Saved  
Values [CSV] files, that can be easily edit by Microsoft Excel, 
by default located in the directory **``$dataDir``** .

results of batch calculation are saved on a **``CSV``**  file(s) named after the detector(s). 
the **``CSV``**  file by default found in **``$(resultdir)``**.
	
# CSV input files
	
*  ``Detectors.csv`` contains the detectors description; The line format is: 
	
		 Crystal_Radius | Crystal_Length | Hole_Radius | Hole_Depth |
    	 ---------------| ---------------|-------------|----------- |

*  ``srcHeights.csv`` contains the source heights; 
	
    	 Source_Heights | 
		 ---------------|

*  ``srcRhos.csv`` contains the source off-axis distances; 	 				
	
		 Source_Rhos | 
     	 ------------|

*  ``srcRadii.csv`` contains the source radii for disc and cylindrical sources; 			
	
		 Source_Radii| 
		 ------------|

*  ``srcLengths.csv`` contains the source length for cylindrical sources; 	
	
		 Source_Lengths| 
		 --------------|

 # CSV results files
 **``CSV``**  file containing the results has columns of headers 
 `AnchorHeight`, `AnchorRho`, `srcRadius`, `srcLength`, `GeoEfficiency` for `non-point` sources 
 and columns of headers `Height`, `Rho`, `GeoEfficiency` for `point` sources.

!!! note
     for Comma Saved Values [CSV] files each line represent an entry, 
     the first line is always treated as the header.
	 
!!! warning
     the program expect each line to contain one number for all CSV files except
     for ``Detectors.csv`` each line should contain at least one number or at 
     most four separated numbers.

""" 
const batchInfo = nothing
