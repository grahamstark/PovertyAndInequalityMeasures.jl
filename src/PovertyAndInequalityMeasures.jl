module PovertyAndInequalityMeasures

using Base: Real
using IterableTables
using IteratorInterfaceExtensions
using TableTraits
using DataFrames


export DEFAULT_ATKINSON_ES, DEFAULT_ENTROPIES, DEFAULT_FGT_ALPHAS
export make_gini, make_poverty, make_inequality, binify, add_decomposed_theil
export PovertyMeasures, InequalityMeasures, ineqs_equal, povs_equal

const WEIGHT          = 1
const INCOME          = 2
const WEIGHTED_INCOME = 3
const POPN_ACCUM      = 4
const INCOME_ACCUM    = 5
const DEFAULT_FGT_ALPHAS = [ 0.0, 0.50, 1.0, 1.50, 2.0, 2.5 ];
const DEFAULT_ATKINSON_ES = [ 0.25, 0.50, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0, 2.25 ];
const DEFAULT_ENTROPIES = [ 1.25, 1.50, 1.75, 2.0, 2.25, 2.5 ];

mutable struct PovertyMeasures{T<:Real}
    headcount :: T
    gap :: T
    watts :: T
    sen :: T
    shorrocks :: T
    fgt_alphas :: Vector{T}
    foster_greer_thorndyke :: Vector{T}
    time_to_exit :: T
    gini_amongst_poor :: T
    poverty_gap_gini :: T
end


function povs_equal( p1 :: PovertyMeasures, p2 :: PovertyMeasures ) :: Bool
    return (p1.headcount ≈ p2.headcount) &&
        (p1.gap ≈ p2.gap) &&
        (p1.watts ≈ p2.watts) &&
        (p1.sen ≈ p2.sen) &&
        (p1.shorrocks ≈ p2.shorrocks) &&
        (p1.fgt_alphas ≈ p2.fgt_alphas) &&
        (p1.foster_greer_thorndyke ≈ p2.foster_greer_thorndyke) &&
        (p1.time_to_exit ≈ p2.time_to_exit) &&
        (p1.gini_amongst_poor ≈ p2.gini_amongst_poor) &&
        (p1.poverty_gap_gini ≈ p2.poverty_gap_gini)
end


mutable struct InequalityMeasures{T<:Real}
    atkinson_es :: Vector{T}
    atkinson :: Vector{T}
    generalised_entropy_alphas :: Vector{T}
    generalised_entropy :: Vector{T}
    hoover :: T
    theil_l :: T
    theil_t :: T
    
    gini :: T
    palma :: T
    median :: T
    total_income :: T
    average_income :: T
    total_population :: T
    deciles :: Matrix{T}
    negative_or_zero_income_count :: Real
end

function ineqs_equal( i1 :: InequalityMeasures, i2 :: InequalityMeasures; include_populations :: Bool = true ) :: Bool
    eq = ( i1.atkinson_es ≈ i2.atkinson_es ) &&
        ( i1.atkinson ≈ i2.atkinson ) &&
        ( i1.generalised_entropy_alphas ≈ i2.generalised_entropy_alphas ) &&
        ( i1.generalised_entropy ≈ i2.generalised_entropy ) &&
        ( i1.hoover ≈ i2.hoover ) &&
        ( i1.theil_l ≈ i2.theil_l ) &&
        ( i1.theil_t ≈ i2.theil_t ) &&
        ( i1.gini ≈ i2.gini ) &&
        ( i1.palma ≈ i2.palma ) &&
        ( i1.median ≈ i2.median )
    
    if include_populations
        eq2 = ( i1.total_income ≈ i2.total_income ) &&
        ( i1.average_income ≈ i2.average_income ) &&
        ( i1.total_population ≈ i2.total_population ) &&
        ( i1.deciles ≈ i2.deciles )
        eq = eq && eq2
    end
    return eq
end

