module DFViews

using DataFrames, Gtk, Dates, Stella, Labels

export dfview, dfdesc

function eltype3(df::DataFrame,v::Symbol)
    if typeof(df[v]) <: CategoricalArray
        return eltype(df[v].pool.index)
    end
    return Missings.T(eltype(df[v]))
end

function dfview(df::DataFrame; start=1)

    # df - dataframe name
    (nrow,ncol) = size(df)

    # variable names
    varnames = names(df)

    # data types
    etypes = Vector{DataType}()
    for v in names(df)
        push!(etypes,String)
    end

    # define a listStore
    ls = GtkListStore(Int64,etypes...)

    # add data to the listStore
    #row_array = Array{Any,1}(ncol)
    aa = Array{Any}(undef,ncol)
    for i in start:(nrow > 1000 ? 1000 : nrow)
        for j in 1:ncol
            aa[j] = ismissing(df[i,j]) ? "" : string(df[i,j])
        end
        push!(ls,tuple(i, aa...))
    end

    # TreeView
    tv = GtkTreeView(GtkTreeModel(ls))

    # let's put borders around the cells
    set_gtk_property!(tv,:enable_grid_lines,3)

    # variable names on the column headings
    r = GtkCellRendererText()

    # setproperty!(r,:xalign, 1.) # left justification
    c = GtkTreeViewColumn("Obs", r, Dict([("text",0)]))
    push!(tv,c)
    for (i,v) in enumerate(varnames)
        if eltype3(df,v) <: Number
            set_gtk_property!(r,:xalign,1)
        else
            set_gtk_property!(r,:xalign,0)
        end
        push!(tv,GtkTreeViewColumn(string(v), r, Dict([("text",i)])))
    end

	# add a Frame with scollbars
	sw = GtkScrolledWindow(tv)
	# setproperty!(sw,:shadow_type,2)
	#set_gtk_property!(sw,:scrollbar_within_bevel, true)
	#set_gtk_property!(sw,:scrollbar_spacing,3)
	# setproperty!(sw,:hscrollbar_policy,1) # automatic
	# setproperty!(sw,:vscrollbar_policy,1) # automatic

    # create a frame and add it to the window
    nrows = start + 999
    win = GtkWindow(sw,"DataFrame - $nrow rows, $ncol columns - Rows $start - $nrows" , 500, 300)
    # push!(win,sw)

    Gtk.showall(win)
end

function dfdesc(df::DataFrame,labels::Union{Nothing,Label} = nothing)

    # df - dataframe name
    (nrow,ncol) = size(df)

    # variable names
    varnames = names(df)

    # define a listStore
    if labels == nothing
        # Row, Variable Name, Atype, Eltype, N Missing, P Missing
        ls = GtkListStore(Int,String,String,String,Int,String)
    else
        # Row, Variable Name, Atype, Eltype, N Missing, P Missing, Lblname, Description
        ls = GtkListStore(Int,String,String,String,Int,String,String,String)
    end

    # add data to the listStore
    aa = Array{Any}(undef,labels == nothing ? 6 : 8)

    # number of missing values in each column
    nmiss = DataFrames.colmissing(df)

    for i in 1:ncol
        # row
        aa[1] = i

        # variable name
        aa[2] = string(varnames[i])

        # array type
        aa[3] = Stella.atype(df,varnames[i])

        # eltype
        aa[4] = Stella.etype(df,varnames[i])

        # number of rows with missing values
        aa[5] = nmiss[i]

        # percent missing
        aa[6] = string( round(100 * nmiss[i] / size(df,1), digits = 2), "%")

        if labels != nothing

            # label name
            lname = Labels.lblname(labels,varnames[i])
            aa[7] = lname == nothing ? "" : string(lname)

            # variable description
            aa[8] = Labels.varlab(labels,varnames[i])
        end

        push!(ls,tuple(aa...))
    end

    # TreeView
    tv = GtkTreeView(GtkTreeModel(ls))

    # let's put borders around the cells
    set_gtk_property!(tv,:enable_grid_lines,3)

    # variable names on the column headings
    r = GtkCellRendererText()

    # setproperty!(r,:xalign, 1.) # left justification
    set_gtk_property!(r,:xalign,1)
    push!(tv,GtkTreeViewColumn("Num", r, Dict([("text",0)])))
    for (i,v) in enumerate(["Variable Name","Array Type","Eltype","N Miss","% Miss","Lblname","Description"])
        if labels == nothing && i > 5
            continue
        end
        r = GtkCellRendererText()
        if i in [4,5]
            set_gtk_property!(r,:xalign,1)
        else
            set_gtk_property!(r,:xalign,0)
        end
        push!(tv,GtkTreeViewColumn(v, r, Dict([("text",i)])))
    end

	# add a Frame with scollbars
	sw = GtkScrolledWindow(tv)
	# setproperty!(sw,:shadow_type,2)
	# set_gtk_property!(sw,:scrollbar_within_bevel, true)
	# set_gtk_property!(sw,:scrollbar_spacing,3)
	# setproperty!(sw,:hscrollbar_policy,1) # automatic
	# setproperty!(sw,:vscrollbar_policy,1) # automatic

    # create a frame and add it to the window
    w = labels == nothing ? 450 : 750
    h = ncol > 25 ? 800 : 30 * ncol
    win = GtkWindow(sw,"DataFrame Table of Contents" , w, h)
    # push!(win,sw)

    Gtk.showall(win)
end



end # module
