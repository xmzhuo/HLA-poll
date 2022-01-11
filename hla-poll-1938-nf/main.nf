#! /usr/bin/env nextflow
/*
 * SAK for Swiss Army Knife
 * created by Xinming Zhuo <xmzhuo@gmail.com> 
 * 
 */ 


nextflow.enable.dsl=2


def helpMessage() {
    log.info"""
    ================================================================
    saks-nf
    ================================================================
    DESCRIPTION
    SAKs for Swiss Army Knifes, a versatile nextflow to run many things 
    Usage:
    nextflow run xmzhuo/saks-nf

    Options for each process:
        --input             Input files  
        --script            optional: run your own script in nextflow, as long as your environment support the language of choice
        --dockerimg         optional: provide a docker image to work with
        --argument          cmdline argument
        --outputDir         Output directory ['results']
        --sakcpu            request cpu for task ['2']
        --sakmemory         reeuest memory for task ['4.GB']
        --saktime           time out policy ['1.hour']

    Profiles:
        standard            local execution
        slurm               SLURM execution with singularity on HPC
        azure               Azure (under development)
        aws                 AWS (under development)

    Author:
    Xinming Zhuo (xmzhuo@gmail.com)
    """.stripIndent()
}


params.help = false

if (params.help) {
    helpMessage()
    exit 0
}


/*
 * Defines some parameters in order to specify input and advance argument by using the command line options
 */

// compose params

params.hla_name = "hla"
params.hla_description = "multiple hla caller"
params.hla_script = "/path/to/alignAndExtract_hs1938.sh"
params.hla_dockerimg = "xmzhuo/hla:0.0.9"
params.hla_argument = "bash hla_poll_v1.8.3.sub.sh !{bam} \$(pwd) !{mem}"
params.hla_outputDir = "./results/hla-poll"
params.hla_sakcpu = "4"
params.hla_sakmem = "16.GB"
params.hla_saktime = "2.hour"
params.hla_input_bam = "/path/to/*.bam"
params.polysolver_name = "polysolver"
params.polysolver_description = "polysolver call hla"
params.polysolver_script = ""
params.polysolver_dockerimg = "xmzhuo/polysolver:v4m2"
params.polysolver_argument = "bash hla_poll_polysolver.sh !{hla_bam}"
params.polysolver_outputDir = "./results/hla-poll"
params.polysolver_sakcpu = "4"
params.polysolver_sakmem = "8.GB"
params.polysolver_saktime = "2.hour"
params.polysolver_input_file = ""
params.poll_name = "poll"
params.poll_description = "hla-poll calling"
params.poll_script = ""
params.poll_dockerimg = ""
params.poll_argument = "bash hla_poll_summary_v1.sh 4"
params.poll_outputDir = "./results/hla-poll"
params.poll_sakcpu = "2"
params.poll_sakmem = "2.GB"
params.poll_saktime = "1.hour"
params.poll_input_file = ""
params.defdir = "$baseDir"
//
/*params.input = "$baseDir/data/input_sanitychk"
*params.input = "$baseDir/data/upstream_sanitychk"
*params.script = "$baseDir/bin/script_sanitychk"
*params.dockerimg = ""
*params.argument = ""
*params.outputDir = 'results'
*params.sakcpu = "2"
*params.sakmem = "4.GB"
*params.saktime = "1.hour"
*
*input_dir = file(params.input).parent
*/

log.info """\
         Swiss Army Knifes Battery  P I P E L I N E    
         ===log.info==========================

{
  'name': 'hla',
  'description': 'multiple hla caller',
  'input': {
    'bam': '/path/to/*.bam'
  },
  'output': {
    'result': '*.f.result',
    'bam': '*_hla.bam',
    'log': '*.log'
  },
  'upstream': [
    ''
  ],
  'script': '/path/to/alignAndExtract_hs1938.sh',
  'dockerimg': 'xmzhuo/hla:0.0.9',
  'argument': 'bash hla_poll_v1.8.3.sub.sh !{bam} \$(pwd) !{mem}',
  'outputDir': './results/hla-poll',
  'sakcpu': '4',
  'sakmem': '8.GB',
  'saktime': '2.hour'
}
{
  'name': 'polysolver',
  'description': 'polysolver call hla',
  'input': {
    'file': ''
  },
  'output': {
    'result': '*.f.result',
    'log': '*.log'
  },
  'upstream': [
    'hla.bam'
  ],
  'script': '',
  'dockerimg': 'xmzhuo/polysolver:v4m2',
  'argument': 'bash hla_poll_polysolver.sh !{hla_bam}',
  'outputDir': './results/hla-poll',
  'sakcpu': '4',
  'sakmem': '8.GB',
  'saktime': '2.hour'
}
{
  'name': 'poll',
  'description': 'hla-poll calling',
  'input': {
    'file': ''
  },
  'output': {
    'csv': '*.csv',
    'log': '*.log'
  },
  'upstream': [
    'hla.result',
    'polysolver.result'
  ],
  'script': '',
  'dockerimg': '',
  'argument': 'bash hla_poll_summary_v1.sh 4',
  'outputDir': './results/hla-poll',
  'sakcpu': '2',
  'sakmem': '2.GB',
  'saktime': '1.hour'
}
         
         """
         .stripIndent()