#
# FIXME this shouldn't need to return a copy!
#
function sortAndAccumulate( 
    aug :: Matrix, sort_data :: Bool, nrows :: Integer )
    if sort_data
        aug = sortslices( aug, alg=QuickSort, dims=1,lt=((x,y)->isless(x[INCOME],y[INCOME])))
    end
    cumulative_weight = 0.0
    cumulative_income = 0.0
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
    incomecol :: Symbol
    ;
    sort_data  :: Bool = true,
    delete_negatives :: Bool = false ) :: Matrix
    @assert TableTraits.isiterabletable( data ) "data needs to implement IterableTables"
    data = DataFrame(data) # this just makes iteration&handling missings easier
    T = eltype( data[!,incomecol] )
    if ! ( T <: AbstractFloat )
	    T = Float64 # jam on some real type regardless of the datatype of the frame if not some type of real
    end
	# better if int then float otherwise leave 
    # 
    # iter = IteratorInterfaceExtensions.getiterator(data)
    nrows = size(data)[1]
    aug = zeros( T, nrows, 5 )
    r = 0
    for row in eachrow(data)
        if ( ismissing( row[weightcol])) || ( ismissing( row[incomecol])) ||
            ( delete_negatives && row[incomecol] < 0.0 )
            ;
        else
            r += 1
            aug[r,WEIGHT] = T(row[weightcol]) 
            aug[r,INCOME] = T(row[incomecol])
            aug[r,WEIGHTED_INCOME] = aug[r,WEIGHT]*aug[r,INCOME]
        end # not missing or negative
    end
    aug = aug[1:r,:]
    return sortAndAccumulate( aug, sort_data, r )
end

"
internal function that makes a sorted array
with cumulative income and population added
"
function make_augmented(
    data            :: Matrix,
    weightpos       :: Integer = 1,
    incomepos       :: Integer = 2;

    sort_data        :: Bool = true,
    delete_negatives :: Bool = false ) :: Matrix
    T = eltype( data )
    if ! ( T <: AbstractFloat )
	    T = Float64 # jam on some real type regardless of the datatype of the data matrix if not some type of real
    end

    nrows = size( data )[1]
    aug = zeros( T, nrows, 5 )
    r = 0
    for row in 1:nrows
        if( delete_negatives && data[row,incomepos] < 0.0 )
            ;
        else
            r += 1
            aug[r,WEIGHT] = data[row,weightpos]
            aug[r,INCOME] = data[row,incomepos]
            aug[r,WEIGHTED_INCOME] = data[row,incomepos]*data[row,weightpos]
        end # not neg or negs accepted
    end # row loop
    return sortAndAccumulate( aug[1:r,:], sort_data, r )
    # return aug[1:r,:]
end

"""
calculate a Gini coefficient on one of our sorted arrays
"""
function make_gini( data :: Matrix ) :: Real
    lorenz = 0.0
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
function make_all_below_line( data :: Matrix, line :: Real ) :: Matrix
    nrows = size( data )[1]
    ncols = size( data )[2]
    T = eltype( data )
    outa = zeros( T, nrows, ncols )
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
    rawdata                       :: Matrix,
    line                          :: Real,
    growth                        :: Real,
    weightpos                     :: Integer = 1,
    incomepos                     :: Integer = 2,
    foster_greer_thorndyke_alphas :: Vector = DEFAULT_FGT_ALPHAS ) :: PovertyMeasures

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
    foster_greer_thorndyke_alphas :: Vector = DEFAULT_FGT_ALPHAS,
     ) :: PovertyMeasures
    @assert TableTraits.isiterabletable( rawdata ) "data needs to implement IterableTables"
    data = make_augmented( rawdata, weightcol, incomecol )
    make_povertyinternal(
        data = data,
        line = line,
        growth = growth,
        foster_greer_thorndyke_alphas = foster_greer_thorndyke_alphas )
end

function calc_positive_inc_popn( data :: Matrix ) :: Real
    pinc = 0.0
    nrows = size( data )[1]
    for r in 1:nrows
        if data[r,INCOME] > 0
            pinc += data[r,WEIGHT]
        end
    end
    return pinc;
end # postive_inc_population


