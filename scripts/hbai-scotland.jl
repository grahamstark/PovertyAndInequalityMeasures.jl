using PovertyAndInequalityMeasures
using DataFrames,CSV

#
# An example of using this package to (not quite) reproduce hbai ineq time-series from:
# https://www.gov.uk/government/statistics/households-below-average-income-199495-to-201819
# Data Tables->income-values-and-inequality-measures-hbai-1994-95-2018-19-tables.ods
# -> 2_2tsBHC/AHC 
# using hbai data from UKDS series /UKDA-5828
#
datadir="/mnt/data/hbai/tab/"
ginis = []
for y in 1994:2018
    # filenames weirdness .. 
    post = (y in 2002:2016) ? "_g4" : ""
    pre = y >= 2017 ? "h" : "hbai"
    fn = "$(datadir)$(pre)"*"$y"[3:end]*"$(y+1)"[3:end]*"$post.tab"
    print(fn)
    
    # load each year & jam varnames to lower case
    hbai =  CSV.File(fn)|>DataFrame
    lcnames = Symbol.(lowercase.(string.(names(hbai))))
    rename!(hbai, lcnames)

    # make scottish subset
    scot = hbai[(hbai.gvtregn .== 12),:]
    scot_wages = scot[(scot.egrernhh.>0),:]
    # make gb subset, since nireland only included 2002-> 
    gb = hbai[(hbai.gvtregn .!== 13),:] 
    print(size(hbai))
    print( size(scot))
    println( size(gb))
    #make scottish ineq with: bhc and ahc incomes; oecd equiv; individual weights
    sco_ineq_bhc = make_inequality( scot,:gs_newpp,:s_oe_bhc )
    sco_ineq_ahc = make_inequality( scot,:gs_newpp,:s_oe_ahc )
    # gross wages for hh
    sco_ineq_wage = make_inequality( scot_wages,:gs_newpp,:egrernhh ) # very rough need indiv level really
    sco_popn = sum( scot.gs_newpp )
    #ditto gb
    gb_ineq_bhc = make_inequality( gb,:gs_newpp,:s_oe_bhc )
    gb_ineq_ahc = make_inequality( gb,:gs_newpp,:s_oe_ahc )
    gb_popn = sum( gb.gs_newpp )

    #println("$gb_popn $(gb_ineq_ahc[:total_population])")
    #println("gb bhc $gb_ineq_bhc")
    #println("gb ahc $gb_ineq_ahc")
    println(size(gb))
    @assert gb_popn ≈ gb_ineq_ahc[:total_population]
    push!(ginis,[y,sco_popn,sco_ineq_bhc[:gini],sco_ineq_ahc[:gini],gb_popn,gb_ineq_bhc[:gini],gb_ineq_ahc[:gini]])
    println("$(y) SCO popn=$sco_popn bhc=$(sco_ineq_bhc[:gini]) ahc=$(sco_ineq_ahc[:gini]) wage=$(sco_ineq_wage[:gini])")
    println("$(y) GB  popn=$gb_popn bhc=$(gb_ineq_bhc[:gini]) ahc=$(gb_ineq_ahc[:gini])")
    
end

for i in size(ginis)
    println(ginis[i,:])
end