// import modules

include { HLA } from './modules/hla'
include { HLADOC } from './modules/hla_docker'
include { POLYSOLVER } from './modules/polysolver'
include { POLYSOLVERDOC } from './modules/polysolver_docker'
include { POLL } from './modules/poll'
include { POLLDOC } from './modules/poll_docker'

//
/*include { SAK } from './modules/sak'
*include { SAKDOC } from './modules/sak_docker'
*/


workflow {
    /*
    *
    */
    
    // compose workflow

    //* ## step cmd example SAK
    if(params.hla_input_bam) {HLA_bam = Channel.fromPath(params.hla_input_bam).toSortedList()} else {HLA_bam = Channel.fromPath("$baseDir" + "/data/input_sanitychk")}
    if(params.hla_script) {HLA_ScriptFiles = Channel.fromPath(params.hla_script).toSortedList()} else {HLA_ScriptFiles = Channel.fromPath("$baseDir" + "/bin/script_sanitychk")}
    
    if (params.hla_dockerimg) {
        HLADOC(HLA_bam,  HLA_ScriptFiles, params.hla_argument, params.hla_dockerimg, params.hla_sakcpu, params.hla_sakmem, params.hla_saktime, params.hla_outputDir)
    } else {
        HLA(HLA_bam,  HLA_ScriptFiles, params.hla_argument, params.hla_sakcpu, params.hla_sakmem, params.hla_saktime, params.hla_outputDir)   
    }
    //* ## step cmd example SAK
    if(params.polysolver_input_file) {POLYSOLVER_file = Channel.fromPath(params.polysolver_input_file).toSortedList()} else {POLYSOLVER_file = Channel.fromPath("$baseDir" + "/data/input_sanitychk")}
    if(params.polysolver_script) {POLYSOLVER_ScriptFiles = Channel.fromPath(params.polysolver_script).toSortedList()} else {POLYSOLVER_ScriptFiles = Channel.fromPath("$baseDir" + "/bin/script_sanitychk")}
    
    if (params.polysolver_dockerimg) {
        POLYSOLVERDOC(POLYSOLVER_file, HLADOC.out.bam.collect(), POLYSOLVER_ScriptFiles, params.polysolver_argument, params.polysolver_dockerimg, params.polysolver_sakcpu, params.polysolver_sakmem, params.polysolver_saktime, params.polysolver_outputDir)
    } else {
        POLYSOLVER(POLYSOLVER_file, HLADOC.out.bam.collect(), POLYSOLVER_ScriptFiles, params.polysolver_argument, params.polysolver_sakcpu, params.polysolver_sakmem, params.polysolver_saktime, params.polysolver_outputDir)   
    }
    //* ## step cmd example SAK
    if(params.poll_input_file) {POLL_file = Channel.fromPath(params.poll_input_file).toSortedList()} else {POLL_file = Channel.fromPath("$baseDir" + "/data/input_sanitychk")}
    if(params.poll_script) {POLL_ScriptFiles = Channel.fromPath(params.poll_script).toSortedList()} else {POLL_ScriptFiles = Channel.fromPath("$baseDir" + "/bin/script_sanitychk")}
    
    if (params.poll_dockerimg) {
        POLLDOC(POLL_file, HLADOC.out.result.collect(), POLYSOLVERDOC.out.result.collect(), POLL_ScriptFiles, params.poll_argument, params.poll_dockerimg, params.poll_sakcpu, params.poll_sakmem, params.poll_saktime, params.poll_outputDir)
    } else {
        POLL(POLL_file, HLADOC.out.result.collect(), POLYSOLVERDOC.out.result.collect(), POLL_ScriptFiles, params.poll_argument, params.poll_sakcpu, params.poll_sakmem, params.poll_saktime, params.poll_outputDir)   
    }
    
    /*
    *//* ## step cmd example SAK
    *if(params.input) {Var_InFiles = Channel.fromPath(params.input).toSortedList()} else {Var_InFiles = Channel.fromPath("$baseDir" + "/data/input_sanitychk")}
    *Var_UpStream = Channel.fromPath("$baseDir" + "/data/upstream_sanitychk").concat_upstream
    *Var_UpStream.view()
    *if(params.script) {Var_ScriptFiles = Channel.fromPath(params.script).toSortedList()} else {Var_ScriptFiles = Channel.fromPath("$baseDir" + "/bin/script_sanitychk")}
    *
    *if (params.dockerimg) {
    *    SAKDOC(Var_InFiles, Var_UpStream, Var_ScriptFiles, params.argument, params.dockerimg, params.sakcpu, params.sakmem, params.saktime, params.outputDir)
    *} else {
    *    SAK(Var_InFiles, Var_UpStream, Var_ScriptFiles, params.argument, params.sakcpu, params.sakmem, params.saktime, params.outputDir)   
    *}
    */
}


workflow.onComplete { 
    log.info """\
        sak-nf has finished.
        Status:   ${workflow.success ?  "Done!" : "Oops .. something went wrong"}
        Time:     ${workflow.complete}
        Duration: ${workflow.duration}\n
        """
        .stripIndent()
}