"""
Internal version, once we have our datatset
"""
function make_povertyinternal(
    ;
    data                          :: Matrix,
    line                          :: Real,
    growth                        :: Real = 0.0,
    foster_greer_thorndyke_alphas :: Vector = DEFAULT_FGT_ALPHAS ) :: PovertyMeasures
   
    nfgs = size( foster_greer_thorndyke_alphas )[1]
    T = eltype( foster_greer_thorndyke_alphas )
    z = zero(T)
    pv = PovertyMeasures( 
        z, 
        z, 
        z, 
        z, 
        z, 
        foster_greer_thorndyke_alphas, 
        zeros( nfgs ), 
        z, 
        z, 
        z ) 
    
    nrows = size( data )[1]
    ncols = size( data )[2]
    population = data[ nrows, POPN_ACCUM ]
    total_income = data[ nrows, INCOME_ACCUM ]
    positive_inc_popn = calc_positive_inc_popn( data )
    
    @assert ncols == 5 "data should have 5 cols"

    belowline = make_all_below_line( data, line )
    nbrrows = size( belowline )[1]

    pv.gini_amongst_poor = make_gini( belowline )
    for row in 1:nbrrows
        inc :: T= belowline[row,INCOME]
        weight :: T = belowline[row,WEIGHT]
        gap :: T = line - inc
        @assert gap >= 0 "poverty gap must be postive"
        pv.headcount  += weight
        pv.gap  += weight*gap/line
        if belowline[row,INCOME ] > 0
            pv.watts  += weight*log(line/inc)
        end
        for p in 1:nfgs
            fg = foster_greer_thorndyke_alphas[p]
            pv.foster_greer_thorndyke[p] += weight*((gap/line)^fg)
        end
    end # main loop
    pv.watts /= population
    if growth > 0.0
        pv.time_to_exit = pv.watts/growth
    end
    pv.gap /= population
    pv.headcount /= population
    pv.foster_greer_thorndyke ./= population
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
    gdata = zeros( T, nrows, 5 )
    for row in 1:nrows
        gap = max( 0.0, line - data[row,INCOME] )
        gpos = nrows - row + 1
        gdata[gpos,INCOME] = gap;
        gdata[gpos,WEIGHT] = data[row,WEIGHT]
    end
    gdata = make_augmented( gdata, 1, 2, sort_data=false )
    pv.poverty_gap_gini = make_gini( gdata )

    pv.sen = pv.headcount*pv.gini_amongst_poor+pv.gap*(1.0-pv.gini_amongst_poor)
    pv.shorrocks  = pv.headcount*pv.gap*(1.0+pv.poverty_gap_gini)
    return pv
end # make_poverty

"""
Make a wee dict with :theil_between and :theil_within
See WB eqns 6.7/6.8.
TODO
1. there are some papers on decomposing Atkinson, but I
don't understand them ..
2. the over time 3-part version

 popindc : Inequal for the population as a whole
 subindices : an array of dics, one for each subgroup of interest
"""
function add_decomposed_theil( popindc :: InequalityMeasures, subindices :: Vector{InequalityMeasures} ) :: NamedTuple
    popn = popindc.total_population 
    income = popindc.total_income 
    avinc = popindc.average_income 
    within_l = 0.0
    within_t = 0.0
    
    between_l = 0.0
    between_t = 0.0
    totalpop = 0.0
    totalinc = 0.0
    for ind in subindices
        popshare = ind.total_population/popn
        incshare = ind.total_income/income
        totalpop += popshare
        totalinc += incshare

        within_l += ind.theil_l*popshare
        between_l += popshare*log(avinc/ind.average_income)

        within_t += ind.theil_t*incshare
        between_t += incshare*log(incshare/popshare)
    end
    @assert totalpop ≈ 1.0
    @assert totalinc ≈ 1.0
    @assert within_l+between_l ≈ popindc.theil_l  "within_l=$(within_l) between_l=$(between_l) ≈ popindc.theil_l=$(popindc.theil_l) "   
    @assert within_t+between_t ≈ popindc.theil_t "within_t=$(within_t) between_t=$(between_t) ≈ popindc.theil_t=$(popindc.theil_t) "    
    ( between_l = between_l, within_l = within_l,  between_t = between_t, within_t = within_t)
end

"""
Make a struct of inequality measures.
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

Also in the struct are:

* `total_income`
* `total_population`
* `average_income`
* `deciles`.


"""
function make_inequality(
    rawdata                    :: Matrix,
    weightpos                  :: Integer = 1,
    incomepos                  :: Integer = 2,
    atkinson_es                :: Vector{<:AbstractFloat} = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: Vector{<:AbstractFloat} = DEFAULT_ENTROPIES ) :: InequalityMeasures
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
    atkinson_es                :: Vector{<:AbstractFloat} = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: Vector{<:AbstractFloat} = DEFAULT_ENTROPIES ) :: InequalityMeasures
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
    rawdata   :: Matrix,
    numbins   :: Integer,
    weightpos :: Integer = 1,
    incomepos :: Integer = 2 ) :: Matrix
    data = make_augmented( rawdata, weightpos, incomepos )
    return binifyinternal( data, numbins )
end

"""
As above, but using any DataFrame like thing that supports the TableTraits.isiterabletable interface
"""
function binify(
    rawdata,
    numbins   :: Integer,
    weightcol :: Symbol,
    incomecol :: Symbol ) :: Matrix
    @assert TableTraits.isiterabletable( rawdata ) "data needs to implement IterableTables"
    data = make_augmented( rawdata, weightcol, incomecol )
    return binifyinternal( data, numbins )
