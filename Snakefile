SUBSETS = [100000, 500000, 1000000]  # 2x, 10x, and 20x coverage

rule all:
    input:
        expand("SRR2584857_quast.{subset}", subset=SUBSETS),
        expand("SRR2584857_annot.{subset}", subset=SUBSETS),

rule subset_reads:
    input:
        "{sample}.fastq.gz",
    output:
        "{sample}.{subset}.fastq.gz"
    shell: """
        gunzip -c {input} | head -{wildcards.subset} | gzip -9c > {output} || true
    """

rule annotate:
    input:
        "SRR2584857-assembly.{subset}.fa"
    output:
        directory("SRR2584857_annot.{subset}")
    shell: """
        mkdir -p {output}  # Create the output directory explicitly
        prokka --outdir {output} --prefix SRR2584857 {input} --cpus 4 --force 2> {output}.log || echo "Prokka failed for {input}" > {output}.error
    """

rule assemble:
    input:
        r1 = "SRR2584857_1.{subset}.fastq.gz",
        r2 = "SRR2584857_2.{subset}.fastq.gz"
    output:
        dir = directory("SRR2584857_assembly.{subset}"),
        assembly = "SRR2584857-assembly.{subset}.fa"
    shell: """
       megahit -1 {input.r1} -2 {input.r2} -f -m 5e9 -t 4 -o {output.dir}     
       cp {output.dir}/final.contigs.fa {output.assembly}                     
    """

rule quast:
    input:
        "SRR2584857-assembly.{subset}.fa"
    output:
        directory("SRR2584857_quast.{subset}")
    shell: """                                                                
       quast {input} -o {output}                                              
    """
