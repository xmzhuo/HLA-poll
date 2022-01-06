process INDEX {
    tag "# ${outputDir} swiss army knife (sak) nf without docker"
    cpus "$cpu"
    memory "$mem"
    time "$timeout"
    stageInMode 'copy' 
    echo true
    
    publishDir "$outputDir", mode: 'copy' 
   

    input:
    path bam
    
    path script
    val advarg
    
    val cpu
    val mem
    val timeout
    val outputDir
     
    output:
    path "*.bam", emit: bam
    path "*.bai", emit: bai
    path "*.log", emit: log
    
    shell:   
    """
    echo "input files check: !{bam}"
    echo "upstream files check: "
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
sample=\$(echo !{bam} | sed 's/.bam/.hla.bam/')
 cp !{bam} \${sample}
 /samtools/bin/samtools index \${sample} 2>&1 | tee -a sak-nf_\$(date +%Y%m%d_%H%M%S).log 
outfileval="*.bam *.bai "
logname=\$(ls *.log | grep sak-nf)
 echo "# md5sum #" >> \${logname}
md5sum \${outfileval} >> \${logname}
 logmd5=\$(md5sum \${logname} | sed "s/ /_/g")
 mv \${logname} \${logmd5}
    
    #rm advarg_temp.sh
    """
}
