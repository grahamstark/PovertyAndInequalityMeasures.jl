using PovertyAndInequalityMeasures
using DataFrames
#
# Note that CSV and Plots are *not* dependencies of 
# this project. You'll need to copy this file out
# of the package tree and install Plots and CSV manually.
#
using Plots, CSV
#
# An example of using this package to (not quite) reproduce hbai ineq time-series from:
# https://www.gov.uk/government/statistics/households-below-average-income-199495-to-201819
# for GB and also Scotland, for income and also wages.
# See: 
# Data Tables->income-values-and-inequality-measures-hbai-1994-95-2018-19-tables.ods
# sheets 2_2tsBHC/AHC 
#
# We're using hbai household level data data 1994/5->2018/19 from [UKDS](https://www.ukdataservice.ac.uk/) 
# (series UKDA-5828).
# 
# .. change this, obvs:
datadir="/mnt/data/hbai/tab/"
start_year = 1994
end_year = 2018
n = end_year - start_year + 1
out=DataFrame( 
    year=zeros(Int,n), 
    scot_pop=zeros(n),
    sco_gini_bhc=zeros(n),
    sco_gini_ahc=zeros(n),
    sco_gini_wage=zeros(n),
    sco_palma_bhc=zeros(n),
    sco_palma_ahc=zeros(n),
    gb_pop=zeros(n),
    gb_gini_bhc=zeros(n), 
    gb_gini_ahc=zeros(n), 
    gb_palma_bhc=zeros(n),
    gb_palma_ahc=zeros(n),
    sco_atkinson_ahc_1=zeros(n),    
    sco_atkinson_bhc_1=zeros(n),
    sco_atkinson_ahc_2=zeros(n),    
    sco_atkinson_bhc_2=zeros(n)
    )

r = 0
for y in start_year:end_year
    # filenames weirdness .. 
    global r
    r += 1
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
    # sub-subset with just positive wages for hhlds - crude measure of
    # wage inequality - better to use individual level series
    scot_wages = scot[(scot.egrernhh.>0),:]
    # make gb subset, since nireland included from 2002 on, but not before  
    gb = hbai[(hbai.gvtregn .!== 13),:] 
    print(size(hbai))
    print( size(scot))
    println( size(gb))
    #make scottish ineq with: bhc and ahc incomes; oecd equiv; individual weights
    sco_ineq_bhc = make_inequality( scot,:gs_newpp,:s_oe_bhc )
    sco_ineq_ahc = make_inequality( scot,:gs_newpp,:s_oe_ahc )
    # inequality of gross wages for hh
    sco_ineq_wage = make_inequality( scot_wages,:gs_newpp,:egrernhh ) # very rough need indiv level really
    sco_popn = sum( scot.gs_newpp )
    #ditto gb
    gb_ineq_bhc = make_inequality( gb,:gs_newpp,:s_oe_bhc )
    gb_ineq_ahc = make_inequality( gb,:gs_newpp,:s_oe_ahc )
    gb_popn = sum( gb.gs_newpp )
    @assert gb_popn ≈ gb_ineq_ahc[:total_population]
    
    out[r, :year] = y
    out[r,:scot_pop] = sco_popn
    out[r, :sco_gini_bhc] = sco_ineq_bhc[:gini]
    out[r, :sco_gini_ahc] = sco_ineq_ahc[:gini]
    out[r, :sco_gini_wage] = sco_ineq_wage[:gini]
    out[r, :gb_pop] = gb_popn
    out[r, :gb_gini_bhc] = gb_ineq_bhc[:gini]
    out[r, :gb_gini_ahc] =  gb_ineq_ahc[:gini]
    out[r, :sco_palma_bhc] = sco_ineq_bhc[:palma]
    out[r, :sco_palma_ahc] = sco_ineq_ahc[:palma]
    out[r, :gb_palma_bhc] = gb_ineq_bhc[:palma]
    out[r, :gb_palma_ahc] = sco_ineq_ahc[:palma]
    out[r, :sco_atkinson_ahc_1] = sco_ineq_ahc[:atkinson][4]
    out[r, :sco_atkinson_bhc_1] = sco_ineq_bhc[:atkinson][4]
    out[r, :sco_atkinson_ahc_2] = sco_ineq_ahc[:atkinson][8]    
    out[r, :sco_atkinson_bhc_2] = sco_ineq_bhc[:atkinson][8]


    println("$(y) SCO popn=$sco_popn bhc=$(sco_ineq_bhc[:gini]) ahc=$(sco_ineq_ahc[:gini]) wage=$(sco_ineq_wage[:gini])")
    println("$(y) GB  popn=$gb_popn bhc=$(gb_ineq_bhc[:gini]) ahc=$(gb_ineq_ahc[:gini])")
    
end

plot(out[:year],[out[:sco_gini_ahc],out[:sco_gini_bhc]])
# .. and so on