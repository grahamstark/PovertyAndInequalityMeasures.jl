```@meta
CurrentModule = PovertyAndInequalityMeasures
```

# PovertyAndInequalityMeasures


This generates various measures poverty and inequality from a sample dataset.

The measures are mostly taken from chs. 4-6 of the World Banks' [Handbook on Poverty and Inequality](biblio.md).

See the [test case for worked examples](https://github.com/grahamstark/PovertyAndInequalityMeasures.jl/tree/master/test)

There's also a small `binify` routine which chops a dataset up
into chunks of cumulative income and population suitable for drawing [Lorenz Curves](https://en.wikipedia.org/wiki/Lorenz_curve).

## Index

```@index
```

```@autodocs
Modules = [PovertyAndInequalityMeasures]
[:constant, :type, :function]
```

## TODO

* better decomposable indices;
* having separate dataframe/array versions seems complicated.

## Bibliography

Cobham Alex, and Sumner Andy. “Is Inequality All about the Tails?: The Palma Measure of Income Inequality.” Significance 11, no. 1 (February 19, 2014): 10–13. [https://doi.org/10.1111/j.1740-9713.2014.00718.x](https://doi.org/10.1111/j.1740-9713.2014.00718.x).

Haughton, Jonathan, and Shahidur R. Khandker. ‘Handbook on Poverty and Inequality’. The World Bank, 27 March 2009. [http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality](http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality).

Preston, Ian. ‘Inequality and Income Gaps’. IFS Working Paper. Institute for Fiscal Studies, 5 December 2006. [https://econpapers.repec.org/paper/ifsifsewp/06_2f25.htm](https://econpapers.repec.org/paper/ifsifsewp/06_2f25.htm).

Reed, Howard, and Graham Stark. ‘Tackling Child Poverty Delivery Plan - Forecasting Child Poverty in Scotland’. Scottish Government, 9 March 2018. [http://www.gov.scot/Publications/2018/03/2911/0](http://www.gov.scot/Publications/2018/03/2911/0)``.
