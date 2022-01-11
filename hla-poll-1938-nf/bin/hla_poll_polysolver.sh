
sample=$1
sample=${sample%.bam}

/home/polysolver/scripts/shell_call_hla_type $sample.bam Unknown 1 hg38 STDFQ 0 $sample
        
cp $sample/winners.hla.txt $sample.polysolver.result

cat $sample.polysolver.result | sed 's/[a-z]*_[a-z]_//g' | sed 's/_/:/g' | awk '{print $1"*"$2"\n"$1"*"$3}' > $sample.polysolver.f.result