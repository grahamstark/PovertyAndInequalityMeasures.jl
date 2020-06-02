module PovertyAndInequalityMeasures

using IterableTables
using IteratorInterfaceExtensions
using TableTraits

# inequality stuff
export OutputDict, OutputDictArray
export DEFAULT_ATKINSON_ES, DEFAULT_ENTROPIES, DEFAULT_FGT_ALPHAS
export make_gini, make_poverty, make_inequality, binify, add_decomposed_theil

# Write your package code here.
const WEIGHT          = 1
const INCOME          = 2
const WEIGHTED_INCOME = 3
const POPN_ACCUM      = 4
const INCOME_ACCUM    = 5
const DEFAULT_FGT_ALPHAS = [ 0.0, 0.50, 1.0, 1.50, 2.0, 2.5 ];
const DEFAULT_ATKINSON_ES = [ 0.25, 0.50, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0, 2.25 ];
const DEFAULT_ENTROPIES = [ 1.25, 1.50, 1.75, 2.0, 2.25, 2.5 ];

const OutputDict = Dict{ Symbol, Any }
const OutputDictArray = Array{ OutputDict, 1 }

function sortAndAccumulate( aug :: Array{<:Real,2}, sortdata :: Bool, nrows :: Integer ) :: Array{<:Real,2}
    if sortdata
        aug = sortslices( aug, alg=QuickSort, dims=1,lt=((x,y)->isless(x[INCOME],y[INCOME])))
    end
    cumulative_weight :: Float64 = 0.0
    cumulative_income :: Float64 = 0.0
    for row in 1:nrows
            cumulative_weight += aug[row,WEIGHT]
            cumulative_income += aug[row,WEIGHTED_INCOME]
            aug[row,POPN_ACCUM] = cumulative_weight
            aug[row,INCOME_ACCUM] = cumulative_income
    end
    return aug
end # sortAndAccumulate


"
internal function that makes a sorted array
with cumulative income and population added
"
function make_augmented(
    data,
    weightcol :: Symbol,
    incomecol :: Symbol,
    sortdata  :: Bool = true,
    deletenegatives :: Bool = true ) :: Array{Float64,2}
    @assert TableTraits.isiterabletable( data ) "data needs to implement IterableTables"
    iter = IteratorInterfaceExtensions.getiterator(data)
    nrows = length(iter)
    aug = zeros( nrows, 5 )
    r = 0
    for row in iter
        if ( ismissing( row[weightcol])) || ( ismissing( row[incomecol])) ||
            ( deletenegatives && row[incomecol] < 0.0 )
            ;
        else
            r += 1
            aug[r,WEIGHT] = get(row[weightcol]) ## this is the datavalue thing; see:
            aug[r,INCOME] = get(row[incomecol])
            aug[r,WEIGHTED_INCOME] = aug[r,WEIGHT]*aug[r,INCOME]
        end # not missing or negative
    end
    aug = aug[1:r,:]
    aug = sortAndAccumulate( aug, sortdata, r )
    return aug
end

"
internal function that makes a sorted array
with cumulative income and population added
"
function make_augmented(
    data            :: Array{<:Real,2},
    weightpos       :: Integer = 1,
    incomepos       :: Integer = 2,
    sortdata        :: Bool = true,
    deletenegatives :: Bool = true ) :: Array{Float64,2}

    nrows = size( data )[1]
    aug = zeros( nrows, 5 )
    r = 0
    for row in 1:nrows
        if( deletenegatives && data[row,incomepos] < 0.0 )
            ;
        else
            r += 1
            aug[r,WEIGHT] = data[row,weightpos]
            aug[r,INCOME] = data[row,incomepos]
            aug[r,WEIGHTED_INCOME] = data[row,incomepos]*data[row,weightpos]
        end # not neg or negs accepted
    end # row loop
    aug = sortAndAccumulate( aug, sortdata, r )
    return aug[1:r,:]
end

"""
calculate a Gini coefficient on one of our sorted arrays
"""
function make_gini( data :: Array{Float64, 2} ) :: Float64
    lorenz :: Float64 = 0.0

    nrows = size( data )[1]
    if nrows == 0
        return 0.0
    end
    lastr = data[nrows,:]
    for row in 1:nrows
        lorenz += data[row, WEIGHT]*((2.0*data[row,INCOME_ACCUM]) - data[row,WEIGHTED_INCOME])
    end
    return 1.0-(lorenz/lastr[INCOME_ACCUM])/lastr[POPN_ACCUM]
