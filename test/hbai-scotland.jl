using PovertyAndInequalityMeasures
using DataFrames,CSV

#
# 
#
datadir="/mnt/data/hbai/tab/"
ginis = []
for y in 1994:2018
    # filenames weirdness .. 
    post = (y in 2002:2016) ? "_g4" : ""
    pre = y >= 2017 ? "h" : "hbai"
    fn = "$(datadir)$(pre)"*"$y"[3:end]*"$(y+1)"[3:end]*"$post.tab"
    print(fn)

    hbai =  CSV.File(fn)|>DataFrame
    lcnames = Symbol.(lowercase.(string.(names(hbai))))
    rename!(hbai, lcnames)
    # scottish subset
    scot = hbai[(hbai.gvtregn .== 12),:]
    # gb subset, since nireland only included 2002-> 
    gb = hbai[(hbai.gvtregn .!== 13),:] 
    print(size(hbai))
    print( size(scot))
    println( size(gb))
    #make scottish ineq with: bhc and ahc incomes; oecd equiv; individual weights
    sco_ineq_bhc = make_inequality( scot,:gs_newpp,:s_oe_bhc )
    sco_ineq_ahc = make_inequality( scot,:gs_newpp,:s_oe_ahc )
    sco_popn = sum( scot.gs_newpp )
    #ditto gb
    gb_ineq_bhc = make_inequality( gb,:gs_newpp,:s_oe_bhc )
    gb_ineq_ahc = make_inequality( gb,:gs_newpp,:s_oe_ahc )
    gb_popn = sum( hbai.gs_newpp )
    push!(ginis,[y,sco_popn,sco_ineq_bhc[:gini],sco_ineq_ahc[:gini],gb_popn,gb_ineq_bhc[:gini],gb_ineq_ahc[:gini]])
    println("$(y) SCO popn=$sco_popn bhc=$(sco_ineq_bhc[:gini]) ahc=$(sco_ineq_ahc[:gini])")
    println("$(y) gb  popn=$gb_popn bhc=$(gb_ineq_bhc[:gini]) ahc=$(gb_ineq_ahc[:gini])")
end

for i in size(ginis)
    println(ginis[i,:])
end