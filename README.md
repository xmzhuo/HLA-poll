# HLA-poll
Xinming Zhuo, PhD. zhuox@upmc.edu; xmzhuo@gmail.com
script and supplement data for HLA-poll

support the manuscript:
HLA-poll: an ensemble suite of human leukocyte antigen-prediction tools for whole-exome and whole-genome sequencing data 

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


