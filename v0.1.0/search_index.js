var documenterSearchIndex = {"docs":
[{"location":"#","page":"Home","title":"Home","text":"CurrentModule = PovertyAndInequalityMeasures","category":"page"},{"location":"#PovertyAndInequalityMeasures-1","page":"Home","title":"PovertyAndInequalityMeasures","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"This generates various measures poverty and inequality from a sample dataset.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"The measures are mostly taken from chs. 4-6 of the World Banks' Handbook on Poverty and Inequality.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"See the test case for worked examples","category":"page"},{"location":"#Poverty:-1","page":"Home","title":"Poverty:","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"These routines can use both 2d arrays and dataframes as inputs For the arrays, supply with integers giving the columns holding weights and incomes; for the frames, the names of the columns (as symbols).","category":"page"},{"location":"#","page":"Home","title":"Home","text":"\nfunction makepoverty(\n    rawdata                       :: Array{<:Real, 2},\n    line                          :: Real,\n    growth                        :: Real,\n    weightpos                     :: Integer = 1,\n    incomepos                     :: Integer = 2,\n    foster_greer_thorndyke_alphas :: AbstractArray{<:Real, 1} = DEFAULT_FGT_ALPHAS ) :: OutputDict\n\nfunction makepoverty(\n    rawdata,\n    line                          :: Real,\n    growth                        :: Real,\n    weightcol                     :: Symbol,\n    incomecol                     :: Symbol,\n    foster_greer_thorndyke_alphas :: AbstractArray{<:Real, 1} = DEFAULT_FGT_ALPHAS,\n     ) :: OutputDict    \n","category":"page"},{"location":"#","page":"Home","title":"Home","text":"notes:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"rawdata - each row is an observation; one col should be a weight, another is income;","category":"page"},{"location":"#","page":"Home","title":"Home","text":"positions assumed to be 1 and 2 unless weight and incomepos are supplied (or names as symbols for the frame version)","category":"page"},{"location":"#","page":"Home","title":"Home","text":"the dataframe version can use anything that supports the Queryverse iterable table interface;\nline - a poverty line. This is the same for for all observations, the income measure needs to be equivalised if the line differs by family size, etc.;\nfoster_greer_thorndyke_alphas - coefficients for Foster-Greer Thorndyke poverty measures (see World Bank, ch. 4); note that FGT(0)","category":"page"},{"location":"#","page":"Home","title":"Home","text":"corresponds to the headcount measure and FGT(1) to poverty gap; count and gap are computed directly anyway but it's worth checking one against the other;","category":"page"},{"location":"#","page":"Home","title":"Home","text":"growth is (e.g.) 0.01 for 1% per period, and is used for 'time to exit' measure.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Output is  dictionary with an entry for each measure.","category":"page"},{"location":"#Inequality-1","page":"Home","title":"Inequality","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Usage is similar to makepoverty above. See chs 5 and 6 of the World Bank book, and the test case for more detail.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Version1:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"\nfunction makeinequality(\n    rawdata                    :: Array{<:Real, 2 },\n    weightpos                  :: Integer = 1,\n    incomepos                  :: Integer = 2,\n    atkinson_es                :: AbstractArray{<:Real, 1} = DEFAULT_ATKINSON_ES,\n    generalised_entropy_alphas :: AbstractArray{<:Real, 1} = DEFAULT_ENTROPIES ) :: OutputDict\n\nfunction makeinequality(\n    rawdata,\n    weightcol                  :: Symbol,\n    incomecol                  :: Symbol,\n    atkinson_es                :: AbstractArray{<:Real, 1} = DEFAULT_ATKINSON_ES,\n    generalised_entropy_alphas :: AbstractArray{<:Real, 1} = DEFAULT_ENTROPIES ) :: OutputDict\n\n","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Notes:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"rawdata a matrix with cols with weights and incomes;\natkinson_es inequality aversion values for the Atkinson indexes;\ngeneralised_entropy_alphas vaues for Theil entropy measure;\nweightpos - column with weights\nincomepos - column with incomes","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Return is a also a Dict of inequality measures.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"There's also a method:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"function adddecomposedtheil( popindic :: OutputDict, subindices :: OutputDictArray ) :: OutputDict","category":"page"},{"location":"#","page":"Home","title":"Home","text":"which takes an array of output dicts, broken down by (e.g.) Regions, Genders, etc. and produces a Theil index decomposition from them.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"There's also a small binify routine which chops a dataset up into chunks of cumulative income and population suitable for drawing Lorenz Curves.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Modules = [PovertyAndInequalityMeasures]\n[:constant, :type, :function]","category":"page"},{"location":"#PovertyAndInequalityMeasures.add_decomposed_theil-Tuple{Dict{Symbol,Any},Array{Dict{Symbol,Any},1}}","page":"Home","title":"PovertyAndInequalityMeasures.add_decomposed_theil","text":"Make a wee dict with :theilbetween and :theilwithin See WB eqns 6.7/6.8. TODO\n\nthere are some papers on decomposing Atkinson, but I\n\ndon't understand them ..\n\nthe over time 3-part version\n\npopindic : Inequal for the population as a whole  subindices : an array of dics, one for each subgroup of interest\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.binify","page":"Home","title":"PovertyAndInequalityMeasures.binify","text":"Chop a dataset with populations and incomes into numbins groups in a form suitable for e.g. a Gini curve.\n\ncol1 is cumulative population,\n2 cumulative income/whatever,\n3 threshold income level.\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.binify-Tuple{Any,Integer,Symbol,Symbol}","page":"Home","title":"PovertyAndInequalityMeasures.binify","text":"As above, but using any DataFrame like thing that supports the TableTraits.isiterabletable interface\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.make_gini-Tuple{Array{Float64,2}}","page":"Home","title":"PovertyAndInequalityMeasures.make_gini","text":"calculate a Gini coefficient on one of our sorted arrays\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.make_inequality","page":"Home","title":"PovertyAndInequalityMeasures.make_inequality","text":"As above but using the iterable table interface; see: https://github.com/queryverse/IterableTables.jl weightcol and incomecol are names of columns\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_inequality","page":"Home","title":"PovertyAndInequalityMeasures.make_inequality","text":"Make a dictionary of inequality measures. This is mainly taken from chs 5 and 6 of the World Bank book.\n\nrawdata a matrix with cols with weights and incomes\natkinson_es inequality aversion values for the Atkinson indexes\ngeneralised_entropy_alphas\nweightpos - column with weights\nincomepos - column with incomes\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_poverty","page":"Home","title":"PovertyAndInequalityMeasures.make_poverty","text":"As above, but using the QueryVerse IterableTables interface rawdata - basically anything resembling a dataframe; see: [https://github.com/queryverse/IterableTables.jl] throws an exception if rawdata doesn't support iterabletable interface\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_poverty","page":"Home","title":"PovertyAndInequalityMeasures.make_poverty","text":"Create a dictionary of poverty measures.\n\nThis is based on the World Bank's Poverty Handbook by  Haughton and Khandker.\n\nArguments:\n\nrawdata - an nxm array of real nunbers; each row is an observation; one col should be a weight, another is income;  positions assumed to be 1 and 2 unless weight and incomepos are supplied\nline - a poverty line, assumed same for all obs (so income is assumed to be already equivalised)\nfoster_greer_thorndyke_alphas - coefficients for FGT poverty measures; note that FGT(0)  corresponds to headcount and FGT(1) to gap; count and gap are computed directly anyway  but it's worth checking one against the other.\ngrowth is (e.g.) 0.01 for 1% per period, and is used for 'time to exit' measure.\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_all_below_line-Tuple{Array{Float64,2},Float64}","page":"Home","title":"PovertyAndInequalityMeasures.make_all_below_line","text":"generate a subset of one of our datasets with just the elements whose incomes are below the line. Probably possible in 1 line, once I get the hang of this a bit more.\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.make_augmented","page":"Home","title":"PovertyAndInequalityMeasures.make_augmented","text":"internal function that makes a sorted array with cumulative income and population added\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_augmented","page":"Home","title":"PovertyAndInequalityMeasures.make_augmented","text":"internal function that makes a sorted array with cumulative income and population added\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_inequalityinternal-Tuple{}","page":"Home","title":"PovertyAndInequalityMeasures.make_inequalityinternal","text":"Make a dictionary of inequality measures. This is mainly taken from chs 5 and 6 of the World Bank book.\n\nrawdata a matrix with cols with weights and incomes\natkinson_es inequality aversion values for the Atkinson indexes\ngeneralised_entropy_alphas\nweightpos - column with weights\nincomepos - column with incomes\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.make_povertyinternal-Tuple{}","page":"Home","title":"PovertyAndInequalityMeasures.make_povertyinternal","text":"Internal version, once we have our datatset\n\n\n\n\n\n","category":"method"},{"location":"#Bibliography-1","page":"Home","title":"Bibliography","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Cobham Alex, and Sumner Andy. “Is Inequality All about the Tails?: The Palma Measure of Income Inequality.” Significance 11, no. 1 (February 19, 2014): 10–13. https://doi.org/10.1111/j.1740-9713.2014.00718.x.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Haughton, Jonathan, and Shahidur R. Khandker. ‘Handbook on Poverty and Inequality’. The World Bank, 27 March 2009. http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Preston, Ian. ‘Inequality and Income Gaps’. IFS Working Paper. Institute for Fiscal Studies, 5 December 2006. https://econpapers.repec.org/paper/ifsifsewp/06_2f25.htm.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Reed, Howard, and Graham Stark. ‘Tackling Child Poverty Delivery Plan - Forecasting Child Poverty in Scotland’. Scottish Government, 9 March 2018. http://www.gov.scot/Publications/2018/03/2911/0.","category":"page"}]
}