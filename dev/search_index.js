var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = PovertyAndInequalityMeasures","category":"page"},{"location":"#PovertyAndInequalityMeasures","page":"Home","title":"PovertyAndInequalityMeasures","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This generates various measures poverty and inequality from a sample dataset.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The measures are mostly taken from chs. 4-6 of the World Banks' Handbook on Poverty and Inequality.","category":"page"},{"location":"","page":"Home","title":"Home","text":"See the test case for worked examples","category":"page"},{"location":"","page":"Home","title":"Home","text":"Poverty measures are:","category":"page"},{"location":"","page":"Home","title":"Home","text":"headcount;\ngap;\nFoster Greer Thorndyke, for each of the values in foster_greer_thorndyke_alphas - note that α=0 is headcount and α=1 is gap;\nWatts;\ntime to exit, for the supplied growth rate;\nShorrocks;\nSen.","category":"page"},{"location":"","page":"Home","title":"Home","text":"See WB ch. 4 on these measures.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Inequality Measures Are:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Gini;\nAtkinson, for each value in atkinson_es;\nTheil;\ngeneralised_entropy;\nHoover;\nTheil;\nPalma.","category":"page"},{"location":"","page":"Home","title":"Home","text":"See World Bank chs. 5 an 6, and Cobham and Sumner on the Palma. Also returned by the inequality function are:","category":"page"},{"location":"","page":"Home","title":"Home","text":"total_income\ntotal_population\naverage_income\ndeciles.","category":"page"},{"location":"","page":"Home","title":"Home","text":"There's also a small binify routine which chops a dataset up into chunks of cumulative income and population suitable for drawing Lorenz Curves.","category":"page"},{"location":"#Index","page":"Home","title":"Index","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [PovertyAndInequalityMeasures]\n[:constant, :type, :function]","category":"page"},{"location":"#PovertyAndInequalityMeasures.add_decomposed_theil-Tuple{InequalityMeasures, Vector{InequalityMeasures}}","page":"Home","title":"PovertyAndInequalityMeasures.add_decomposed_theil","text":"Make a wee dict with :theilbetween and :theilwithin See WB eqns 6.7/6.8. TODO\n\nthere are some papers on decomposing Atkinson, but I\n\ndon't understand them ..\n\nthe over time 3-part version\n\npopindc : Inequal for the population as a whole  subindices : an array of dics, one for each subgroup of interest\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.binify","page":"Home","title":"PovertyAndInequalityMeasures.binify","text":"Chop a dataset with populations and incomes into numbins groups in a form suitable for e.g. a Gini curve.\n\ncol1 is cumulative population,\n2 cumulative income/whatever,\n3 threshold income level.\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.binify-Tuple{Any, Integer, Symbol, Symbol}","page":"Home","title":"PovertyAndInequalityMeasures.binify","text":"As above, but using any DataFrame like thing that supports the TableTraits.isiterabletable interface\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.make_all_below_line-Tuple{Matrix, Real}","page":"Home","title":"PovertyAndInequalityMeasures.make_all_below_line","text":"generate a subset of one of our datasets with just the elements whose incomes are below the line. Probably possible in 1 line, once I get the hang of this a bit more.\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.make_augmented","page":"Home","title":"PovertyAndInequalityMeasures.make_augmented","text":"internal function that makes a sorted array with cumulative income and population added\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_augmented-Tuple{Any, Symbol, Symbol}","page":"Home","title":"PovertyAndInequalityMeasures.make_augmented","text":"internal function that makes a sorted array with cumulative income and population added\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.make_gini-Tuple{Matrix}","page":"Home","title":"PovertyAndInequalityMeasures.make_gini","text":"calculate a Gini coefficient on one of our sorted arrays\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.make_inequality","page":"Home","title":"PovertyAndInequalityMeasures.make_inequality","text":"Make a struct of inequality measures. This is mainly taken from chs 5 and 6 of the World Bank book.\n\nrawdata a matrix with cols with weights and incomes\natkinson_es inequality aversion values for the Atkinson indexes\ngeneralised_entropy_alphas\nweightpos - column with weights\nincomepos - column with incomes\n\nReturned is a Dict of inequality measures with:\n\nGini;\nAtkinson, for each value in atkinson_es;\nTheil;\ngeneralised_entropy;\nHoover;\nTheil;\nPalma.\n\nSee WB chs 5 an 6, and Cobham and Sumner on the Palma.\n\nAlso in the struct are:\n\ntotal_income\ntotal_population\naverage_income\ndeciles.\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_inequality-2","page":"Home","title":"PovertyAndInequalityMeasures.make_inequality","text":"As above but using the iterable table interface; see: https://github.com/queryverse/IterableTables.jl weightcol and incomecol are names of columns\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_inequalityinternal-Tuple{}","page":"Home","title":"PovertyAndInequalityMeasures.make_inequalityinternal","text":"Make a dictionary of inequality measures. This is mainly taken from chs 5 and 6 of the World Bank book.\n\nrawdata a matrix with cols with weights and incomes\natkinson_es inequality aversion values for the Atkinson indexes\ngeneralised_entropy_alphas\nweightpos - column with weights\nincomepos - column with incomes\n\n\n\n\n\n","category":"method"},{"location":"#PovertyAndInequalityMeasures.make_poverty","page":"Home","title":"PovertyAndInequalityMeasures.make_poverty","text":"Create a dictionary of poverty measures.\n\nThis is based on the World Bank's Poverty Handbook by  Haughton and Khandker.\n\nArguments:\n\nrawdata - an nxm array of real nunbers; each row is an observation; one col should be a weight, another is income;  positions assumed to be 1 and 2 unless weight and incomepos are supplied\nline - a poverty line, assumed same for all obs (so income is assumed to be already equivalised)\nfoster_greer_thorndyke_alphas - coefficients for FGT poverty measures; note that FGT(0)  corresponds to headcount and FGT(1) to gap; count and gap are computed directly anyway  but it's worth checking one against the other.\ngrowth is (e.g.) 0.01 for 1% per period, and is used for 'time to exit' measure.\n\nOutput is  dictionary with an entry for each measure.\n\nThe measures are:\n\nheadcount;\ngap;\nFoster Greer Thorndyke, for each of the values in foster_greer_thorndyke_alphas;\nWatts;\ntime to exit, for the supplied growth rate;\nShorrocks;\nSen.\n\nSee World Bank, ch. 4.\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_poverty-2","page":"Home","title":"PovertyAndInequalityMeasures.make_poverty","text":"As above, but using the QueryVerse IterableTables interface rawdata - basically anything resembling a dataframe; see: [https://github.com/queryverse/IterableTables.jl] throws an exception if rawdata doesn't support iterabletable interface\n\n\n\n\n\n","category":"function"},{"location":"#PovertyAndInequalityMeasures.make_povertyinternal-Tuple{}","page":"Home","title":"PovertyAndInequalityMeasures.make_povertyinternal","text":"Internal version, once we have our datatset\n\n\n\n\n\n","category":"method"},{"location":"#TODO","page":"Home","title":"TODO","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"better decomposable indices;\nhaving separate dataframe/array versions seems complicated.","category":"page"},{"location":"#Bibliography","page":"Home","title":"Bibliography","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Cobham Alex, and Sumner Andy. “Is Inequality All about the Tails?: The Palma Measure of Income Inequality.” Significance 11, no. 1 (February 19, 2014): 10–13. https://doi.org/10.1111/j.1740-9713.2014.00718.x.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Haughton, Jonathan, and Shahidur R. Khandker. ‘Handbook on Poverty and Inequality’. The World Bank, 27 March 2009. http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Preston, Ian. ‘Inequality and Income Gaps’. IFS Working Paper. Institute for Fiscal Studies, 5 December 2006. https://econpapers.repec.org/paper/ifsifsewp/06_2f25.htm.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Reed, Howard, and Graham Stark. ‘Tackling Child Poverty Delivery Plan - Forecasting Child Poverty in Scotland’. Scottish Government, 9 March 2018. http://www.gov.scot/Publications/2018/03/2911/0``.","category":"page"}]
}