end

"""
generate a subset of one of our datasets with just the elements whose incomes
are below the line. Probably possible in 1 line, once I get the hang of this
a bit more.
"""
function make_all_below_line( data :: Array{Float64, 2}, line :: Float64 ) :: Array{Float64, 2 }
    nrows = size( data )[1]
    ncols = size( data )[2]
    outa = zeros( Float64, nrows, ncols ) # Array{Float64}( undef, 0, 5 )
    @assert ncols == 5 "data should have 5 cols"
    nout = 0
    for row in 1:nrows
        if data[row,INCOME] < line
            nout += 1
            outa[ nout, : ] .= data[row,:]
        end
    end
    return outa[1:nout,:]
end


"""
Create a dictionary of poverty measures.

This is based on the [World Bank's Poverty Handbook](http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality)
by  Haughton and Khandker.

Arguments:
* `rawdata` - an nxm array of real nunbers; each row is an observation; one col should be a weight, another is income;
   positions assumed to be 1 and 2 unless weight and incomepos are supplied
* `line` - a poverty line, assumed same for all obs (so income is assumed to be already equivalised)
* `foster_greer_thorndyke_alphas` - coefficients for FGT poverty measures; note that FGT(0)
   corresponds to headcount and FGT(1) to gap; count and gap are computed directly anyway
   but it's worth checking one against the other.
* `growth` is (e.g.) 0.01 for 1% per period, and is used for 'time to exit' measure.


Output is  dictionary with an entry for each measure.

The measures are:

* `headcount`;
* `gap`;
* `Foster Greer Thorndyke`, for each of the values in `foster_greer_thorndyke_alphas`;
* `Watts`;
* `time to exit`, for the supplied growth rate;
* `Shorrocks`;
* `Sen`.

See World Bank, ch. 4.

"""
function make_poverty(
    rawdata                       :: Array{<:Real, 2},
    line                          :: Real,
    growth                        :: Real,
    weightpos                     :: Integer = 1,
    incomepos                     :: Integer = 2,
    foster_greer_thorndyke_alphas :: AbstractArray{<:Real, 1} = DEFAULT_FGT_ALPHAS ) :: OutputDict

    data = make_augmented( rawdata, weightpos, incomepos )
    make_povertyinternal(
        data = data,
        line = line,
        growth = growth,
        foster_greer_thorndyke_alphas = foster_greer_thorndyke_alphas )
end

"""
As above, but using the QueryVerse IterableTables interface
rawdata - basically anything resembling a dataframe; see: [https://github.com/queryverse/IterableTables.jl]
throws an exception if rawdata doesn't support iterabletable interface
"""
function make_poverty(
    rawdata,
    line                          :: Real,
    growth                        :: Real,
    weightcol                     :: Symbol,
    incomecol                     :: Symbol,
    foster_greer_thorndyke_alphas :: AbstractArray{<:Real, 1} = DEFAULT_FGT_ALPHAS,
     ) :: OutputDict
    @assert TableTraits.isiterabletable( rawdata ) "data needs to implement IterableTables"
    data = make_augmented( rawdata, weightcol, incomecol )
    make_povertyinternal(
        data = data,
        line = line,
        growth = growth,
        foster_greer_thorndyke_alphas = foster_greer_thorndyke_alphas )
end