end

## FIXME this can go horribly wrong with small unbalanced numbers of rows -
# try pop=[22,1,1,1,1,1,1,1,1,1 inc==[1,2,2,2,2,2,2,2,2,2]
function binifyinternal(
    data      :: Matrix,
    numbins   :: Integer ) :: Matrix
    T = eltype( data )
    
    nrows = size( data )[1]
    ncols = size( data )[2]
    out = zeros( T, numbins, 3 )
    total_population = data[ nrows, POPN_ACCUM ]
    total_income = data[ nrows, INCOME_ACCUM ]
    bin_size :: T = 1.0/numbins
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
    data                       :: Matrix,
    atkinson_es                :: Vector = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: Vector = DEFAULT_ENTROPIES ) :: InequalityMeasures
    nrows = size( data )[1]
    ncols = size( data )[2]
    @assert ncols == 5 "data should have 5 cols but has $ncols"
    T = eltype( generalised_entropy_alphas )
    z = zero(T)
    nats = size( atkinson_es )[1]
    neps = size( generalised_entropy_alphas )[1]
    iq =InequalityMeasures( 
        atkinson_es, 
        [i == 1.0 ? 1.0 : 0.0 for i in atkinson_es], 
        generalised_entropy_alphas, 
        zeros(T,neps),
        z,
        z,
        z,
        z,
        z,
        z,
        z,
        z,
        z,
        zeros( T, 10, 3 ),
        0 )
        
    # initialise atkinsons; 1 for e = 1 0 otherwise
    
    iq.gini = make_gini( data )
    positive_inc_popn = calc_positive_inc_popn( data )
    total_income = data[nrows,INCOME_ACCUM]
    total_population = data[nrows,POPN_ACCUM]
    y_bar = total_income/total_population
    iq.total_income = total_income
    iq.total_population = total_population
    iq.average_income = y_bar
    popsharelast = 0.0
    incomelast = 0.0
    for row in 1:nrows
        income = data[row,INCOME]
        weight = data[row,WEIGHT]
        y_yb  :: T = income/y_bar
        yb_y  :: T = y_bar/income
        iq.hoover += weight*abs( income - y_bar )
        # atkinson kinda sorta needs
        # to be over +ives only since otherwise atk(1) = 1 always
        # since the inner sum goes to 0
        if income > 0.0
	    for i in 1:neps
            	alpha :: T = iq.generalised_entropy_alphas[i]
            	iq.generalised_entropy[i] += weight*(y_yb^alpha)
            end # entropies
            ln_y_yb :: T = log( y_yb )
            ln_yb_y :: T = log( yb_y )
            iq.theil_l += weight*ln_yb_y
            iq.theil_t += weight*y_yb*ln_y_yb
            for i in 1:nats
                es :: T = iq.atkinson_es[i]
                if es != 1.0
                    iq.atkinson[i] += weight*(y_yb^(1.0-es))
                else
                    iq.atkinson[i] *= (income)^(weight/positive_inc_popn)
                end # e = 1 case
            end # atkinsons
        else
            iq.negative_or_zero_income_count += weight
        end # positive income
    end # main loop
    
    @assert (iq.negative_or_zero_income_count + positive_inc_popn) ≈ iq.total_population "nzc $(iq.negative_or_zero_income_count) pip $positive_inc_popn tp $(iq.total_population)"
    deciles = binify( data, 10 )
    iq.median = deciles[5,3]
    # top 10/bottom 40
    if deciles[4,2] > 0
        iq.palma = (1.0-deciles[9,2])/deciles[4,2]
    end
    iq.deciles = deciles
    iq.hoover /= 2.0*total_income
    for i in 1:neps
        alpha :: T = iq.generalised_entropy_alphas[i]
        aq :: T = (1.0/(alpha*(alpha-1.0)))
        iq.generalised_entropy[i] =
            aq*((iq.generalised_entropy[i]/iq.total_population)-1.0)
    end # entropies
    for i in 1:nats
        es :: T = iq.atkinson_es[i]
        if es != 1.0
            iq.atkinson[i] = 1.0 - ( iq.atkinson[i]/positive_inc_popn)^(1.0/(1.0-es))
        else
            iq.atkinson[i] = 1.0 - ( iq.atkinson[i]/y_bar )
        end # e = 1
    end
    iq.theil_l /= positive_inc_popn
    iq.theil_t /= positive_inc_popn
    return iq
end # make_inequalityinternal

end
