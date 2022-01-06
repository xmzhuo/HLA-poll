process POLYSOLVER {
    tag "# ${outputDir} swiss army knife (sak) nf without docker"
    cpus "$cpu"
    memory "$mem"
    time "$timeout"
    stageInMode 'copy' 
    echo true
    
    publishDir "$outputDir", mode: 'copy' 
   

    input:
    path bam
path bai
    
    path script
    val advarg
    
    val cpu
    val mem
    val timeout
    val outputDir
     
    output:
    path "*.f.result", emit: result
    path "*.log", emit: log
    
    shell:   
    """
    echo "input files check: !{bam}, !{bai}"
    echo "upstream files check: "
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
bash /home/polysolver/scripts/shell_call_hla_type /home/docker/\$sample.bam Unknown 1 hg38 STDFQ 0 /home/docker/HLA/polysolver/\$sample 2>&1 | tee -a sak-nf_\$(date +%Y%m%d_%H%M%S).log 
outfileval="*.f.result "
logname=\$(ls *.log | grep sak-nf)
 echo "# md5sum #" >> \${logname}
md5sum \${outfileval} >> \${logname}
 logmd5=\$(md5sum \${logname} | sed "s/ /_/g")
 mv \${logname} \${logmd5}
    
    #rm advarg_temp.sh
    """
}
