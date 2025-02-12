import numpy as np
import pandas as pd

"""

This package allows you to generate various standard measures of poverty and inequality from a sample dataset.

The measures are mostly taken from chs. 4-6 of the World Banks' [Handbook on Poverty and Inequality](http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality). 

"""

class PovertyMeasures:
    """
    Container for Poverty Measures
    """
    def __init__(self):
        self.headcount = 0.0
        self.gap = 0.0
        self.watts = 0.0
        self.sen = 0.0
        self.shorrocks = []
        self.fgt_alphas = []
        self.foster_greer_thorndyke = 0.0
        self.time_to_exit = 0.0
        self.gini_amongst_poor = 0.0
        self.poverty_gap_gini = 0.0

class InequalityMeasures:
    """
    Container for Inequality Measures
    """
    def __init__(self):
        self.atkinson_es = []
        self.atkinson = [] 
        self.generalised_entropy_alphas = []
        self.generalised_entropy = []
        self.hoover = 0.0
        self.theil_l = 0.0
        self.theil_t = 0.0
        self.gini = 0.0
        self.palma = 0.0
        self.median = 0.0
        self.total_income = 0.0
        self.average_income = 0.0
        self.total_population = 0.0
        self.deciles = 0.0
        self.negative_or_zero_income_count = 0

def make_augmented(  data, weightcol, incomecol, sort_data = True, delete_negatives=False ):
    """
    Internal function that makes a sorted array
    with cumulative income and population added
    """
    pass


        