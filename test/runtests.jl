using PovertyAndInequalityMeasures
using Test

#
# These tests mostly try to replicate examples from
# World Bank 'Handbook on poverty and inequality'
# by Haughton and Khandker
# http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality
#

# ...
primitive type Amount <: AbstractFloat 64 end

const  TOL = 0.00001; # for nearly equal

"
This just creates an array which is `times` vcat copies of `a`
"
function vcn( a :: Array{Float64}, times :: Int64 )
    nrows = size( a )[1]
    ncols = size( a )[2]
    newrows = nrows*times
    out = zeros( Float64, newrows, ncols )
    p = 0
    for row in 1:nrows
        for i in 1:times
            p += 1
            out[p,:] .= a[row,:]
        end
    end
    out
end

NONE=Array{Symbol,1}();

function removeIgnored( d :: Dict{ Symbol, <:Any}, ignore::Array{Symbol,1} ):: Dict{ Symbol, <:Any}
    for i in ignore
        if haskey( d, i )
            delete!( d, i )
        end
    end
    return d;
end

"
element - by element compare of the type of dicts we use for poverty and inequality output
"
function comparedics( left :: Dict{ Symbol, <:Any}, right :: Dict{ Symbol, <:Any}, ignore::Array{Symbol,1} = NONE ) :: Bool
    left  = removeIgnored( left, ignore )
    right = removeIgnored( right, ignore )
    lk = keys( left )
    if lk != keys( right )
        return false
    end
    for k in lk
        # try catch here in case types are way off
        try
            if !( left[k] ≈ right[k] )
                l = left[k]
                r = right[k]
                print( "comparison failed '$k' : left = $l right = $r")
                return false
            end
       catch e
            return false
       end
    end
    return true
end


@testset "WB Chapter 4 - Poverty " begin
    country_a = [ 1.0 100; 1.0 100; 1 150; 1 150 ]
    country_b = copy( country_a )
    country_b[1:2,2] .= 124
    country_c = [ 1.0 100; 1.0 110; 1 150; 1 160 ]
    #
    # Ch 4 doesn't discuss weighting issues, so
    # we'll add some simple checks for that.
    # a_2 and b_2 should be the same as country_a and _b,
    # but with 2 obs of weight 2 rather than 4 of weight 1
    #
    country_a_2 = [2.0 100; 2.0 150 ]
    country_b_2 = [2.0 124; 2.0 150 ]
    # d should be a big version of a and also produce same result
    country_d = vcn( country_a, 50 )
    # attempt to blow things up with huge a clone
    country_d = vcn( country_c, 100_000 )

    # very unbalanced copy of dataset 1 with 10,000 weight1 1:2 and 2 weight 10,000 7:10
    country_e = vcn( country_c[1:2,:], 10_000 )
    cx = copy(country_c[3:4,:])
    cx[:,1] .= 10_000
    country_e = vcat( country_e, cx )

    line = 125.0
    growth = 0.05



    country_a_pov = make_poverty( country_a, line, growth )
    print("country A " );println( country_a_pov )
    country_a_2_pov = make_poverty( country_a_2, line,growth )
    country_b_pov = make_poverty( country_b, line, growth )
    country_c_pov = make_poverty( country_c, line, growth )
    print("country C " );println( country_c_pov )
    country_d_pov = make_poverty( country_d, line, growth )
    print("country D " );println( country_d_pov )
    country_e_pov = make_poverty( country_e, line, growth )
    print("country E " );println( country_e_pov )

    @test comparedics( country_a_pov, country_a_2_pov )
    @test comparedics( country_c_pov, country_e_pov )
    # @test comparedics( country_c_pov, country_d_pov )

    # numbers from WP ch. 4
    @test country_a_pov[:headcount] ≈ 0.5
    @test country_b_pov[:headcount] ≈ 0.5
    @test country_b_pov[:gap] ≈ 1.0/250.0
    @test country_c_pov[:watts] ≈ 0.0877442307
    # some of these are hand-calculations, for from Ada version
    @test isapprox( country_c_pov[:gap], 0.080000, atol = TOL )
    @test isapprox( country_c_pov[:foster_greer_thorndyke][ 1 ], 0.5000000, atol = TOL ) # pov level
    @test isapprox( country_c_pov[:foster_greer_thorndyke][ 2 ], 0.1984059, atol = TOL )
    @test isapprox( country_c_pov[:foster_greer_thorndyke][ 3 ], 0.0800000, atol = TOL )
    @test isapprox( country_c_pov[:foster_greer_thorndyke][ 4 ], 0.0327530, atol = TOL )
    @test isapprox( country_c_pov[:foster_greer_thorndyke][ 5 ], 0.0136000, atol = TOL )
    @test isapprox( country_c_pov[:foster_greer_thorndyke][ 6 ], 0.0057192, atol = TOL )
    @test isapprox( country_c_pov[:sen ], 0.0900000, atol = TOL )
    @test isapprox( country_c_pov[:shorrocks ], 0.0625000, atol = TOL )
    @test isapprox( country_c_pov[:watts ], 0.0877442, atol = TOL )
    @test isapprox( country_c_pov[:time_to_exit ], 1.7548846, atol = TOL )
    @test isapprox( country_c_pov[:gini_amongst_poor ], 0.0238095, atol = TOL )
    @test isapprox( country_c_pov[:poverty_gap_gini ], 0.5625000, atol = TOL )