"""
Internal version, once we have our datatset
"""
function make_povertyinternal(
    ;
    data                          :: Array{Float64, 2},
    line                          :: Real,
    growth                        :: Real = 0.0,
    foster_greer_thorndyke_alphas :: AbstractArray{<:Real, 1} = DEFAULT_FGT_ALPHAS,) :: OutputDict

    pv = Dict{ Symbol, Any}()
    nrows = size( data )[1]
    ncols = size( data )[2]
    population = data[ nrows, POPN_ACCUM ]
    total_income = data[ nrows, INCOME_ACCUM ]

    nfgs = size( foster_greer_thorndyke_alphas )[1]
    @assert ncols == 5 "data should have 5 cols"
    pv[:fgt_alphas] = foster_greer_thorndyke_alphas
    pv[:headcount] = 0.0
    pv[:gap] = 0.0
    pv[:watts] = 0.0
    pv[:foster_greer_thorndyke] = zeros( Float64, nfgs )
    pv[:time_to_exit] = 0.0

    belowline = make_all_below_line( data, line )
    nbrrows = size( belowline )[1]

    pv[:gini_amongst_poor] = make_gini( belowline )
    for row in 1:nbrrows
        inc :: Float64= belowline[row,INCOME]
        weight :: Float64 = belowline[row,WEIGHT]
        gap :: Float64 = line - inc
        @assert gap >= 0 "poverty gap must be postive"
        pv[:headcount] += weight
        pv[:gap] += weight*gap/line
        if belowline[row,INCOME ] > 0
            pv[:watts] += weight*log(line/inc)
        end
        for p in 1:nfgs
            fg = foster_greer_thorndyke_alphas[p]
            pv[:foster_greer_thorndyke][p] += weight*((gap/line)^fg)
        end
    end # main loop
    pv[:watts] /= population
    if growth > 0.0
        pv[:time_to_exit] = pv[:watts]/growth
    end
    pv[:gap] /= population
    pv[:headcount] /= population
    pv[:foster_greer_thorndyke] ./= population
    #
    # Gini of poverty gaps; see: WB pp 74-5
    #
    # create a 'Gini of the Gaps'
    # the sort routine in make_augmented does a really
    # bad job here either because the data
    # is mostly zeros or because it's reverse sorted
    # (smallest income -> biggest gap)
    # we we can just create the dataset in reverse
    # and use that
    gdata = zeros( Float64, nrows, 5 )
    for row in 1:nrows
        gap = max( 0.0, line - data[row,INCOME] )
        gpos = nrows - row + 1
        gdata[gpos,INCOME] = gap;
        gdata[gpos,WEIGHT] = data[row,WEIGHT]
    end
    gdata = make_augmented( gdata, 1, 2, false )
    pv[:poverty_gap_gini] = make_gini( gdata )

    pv[:sen] = pv[:headcount]*pv[:gini_amongst_poor]+pv[:gap]*(1.0-pv[:gini_amongst_poor])
    pv[:shorrocks] = pv[:headcount]*pv[:gap]*(1.0+pv[:poverty_gap_gini])
    return pv
end # make_poverty

"""
Make a wee dict with :theil_between and :theil_within
See WB eqns 6.7/6.8.
TODO
1. there are some papers on decomposing Atkinson, but I
don't understand them ..
2. the over time 3-part version

 popindic : Inequal for the population as a whole
 subindices : an array of dics, one for each subgroup of interest
"""
function add_decomposed_theil( popindic :: OutputDict, subindices :: OutputDictArray ) :: OutputDict
    popn = popindic[:total_population]
    income = popindic[:total_income]
    avinc = popindic[:average_income]
    within = zeros(2)
    between = zeros(2)
    totalpop = 0.0
    totalinc = 0.0
    for ind in subindices
        popshare = ind[:total_population]/popn
        incshare = ind[:total_income]/income
        totalpop += popshare
        totalinc += incshare

        within[1] += ind[:theil][1]*popshare
        between[1] += popshare*log(avinc/ind[:average_income])

        within[2] += ind[:theil][2]*incshare
        between[2] += incshare*log(incshare/popshare)

    end
    overall1 = popindic[:theil][1]
    overall2 = popindic[:theil][2]

    @assert totalpop ≈ 1.0
    @assert totalinc ≈ 1.0
    @assert within[1]+between[1] ≈ popindic[:theil][1]
    @assert within[2]+between[2] ≈ popindic[:theil][2]
    md = OutputDict()
    md[:theil_between] = between
    md[:theil_within] = within
    md
end

