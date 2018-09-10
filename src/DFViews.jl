module DFViews

using DataFrames, Electron, Labels

export dfview, dfdesc

function getmaxwidth(vec::AbstractVector)
    return maximum(length.(collect(skipmissing(vec))))
end

function atype(df::DataFrame,v::Symbol)
    # Array type = DA for DataArray, CA for Categorical Array, and UV for Union Vector
    if isdefined(Main,:CategoricalArrays) && typeof(df[v]) <: CategoricalArray
        return string("Categorical (",replace(string(eltype(df[v].refs)),"UInt" => ""),")")
    elseif isdefined(Main,:DataArrays) && typeof(df[v]) <: DataArray
         return "DataArray"
    elseif isdefined(Main,:PooledArrays) && typeof(df[v]) <: PooledArray
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
        elseif eltyp in ["Dates.Date","Dates.DateTime"]
            eltyp = replace(eltyp,r"^Dates\." => "")
        end
    end

    return eltyp
end

function dfdesc(df::DataFrame, label::Union{Label,Nothing} = nothing; width=800, height=850)

    bdata = IOBuffer()

    print(bdata,"""
<!DOCTYPE html>
<html lang="en">
<head>
  <title>DataFrame Table of Contents</title>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/tabulator/3.5.3/css/tabulator.min.css" rel="stylesheet">
</head>
<body style="margin:0;padding:0;font-family:Arial,Helvetica,Tahoma;">
<div id="df-table"></div>

<!-- Insert this line above script imports  -->
<script>if (typeof module === 'object') {window.module = module; module = undefined;}</script>
<script
    src="https://code.jquery.com/jquery-3.3.1.slim.min.js"
    integrity="sha256-3edrmyuQ0w65f8gfBsqowzjJe2iM6n0nKciPUp8y+7E="
    crossorigin="anonymous"></script>
<script
    src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"
    integrity="sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU="
    crossorigin="anonymous"></script>
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/tabulator/3.5.3/js/tabulator.min.js"></script>
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
        pmiss = string(round(100 * nmiss[i]/nrows,digits=1),"%")

        print(bdata,"\t{id:",i,",varname:\"",varname,"\",atype:\"",atyp,
            "\",etype:\"",etyp,"\",nval:",nrows-nmiss[i],",pmiss:\"",pmiss,"\"")

        # if label dictionary is provided
        if label != nothing
            # label name
            lname = lblname(label,varnames[i]) == nothing ? "" : string(lblname(label,varnames[1]))
            # variable label
            vrlab = varlab(label,varnames[i])
            print(bdata,",lblname:\"",lname,"\",varlab:\"",replace(vrlab,"\"" => "\\\""),"\"")
        end

        println(bdata, "},")
    end
    println(bdata, "];")

    println(bdata,"""
    \$("#df-table").tabulator({
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

    fn = tempdir() * "dfdesc_table.html"
    if isfile(fn)
        rm(fn)
    end
    println(fn)
    fout = open(fn,"w")
    print(fout,String(take!(bdata)))
    close(fout)

    Window(URI(fn),options=Dict("width"=>width,"height"=>height,"x"=>0,"y"=>0))

end

function dfview(df::DataFrame, label::Union{Label,Nothing} = nothing; from = 1, maxrows = 1000, width=800, height=850)

    bdata = IOBuffer()

    print(bdata,"""
<!DOCTYPE html>
<html lang="en">
<head>
  <title>DataFrame Data View</title>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/tabulator/3.5.3/css/tabulator.min.css" rel="stylesheet">
</head>
<body style="margin:0;padding:0;font-family:Arial,Helvetica,Tahoma;">
<div id="df-table"></div>

<!-- Insert this line above script imports  -->
<script>if (typeof module === 'object') {window.module = module; module = undefined;}</script>
<script
    src="https://code.jquery.com/jquery-3.3.1.slim.min.js"
    integrity="sha256-3edrmyuQ0w65f8gfBsqowzjJe2iM6n0nKciPUp8y+7E="
    crossorigin="anonymous"></script>
<script
    src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"
    integrity="sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU="
    crossorigin="anonymous"></script>
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/tabulator/3.5.3/js/tabulator.min.js"></script>
<script type="text/javascript">
    var tabledata = [
""")

    varnames = names(df)
    nrows,ncols = size(df)

    to = min(nrows,maxrows + from - 1)

    for i=from:to

        print(bdata,"\t{id:",i)
        for j=1:ncols
            if occursin("Str",etype(df,varnames[j]))
                str = ismissing(df[i,varnames[j]]) ? "" : df[i,varnames[j]]
                print(bdata,",",string("f_",varnames[j]),":\"",str,"\"")
            elseif etype(df,varnames[j]) in ["Date","DateTime"]
                str = ismissing(df[i,varnames[j]]) ? "" : string(df[i,varnames[j]])
                print(bdata,",",string("f_",varnames[j]),":\"",str,"\"")
            elseif ismissing(df[i,varnames[j]])
                print(bdata,",",string("f_",varnames[j]),":\"\"")
            else
                print(bdata,",",string("f_",varnames[j]),":\"",df[i,varnames[j]],"\"")
            end
        end
        println(bdata,"},")

    end
    println(bdata, "];")

    println(bdata,"""
    \$("#df-table").tabulator({
    data:tabledata,
    layout:"fitData",
    columns:[""")

    println(bdata,"{title:\"Row\",field:\"id\",align:\"right\",headerSort:false},")
    for i=1:ncols
        if occursin("Str",etype(df,varnames[i]))
            align="left"
        else
            align="right"
        end

        println(bdata,"\t{title:\"",string(varnames[i]),"\",field:\"",string("f_",varnames[i]),"\",align:\"",align,"\",headerSort:false},")
    end
    println(bdata,"""
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
