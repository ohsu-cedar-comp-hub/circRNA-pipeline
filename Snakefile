import datetime
import sys
import os
import pandas as pd
import json

timestamp = ('{:%Y-%m-%d_%H:%M:%S}'.format(datetime.datetime.now()))

configfile:"omic_config.yaml"
project_id = config["project_id"]

SAMPLES, = glob_wildcards("samples/raw/{sample}_R1.fq")

with open('cluster.json') as json_file:
    json_dict = json.load(json_file)

rule_dirs = list(json_dict.keys())

for rule in rule_dirs:
    if not os.path.exists(os.path.join(os.getcwd(),'logs',rule)):
        log_out = os.path.join(os.getcwd(), 'logs', rule)
        os.makedirs(log_out)
        print(log_out)

result_dirs = ['diffexp','tables']
for rule in result_dirs:
    if not os.path.exists(os.path.join(os.getcwd(),'results',rule)):
        log_out = os.path.join(os.getcwd(), 'results', rule)
        os.makedirs(log_out)
        print(log_out)

def message(mes):
    sys.stderr.write("|--- " + mes + "\n")

def get_deseq2_threads(wildcards=None):
    few_coeffs = False if wildcards is None else len(get_contrast(wildcards)) < 10
    return 1 if len(config["omic_meta_data"]) < 100 or few_coeffs else 6

def get_contrast(wildcards):
    """Return each contrast provided in the configuration file"""
    return config["diffexp"]["contrasts"][wildcards.contrast]

for sample in SAMPLES:
    message("Sample " + sample + " will be processed")

rule all:
    input:
        "results/tables/{project_id}_ciri_junctioncounts.txt".format(project_id=project_id),
        "results/tables/{project_id}_ciri_frequency.txt".format(project_id=project_id),
        expand("results/diffexp/pairwise/{contrast}.diffexp.{adjp}.VolcanoPlot.pdf", contrast = config["diffexp"]["contrasts"], adjp = config['adjp']),
        expand("results/diffexp/pairwise/permutationTest/Histogram.{contrast}.Permutation.Test.pdf", contrast = config["diffexp"]["contrasts"]),
        "results/diffexp/group/MDS_table.txt",
        expand(["results/diffexp/glimma-plots/{contrast}.ma_plot.html", "results/diffexp/glimma-plots/{contrast}.volcano_plot.html"],contrast = config["diffexp"]["contrasts"]),
        "results/diffexp/glimma-plots/{project_id}.mds_plot.html".format(project_id=project_id)

include: "rules/ciri.smk"
include: "rules/deseq.smk"
