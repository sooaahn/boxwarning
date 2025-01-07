#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Dec 29 22:05:06 2024

@author: sooa
"""
# conda install conda-forge::fuzzywuzzy

import csv
import pandas as pd
import os
from fuzzywuzzy import fuzz
from thefuzz import process

# Set the directory containing the CSV files
directory = "/Users/sooa/Documents/boxwarning/drug_names"
os.chdir(directory)

df = pd.read_csv("/Users/sooa/Downloads/drug_provider_drugs.csv", low_memory=False) # All Part D Drugs
df_1 = pd.DataFrame(df)
print(df_1)

#df = pd.read_csv("drug_names_241229.csv", low_memory=False) # Drugs with warning
df = pd.read_csv("uspcat.csv", low_memory=False)
df_2 = pd.DataFrame(df)
print(df_2)

# Function to perform fuzzy matching and return matched name and score
def token_match(name, choices):
    match = process.extractOne(name, choices, scorer=fuzz.token_sort_ratio)
    return pd.Series([match[0], match[1]]) if match else pd.Series([None, None])

# Apply token-based fuzzy matching to warning list
# df_2[["matched_name", "match_score"]] = df_2["gnrc_name"].apply(token_match, choices=df_1["gnrc_name"])

# Apply matching to drug_provider list
df_1[["matched_name", "match_score"]] = df_1["gnrc_name"].apply(token_match, choices=df_2["gnrc_name2"])

#df_2.to_csv('drug_match.csv', index=False) # Drugs with warning
df_1.to_csv('drug_uspcat.csv', index=False) # All drugs from drug_provider list
    