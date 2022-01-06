# HLA-poll
Xinming Zhuo, PhD. zhuox@upmc.edu; xmzhuo@gmail.com
script and supplement data for HLA-poll

support the manuscript:
HLA-poll: an ensemble suite of human leukocyte antigen-prediction tools for whole-exome and whole-genome sequencing data 


# A nextflow solution is provided in hla-poll-nf
Dependency: nextflow version >21.04; Docker (local); SIngularity (HPC)

User can simply run <br: />
for local:
nextflow run hla-poll-nf -profile standard --index_input_bam "/path/to/*.bam" <br: />

for HPC:
nextflow run hla-poll-nf -profile slurm --index_input_bam "path/to/*.bam"



### MISC:
hla_poll_v1.8.main.run.sh
hla_poll_v1.8.sub.sh
hla_poll_call_v1.sh

docker images:
xmzhuo/hla:0.0.9
xmzhuo/polysolver:v4m2

requirement: linux OS (MacOS may need a few modification), docker
file: bam (mapped with hg38)

How to run:
bash hla_poll_v1.8.main.run.sh /data/in/ /data/out/ hla_poll_v1.8.sub.sh target.bam


For using each indevidual caller, please refer to each caller's licenscing policy.


