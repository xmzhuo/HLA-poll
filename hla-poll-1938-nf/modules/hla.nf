process HLA {
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
    path "*.f.result", emit: result
    path "*_hla.bam", emit: bam
    path "*_hla.*bai", emit: bai
    path "*.log", emit: log
    
    shell:   
    """
    echo "input files check: !{bam}"
    echo "upstream files check: "
    echo "script check: !{script}"
    #echo "cmd:!{advarg}"
    #echo "!{advarg}" > advarg_temp.sh
    #bash advarg_temp.sh 2>&1 | tee -a sak-nf_\$(date '+%Y%m%d_%H%M').log
bash hla_poll_v1.8.3.sub.sh !{bam} \$(pwd) !{mem} 2>&1 | tee -a sak-nf_\$(date +%Y%m%d_%H%M%S).log 
outfileval="*.f.result *_hla.bam *_hla.*bai "
logname=\$(ls *.log | grep sak-nf)
 echo "# md5sum #" >> \${logname}
md5sum \${outfileval} >> \${logname}
 logmd5=\$(md5sum \${logname} | sed "s/ /_/g")
 mv \${logname} \${logmd5}
    
    #rm advarg_temp.sh
    """
}