end # poverty testset

#
# reproduce WB Table 6.3 with various cominations ofweights & data
# note table has errors:
#
#    1. uses log10 not ln for  theil##
#    2. has N in wrong place for ge(2) - outside bracket
#
@testset "WB Chapter 6 - Inequality " begin
    c1 = [1.0 10; 1 15; 1 20; 1 25; 1 40; 1 20; 1 30; 1 35; 1 45; 1 90 ]
    # these next are copies of c1 intended
    # to check we haven't screwed up the weighting
    c2 = vcn( c1, 2 )
    c3 = copy( c1 )
    c3[:,1] .= 10_000.0
    c4 = copy( c1 )
    c4[:,1] .= 2.0
    # very unbalanced copy of dataset 1 with 100,000 weight1 1:6 and 4 weight 100,000 7:10
    c64k = vcn( c1[1:6,:], 100_000 )
    cx = copy(c1[7:10,:])
    cx[:,1] .= 100_000
    c64k = vcat( c64k, cx )
    iq1 = make_inequality( c1 )
    iq2 = make_inequality( c2 )
    iq3 = make_inequality( c3 )
    iq4 = make_inequality( c4 )
    iq64k = make_inequality( c64k )
    # weighting and multiplying should make no difference
    @test comparedics( iq1, iq2, [:total_income, :total_population, :deciles] )
    println( "iq1");println( iq1 )
    println( "iq2");println( iq2 )
    println( "iq3");println( iq3 )
    println( "iq64k");println( iq64k )

    @test comparedics( iq1, iq3, [:total_income, :total_population, :deciles] )
    @test comparedics( iq1, iq4, [:total_income, :total_population, :deciles] )
    @test comparedics( iq1, iq64k, [:total_income, :total_population, :deciles] )
    @test isapprox( iq1[:gini ], 0.3272727, atol = TOL )
    @test isapprox( iq1[:theil][1], 0.1792203, atol = TOL )
    @test isapprox( iq1[:theil][2],  0.1830644, atol = TOL )
    @test isapprox( iq1[:generalised_entropy][ 1 ], 0.1883288, atol = TOL )
    @test isapprox( iq1[:generalised_entropy][ 2 ], 0.1954897, atol = TOL )
    @test isapprox( iq1[:generalised_entropy][ 3 ], 0.2047211, atol = TOL )
    @test isapprox( iq1[:generalised_entropy][ 4 ], 0.2162534, atol = TOL )
    @test isapprox( iq1[:generalised_entropy][ 5 ], 0.2303812, atol = TOL )
    @test isapprox( iq1[:generalised_entropy][ 6 ], 0.2474728, atol = TOL )
    @test isapprox( iq1[:atkinson][ 1 ], 0.0446396, atol = TOL )
    @test isapprox( iq1[:atkinson][ 2 ], 0.0869155, atol = TOL )
    @test isapprox( iq1[:atkinson][ 3 ], 0.1267328, atol = TOL )
    @test isapprox( iq1[:atkinson][ 4 ], 0.1640783, atol = TOL )
    @test isapprox( iq1[:atkinson][ 5 ], 0.1989991, atol = TOL )
    @test isapprox( iq1[:atkinson][ 6 ], 0.2315817, atol = TOL )
    @test isapprox( iq1[:atkinson][ 7 ], 0.2619332, atol = TOL )
    @test isapprox( iq1[:atkinson][ 8 ], 0.2901688, atol = TOL )
    @test isapprox( iq1[:atkinson][ 9 ], 0.3164032, atol = TOL )
    @test isapprox( iq1[:hoover], 0.2363636, atol = TOL )
    print( iq1 )
end # inequality testset
