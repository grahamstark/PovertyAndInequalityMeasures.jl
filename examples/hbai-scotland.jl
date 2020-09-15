using PovertyAndInequalityMeasures
using DataFrames
#
# Note that CSV and Plots are *not* dependencies of 
# this project. You'll need to copy this file out
# of the package tree and install Plots and CSV manually.
#
using Plots, CSV
#pgfplotsx()
#pgfplotsx()
#Plots.PGFPlotsXBackend()
# using PyPlot 
pyplot()
Plots.PyPlotBackend()
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
    sco_palma_bhc=zeros(n),
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
    global r
    r += 1
    # filenames weirdness .. 
    post = (y in 2002:2016) ? "_g4" : ""
    pre = y >= 2017 ? "h" : "hbai"
    fn = "$(datadir)$(pre)"*"$y"[3:end]*"$(y+1)"[3:end]*"$post.tab"
    println(fn)
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
    # make scottish ineq with: bhc and ahc incomes; oecd equiv; individual weights
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
    out[r, :scot_pop] = sco_popn
    out[r, :sco_gini_bhc] = sco_ineq_bhc[:gini]
    out[r, :sco_gini_ahc] = sco_ineq_ahc[:gini]
    out[r, :sco_gini_wage] = sco_ineq_wage[:gini]
    out[r, :gb_pop] = gb_popn
    out[r, :gb_gini_bhc] = gb_ineq_bhc[:gini]
    out[r, :gb_gini_ahc] =  gb_ineq_ahc[:gini]
    out[r, :sco_palma_bhc] = sco_ineq_bhc[:palma]
    out[r, :sco_palma_ahc] = sco_ineq_ahc[:palma]
    out[r, :gb_palma_bhc] = gb_ineq_bhc[:palma]
    out[r, :gb_palma_ahc] = gb_ineq_ahc[:palma]
    out[r, :sco_atkinson_ahc_1] = sco_ineq_ahc[:atkinson][4]
    out[r, :sco_atkinson_bhc_1] = sco_ineq_bhc[:atkinson][4]
    out[r, :sco_atkinson_ahc_2] = sco_ineq_ahc[:atkinson][8]    
    out[r, :sco_atkinson_bhc_2] = sco_ineq_bhc[:atkinson][8]
end

out.snp = out.year .>= 2007 # snp dummy

gini = plot( 
    out.year,
    [out.sco_gini_ahc,out.sco_gini_bhc],
    title="Scotland: Gini",
    ylims=(0,1),
    labels=["AHC" "BHC"])

palma = plot( 
    out.year,
    [out.sco_palma_ahc,out.sco_palma_bhc],
    title="Scotland: Palma",
    ylims=(1,2),
    labels=["AHC" "BHC"])

wage  = plot( 
    out.year,
    [out.sco_gini_wage],
    title="Scotland: Wage Gini",
    ylims=(0,1),
    labels="Wages")

atkin = plot( 
    out.year,
    [out.sco_atkinson_ahc_1, out.sco_atkinson_bhc_1, 
        out.sco_atkinson_ahc_2, out.sco_atkinson_bhc_2 ],
    title="Atkinson α=1,2",
    labels=["AHC α=1" "BHC α=1" "AHC α=2" "BHC α=2"])

sc_gb_gini = plot( 
    out.year,
    [out.sco_gini_ahc, out.sco_gini_bhc, out.gb_gini_ahc, out.gb_gini_bhc],
    title="Scotland vs GB (Gini)",
    labels=[ "Sco:AHC" "Sco:BHC" "GB:AHC" "GB:BHC"])
    
grid = plot( gini, palma, wage, sc_gb_gini, layout = (2, 2), 
    legend = :outerbottomright,
    size=(1024,640), 
    # legendfontsize=6,
    titlefontsize=8 )
# .. and so on

savefig(grid, "~/tmp/scotland_inequality.svg" )

savefig(grid, "~/tmp/scotland_inequality.png")

savefig(grid, "~/tmp/scotland_inequality.pdf" )

using StatsKit
using RegressionTables
sco_gini_r1 = GLM.lm( @formula( sco_gini_ahc ~ year ), out )
sco_gini_r2 = GLM.lm( @formula( sco_gini_bhc ~ year ), out )
sco_gini_r3 = GLM.lm( @formula( sco_gini_ahc ~ year+snp ), out )
sco_gini_r4 = GLM.lm( @formula( sco_gini_bhc ~ year+snp ), out )
sco_gini_r5 = GLM.lm( @formula( log(sco_gini_ahc) ~ year ), out )
sco_gini_r6 = GLM.lm( @formula( log(sco_gini_bhc) ~ year ), out )
sco_gini_r7 = GLM.lm( @formula( log(sco_gini_ahc) ~ year+snp ), out )
sco_gini_r8 = GLM.lm( @formula( log(sco_gini_bhc) ~ year+snp ), out )

sco_palma_r1 = GLM.lm( @formula( sco_palma_ahc ~ year ), out )
sco_palma_r2 = GLM.lm( @formula( sco_palma_bhc ~ year ), out )
sco_palma_r3 = GLM.lm( @formula( sco_palma_ahc ~ year+snp ), out )
sco_palma_r4 = GLM.lm( @formula( sco_palma_bhc ~ year+snp ), out )
sco_palma_r5 = GLM.lm( @formula( log(sco_palma_ahc) ~ year ), out )
sco_palma_r6 = GLM.lm( @formula( log(sco_palma_bhc) ~ year ), out )
sco_palma_r7 = GLM.lm( @formula( log(sco_palma_ahc) ~ year+snp ), out )
sco_palma_r8 = GLM.lm( @formula( log(sco_palma_bhc) ~ year+snp ), out )

regtable( sco_gini_r1, sco_gini_r2, sco_gini_r3, sco_gini_r4 )

# regtable( sco_gini_r5, sco_gini_r6, sco_gini_r7, sco_gini_r8 )
regtable( sco_palma_r1, sco_palma_r2, sco_palma_r3, sco_palma_r4 )
#regtable( sco_palma_r5, sco_palma_r6, sco_palma_r7, sco_palma_r8 )