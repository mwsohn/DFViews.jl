module DFViews

using DataFrames, Electron

export dfview

function getmaxwidth(vec::AbstractVector)
    return maximum(length.(collect(skipmissing(vec))))
end

function atype(df::DataFrame,v::Symbol)
    # Array type = DA for DataArray, CA for Categorical Array, and UV for Union Vector
    if isdefined(:CategoricalArrays) && typeof(df[v]) <: CategoricalArray
        return string("Categorical (",replace(string(eltype(df[v].refs)),"UInt",""),")")
    elseif isdefined(:DataArrays) && typeof(df[v]) <: DataArray
         return "DataArray"
    elseif isdefined(:PooledArrays) && typeof(df[v]) <: PooledArray
         return "PooledArray"
    elseif isa(eltype(df[v]),Union)
        return "Union Vector" # Union Vector
    else
        return "Vector"
    end
end

function etype(df::DataFrame,v::Symbol)
    # Eltype
    if typeof(df[v]) <: CategoricalArray
        eltyp = string(eltype(df[v].pool.index))
        if in(eltyp,["String","AbstractString"])
            eltyp = string("Str",getmaxwidth(df[v].pool.index))
        end
    else
        eltyp = string(Missings.T(eltype(df[v])))
        if in(eltyp,["String","AbstractString"])
            eltyp = string("Str",getmaxwidth(df[v]))
        end
    end

    return eltyp
end

function dfview(df::DataFrame, label::Dict = Dict(); width=800, height=850)

    bdata = IOBuffer()

    pkgdir = replace(Pkg.dir(),"\\","/") * "/DFViews/src"

    print(bdata,"""
<!DOCTYPE html>
<html lang="en">
<head>
  <title>DataFrame Table of Contents</title>
  <link href="$pkgdir/tabulator_simple.min.css" rel="stylesheet">
</head>
<body style="margin:0;padding:0;font-family:Arial,Helvetica,Tahoma;">
<div id="df-table"></div>

<!-- Insert this line above script imports  -->
<script>if (typeof module === 'object') {window.module = module; module = undefined;}</script>
<script type="text/javascript" src="$pkgdir/jquery-3.3.1.min.js"></script>
<script type="text/javascript" src="$pkgdir/jquery-ui.min.js"></script>
<script type="text/javascript" src="$pkgdir/tabulator.min.js"></script>
<script type="text/javascript">
    var tabledata = [
    """)

    varnames = names(df)
    nrows = size(df,1)
    nmiss = DataFrames.colmissing(df)
    for i=1:size(df,2)
        varname = string(varnames[i])
        atyp = atype(df,varnames[i])
        etyp = etype(df,varnames[i])
        pmiss = string(round(100 * nmiss[i]/nrows,1),"%")

        print(bdata,"\t{id:",i,",varname:\"",varname,"\",atype:\"",atyp,
            "\",etype:\"",etyp,"\",nval:",nrows-nmiss[i],",pmiss:\"",pmiss,"\"")

        # if label dictionary is provided
        if length(label) > 0
            # label name
            lblname = label["label"][varnames[i]]
            # variable label
            varlab = label["variable"][varnames[i]]
            print(bdata,",lblname:\"",lblname,"\",varlab:\"",replace(varlab,"\"","\\\""),"\"")
        end

        println(bdata, "},")
    end
    println(bdata, "];")

    println(bdata,"""

\$\(\"#df-table\"\).tabulator({
    height:800,
    data:tabledata,
    layout:"fitColumns",
    columns:[
        {title:"Num",field:"id",sorter:"number",align:"right",width:65,headerTooltip:"Variable Number"},
        {title:"Variable Name",field:"varname",sorter:"string",align:"left",minWidth:100,headerTooltip:true},
        {title:"Array Type",field:"atype",sorter:"string",align:"left",headerTooltip:true},
        {title:"Eltype",field:"etype",sorter:"string",align:"left",width:80,headerTooltip:"Data type of array elements"},
        {title:"Values",field:"nval",sorter:"number",align:"right",width:70,formatter:"money",formatterParams:{precision:0},headerTooltip:"Number of non-missing values"},
        {title:"Missing",field:"pmiss",sorter:"number",align:"right",width:70,headerTooltip:"Percent missing"},
        {title:"Label Name",field:"lblname",sorter:"string",align:"left",width:70,headerTooltip:"Value Label Name"},
        {title:"Variable Definition",field:"varlab",sorter:"string",align:"left",minWidth:200,headerTooltip:"Vaiable Label"},
    ],
});
</script>
</body>
</html>
    """)

    fn = tempdir() * "dfview_table.html"
    if isfile(fn)
        rm(fn)
    end
    println(fn)
    fout = open(fn,"w")
    print(fout,String(take!(bdata)))
    close(fout)

    Window(URI(fn),options=Dict("width"=>width,"height"=>height,"x"=>0,"y"=>0))

end

end # module