"""
Make a dictionary of inequality measures.
This is mainly taken from chs 5 and 6 of the World Bank book.

1. `rawdata` a matrix with cols with weights and incomes
2. `atkinson_es` inequality aversion values for the Atkinson indexes
3. `generalised_entropy_alphas`
4. `weightpos` - column with weights
5. `incomepos` - column with incomes


Returned is a Dict of inequality measures with:

* `Gini`;
* `Atkinson`, for each value in `atkinson_es`;
* `Theil`;
* `generalised_entropy`;
* `Hoover`;
* `Theil`;
* `Palma`.

See WB chs 5 an 6, and Cobham and Sumner on the Palma.

Also in the dict are:

* `total_income`
* `total_population`
* `average_income`
* `deciles`.


"""
function make_inequality(
    rawdata                    :: Array{<:Real, 2 },
    weightpos                  :: Integer = 1,
    incomepos                  :: Integer = 2,
    atkinson_es                :: AbstractArray{<:Real, 1} = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: AbstractArray{<:Real, 1} = DEFAULT_ENTROPIES ) :: OutputDict
    data = make_augmented( rawdata, weightpos, incomepos )
    return make_inequalityinternal(
        data = data,
        atkinson_es = atkinson_es,
        generalised_entropy_alphas = generalised_entropy_alphas
    )
end

"""
As above but using the iterable table interface; see: https://github.com/queryverse/IterableTables.jl
weightcol and incomecol are names of columns
"""
function make_inequality(
    rawdata,
    weightcol                  :: Symbol,
    incomecol                  :: Symbol,
    atkinson_es                :: AbstractArray{<:Real, 1} = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: AbstractArray{<:Real, 1} = DEFAULT_ENTROPIES ) :: OutputDict
    @assert TableTraits.isiterabletable( rawdata ) "data needs to implement IterableTables"
    data = make_augmented( rawdata, weightcol, incomecol )
    return make_inequalityinternal(
        data = data,
        atkinson_es = atkinson_es,
        generalised_entropy_alphas = generalised_entropy_alphas
    )

end

"""
Chop a dataset with populations and incomes
into numbins groups in a form suitable for
e.g. a Gini curve.
* col1 is cumulative population,
*    2 cumulative income/whatever,
*    3 threshold income level.
"""
function binify(
    rawdata   :: Array{<:Real, 2 },
    numbins   :: Integer,
    weightpos :: Integer = 1,
    incomepos :: Integer = 2 ) :: AbstractArray{<:Real, 2}
    data = make_augmented( rawdata, weightpos, incomepos, true, true )
    return binifyinternal( data, numbins )
end

"""
As above, but using any DataFrame like thing that supports the TableTraits.isiterabletable interface
"""
function binify(
    rawdata,
    numbins   :: Integer,
    weightcol :: Symbol,
    incomecol :: Symbol ) :: AbstractArray{<:Real, 2}
    @assert TableTraits.isiterabletable( rawdata ) "data needs to implement IterableTables"
    data = make_augmented( rawdata, weightcol, incomecol, true, true )
    return binifyinternal( data, numbins )
end

## FIXME this can go horribly wrong with small unbalanced numbers of rows -
# try pop=[22,1,1,1,1,1,1,1,1,1 inc==[1,2,2,2,2,2,2,2,2,2]
function binifyinternal(
    data      :: Array{<:Real, 2 },
    numbins   :: Integer ) :: AbstractArray{<:Real, 2}
    nrows = size( data )[1]
    ncols = size( data )[2]
    out = zeros( Float64, numbins, 3 )
    total_population = data[ nrows, POPN_ACCUM ]
    total_income = data[ nrows, INCOME_ACCUM ]
    bin_size :: Float64 = 1.0/numbins
    bno = 0
    thresh = bin_size
    popsharelast = 0.0
    incomelast = 0.0
    incomeaccumlast = 0.0
    incomeaccum = 0.0
    # print( "total_population $total_population total_income $total_income \n")
    for row in 1:nrows
        income = data[row,INCOME]
        incomeaccum = data[row,INCOME_ACCUM]/total_income
        popshare = data[row,POPN_ACCUM]/total_population
        if popshare ≈ thresh
            bno += 1
            out[bno,1] = popshare
            out[bno,2] = incomeaccum
            out[bno,3] = income
            # print( "row $row popshare $popshare ≈ thresh $thresh incomeaccum $incomeaccum \n")
            thresh += bin_size
        elseif( popsharelast < thresh ) && ( popshare > thresh)
            bno += 1
            # print( "row $row popsharelast $popsharelast thresh $thresh popshare $popshare\n" )
            pgap = popshare - popsharelast
            p1 = (thresh - popsharelast)
            p2 = (popshare - thresh)
            out[bno,1] = ((popshare*p2)+(popsharelast*p1))/pgap
            out[bno,2] = ((incomeaccum*p2)+(incomeaccumlast*p1))/pgap
            out[bno,3] = ((income*p2)+(incomelast*p1))/pgap
            thresh += bin_size
        end
        popsharelast = popshare
        incomelast = income
        incomeaccumlast = incomeaccum
    end
    return out
