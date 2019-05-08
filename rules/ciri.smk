rule bwa:
  input:
    fwd = "samples/raw/{sample}_R1.fq",
    rev = "samples/raw/{sample}_R2.fq"
  output: "samples/ciri/{sample}.sam"
  run:
    bwa="/home/exacloud/lustre1/CEDAR/tools/bwa"
    genome= config["genome"]

    shell ("""
      {bwa}  mem -T 12 {genome} {input.fwd} {input.rev} > {output}
        """)

rule ciri:
  input:"samples/ciri/{sample}.sam"
  output:"results/ciri_out/{sample}_ciriout.txt"
  run:
    genome= config["genome"]

    shell( """
      perl /home/exacloud/lustre1/CEDAR/tools/CIRI2.pl -T 12 -I {input} -O {output} -F {genome} -A /home/exacloud/lustre1/CEDAR/josiah/circ_RNA/gencode.v27.annotation.gtf
    """)

rule ciri_junction_counts:
  input:
    expand("results/ciri_out/{sample}_ciriout.txt",sample=SAMPLES)
  output:
    "results/tables/{project_id}_ciri_junctioncounts.txt".format(project_id=project_id),
    "results/tables/{project_id}_ciri_frequency.txt".format(project_id=project_id)
  script:
    "../scripts/ciri_junction_counts.R"