end


"""
Make a dictionary of inequality measures.
This is mainly taken from chs 5 and 6 of the World Bank book.

1. `rawdata` a matrix with cols with weights and incomes
2. `atkinson_es` inequality aversion values for the Atkinson indexes
3. `generalised_entropy_alphas`
4. `weightpos` - column with weights
5. `incomepos` - column with incomes

"""
function make_inequalityinternal(
    ;
    data                       :: Array{Float64, 2},
    atkinson_es                :: AbstractArray{<:Real, 1} = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: AbstractArray{<:Real, 1} = DEFAULT_ENTROPIES ) :: OutputDict
    nrows = size( data )[1]
    ncols = size( data )[2]
    @assert ncols == 5 "data should have 5 cols but has $ncols"

    nats = size( atkinson_es )[1]
    neps = size( generalised_entropy_alphas )[1]
    iq = OutputDict()
    # initialise atkinsons; 1 for e = 1 0 otherwise
    iq[:atkinson_es] = atkinson_es
    iq[:atkinson] = zeros( Float64, nats )
    iq[:atkinson] = [i == 1.0 ? 1.0 : 0.0 for i in atkinson_es]
    iq[:generalised_entropy_alphas] = generalised_entropy_alphas
    iq[:generalised_entropy] = zeros( Float64, neps )
    iq[:negative_or_zero_income_count] = 0
    iq[:hoover] = 0.0
    iq[:theil] = zeros(Float64,2)
    iq[:gini] = make_gini( data )

    total_income = data[nrows,INCOME_ACCUM]
    total_population = data[nrows,POPN_ACCUM]
    y_bar = total_income/total_population
    iq[:total_income] = total_income
    iq[:total_population] = total_population
    iq[:average_income] = y_bar
    popsharelast = 0.0
    incomelast = 0.0
    for row in 1:nrows
        income = data[row,INCOME]
        weight = data[row,WEIGHT]
        if income > 0.0
            y_yb  :: Float64 = income/y_bar
            yb_y  :: Float64 = y_bar/income
            ln_y_yb :: Float64 = log( y_yb )
            ln_yb_y :: Float64 = log( yb_y )
            iq[:hoover] += weight*abs( income - y_bar )
            iq[:theil][1] += weight*ln_yb_y
            iq[:theil][2] += weight*y_yb*ln_y_yb
            for i in 1:nats
                    es :: Float64 = iq[:atkinson_es][i]
                    if es != 1.0
                        iq[:atkinson][i] += weight*(y_yb^(1.0-es))
                    else
                        iq[:atkinson][i] *= (income)^(weight/total_population)
                    end # e = 1 case
            end # atkinsons
            for i in 1:neps
                alpha :: Float64 = iq[:generalised_entropy_alphas][i]
                iq[:generalised_entropy][i] += weight*(y_yb^alpha)
            end # entropies
        else
            iq[:negative_or_zero_income_count] += 1
        end # positive income
    end # main loop
    deciles = binify( data, 10 )
    iq[:median] = deciles[5,3]
    # top 10/bottom 40
    iq[:palma] = (1.0-deciles[9,2])/deciles[4,2]
    iq[:deciles] = deciles
    iq[:hoover] /= 2.0*total_income
    for i in 1:neps
        alpha :: Float64 = iq[:generalised_entropy_alphas][i]
        aq :: Float64 = (1.0/(alpha*(alpha-1.0)))
        iq[:generalised_entropy][i] =
            aq*((iq[:generalised_entropy][i]/total_population)-1.0)
    end # entropies
    for i in 1:nats
        es :: Float64 = iq[:atkinson_es][i]
        if es != 1.0
            iq[:atkinson][i] = 1.0 - ( iq[:atkinson][i]/total_population )^(1.0/(1.0-es))
        else
            iq[:atkinson][i] = 1.0 - ( iq[:atkinson][i]/y_bar )
        end # e = 1
    end
    iq[:theil] ./= total_population
    return iq
end # make_inequalityinternal

end
