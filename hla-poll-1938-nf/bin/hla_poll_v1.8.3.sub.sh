#!usr/bin/env bash

##hla_poll_v1.8.cloud_sub.sh
#1.8.2 adapted for nextflow and allow hg19
# Xinming Zhuo PhD; xmzhuo@gmail.com
#this the sub script used by the master script in a docker
#background running HLA-scan, hlavbseq, hlaminer and HLA-HD to save computation time
################ body of code ###############
### Kourami, HLD-scan, HLA-VBSeq, HLA-HD, HLAminer ####
    export PATH=$PATH:/bin:/bwa.kit:/tools/:/samtools/bin:/samtools/bin:/tools/hlahd.1.2.0.1/bin
    #echo "export PATH=$PATH:/bin:/bwa.kit:/tools:/samtools/bin:/samtools/bin:/tools/hlahd.1.2.0.1/bin" >> ~/.bashrc
    #source ~/.bashrc
    #avoid smatools point to alternative location
     mv /usr/bin/samtools /usr/bin/samtools1
     cp alignAndExtract_hs1938.sh /kourami/scripts/
    #folder="/mydata"
    folder=$2
    cd $folder 
    #sample=$(ls *.bam)

    #for sample in $(ls *.bam); do
    
    sample=$1
    sample=$(echo $sample | sed 's/\.bam//')
    echo $sample
    
    mem=$(echo $3 | sed 's/\.//' | sed 's/[Bb]//')

    # check if bam file is hg19
    hg19_chk=$(samtools view -H $sample.bam | grep ^@SQ | grep -E "hs37|hg19" | wc -l)
    if [ $hg19_chk -gt 0 ]; then echo "$sample is mapped to hg19"; else echo "$sample is mapped to hg38"; fi 

    #sample_name=$(echo $sample | sed "s/\..*$//")
    if [ ! -f $sample.bam.bai ] && [ ! -f $sample.bai ]; then
        echo "indexing $sample.bam"
        samtools index $folder/$sample.bam
    fi
    
    mkdir $folder/HLA
    
    
    #######################
    # HLA-scan 2.1.4
        echo "HLA-scan"
        mkdir $folder/HLA/hla_scan/
        cd $folder/HLA/hla_scan/
        hla_list="HLA-A HLA-B HLA-C HLA-E HLA-F HLA-G MICA MICB HLA-DMA HLA-DMB HLA-DOA HLA-DOB HLA-DPA1 HLA-DPB1 HLA-DQA1 HLA-DQB1 HLA-DRA HLA-DRB1 HLA-DRB5 TAP1 TAP2"
        #run hlascan in background
        if [ 1 -gt 0 ]; then
            #hla_list=$(cat /downloads/hla_list.txt)
            #hlascan="/mydata/hla_scan_r_v2.1.4"
            hlascan="/hla_scan"
            chmod +x $hlascan
            echo "" > $folder/HLA/hla_scan/$sample.result
            echo "" > $folder/HLA/hla_scan/$sample.summary
            for hla_gene in $hla_list
                do
                echo $hla_gene
                if [ $hg19_chk -gt 0 ]; then 
                    #$hlascan -b $folder/$sample.bam -d /downloads/db/HLA-ALL.IMGT -g $hla_gene -t 24 -v 38 >> $folder/HLA/hla_scan/$sample.result
                    $hlascan -b $folder/$sample.bam -d /downloads/db/HLA-ALL.IMGT -g $hla_gene -t 24 -v 19 > temp
                else
                    #$hlascan -b $folder/$sample.bam -d /downloads/db/HLA-ALL.IMGT -g $hla_gene -t 24 -v 38 >> $folder/HLA/hla_scan/$sample.result
                    $hlascan -b $folder/$sample.bam -d /downloads/db/HLA-ALL.IMGT -g $hla_gene -t 24 -v 38 > temp
                fi

                
                count=$(cat temp | grep "$hla_gene" -A6 | grep "# of considered types" | sed 's/^#.*: //')
                echo $count
                cat temp | grep "$hla_gene" -A6 | grep '\[Type ' | awk -v FS=" " -v var1="$hla_gene" var2="$count"'{print var1","$3","var2}' >> $folder/HLA/hla_scan/$sample.summary
                
                cp $folder/HLA/hla_scan/$sample.result temp1 
                cat temp1 temp > $folder/HLA/hla_scan/$sample.result
                rm temp1
            done
            rm temp temp1

            cp $folder/HLA/hla_scan/$sample.summary $folder/HLA/${sample}.hlascan.result
            #format result
            cat $folder/HLA/${sample}.hlascan.result | awk -v FS="," '{print $1"*"$2}' > $folder/HLA/${sample}.hlascan.f.result
        fi &
    #########################
    ####  Kourami #######
        echo "Kourami"
        thread_n=$(grep -c ^processor /proc/cpuinfo | awk '{print $0/2}')
        sed -i "s/num_processors=[0-9]*$/num_processors=$thread_n/" /kourami/scripts/alignAndExtract_hs38DH.sh

        mkdir $folder/HLA/kourami
        cd $folder/HLA/kourami
    
        #/kourami/scripts/alignAndExtract_hs38DH.sh $sample $folder/$sample.bam
        /kourami/scripts/alignAndExtract_hs1938.sh $sample $folder/$sample.bam

        java -jar /kourami/target/Kourami.jar -Xmx${mem} -d /kourami/db -o $sample ${sample}_on_KouramiPanel.bam

        cp $sample.result $folder/HLA/$sample.kourami.result
        #format
        cat $folder/HLA/$sample.kourami.result | awk '{print "HLA-"$1}' | sed 's/[A-Z]$//' > $folder/HLA/$sample.kourami.f.result

    ######################
    ### HLA-VBSeq ####
        #originallly take hg19, modify it to hg38, but some problem persist when map back to the reference, use kourami fq instead
        #dx download file-FXpKVP000FbKzXqxBBF8kk4P
        #mkdir /tools/hla-vbseq/
        #tar -C /mydata/hla-vbseq/ -xzvf HLA-VBSeq.tar.gz

        HLAVBSEQ="/tools/hla-vbseq"
        #mkdir -p $HLAVBSEQ
        #tar -C $HLAVBSEQ -xzvf HLA-VBSeq.tar.gz
        mkdir -p $folder/HLA/hlavbseq
        cd $folder/HLA/hlavbseq
        bwa index $HLAVBSEQ/hla_all_v2.fasta
        cp $folder/HLA/kourami/${sample}_extract*.fq.gz .
        gunzip ${sample}_extract*.fq.gz
        bwa mem -t 8 -P -L 10000 -a $HLAVBSEQ/hla_all_v2.fasta ${sample}_extract_1.fq ${sample}_extract_2.fq > $folder/HLA/hlavbseq/$sample.hla.sam
        #For paired-end read data:
        java -jar $HLAVBSEQ/HLAVBSeq.jar $HLAVBSEQ/hla_all_v2.fasta $folder/HLA/hlavbseq/$sample.hla.sam $folder/HLA/hlavbseq/$sample.result.txt --alpha_zero 0.01 --is_paired
        $HLAVBSEQ/parse_result.pl $HLAVBSEQ/Allelelist_v2.txt $folder/HLA/hlavbseq/$sample.result.txt | sort -k2 -n -r > $sample.HLA.txt
        $HLAVBSEQ/call_hla_digits.py -v $folder/HLA/hlavbseq/$sample.result.txt -a $HLAVBSEQ/Allelelist_v2.txt -r 300 -d 8 --ispaired > $folder/HLA/hlavbseq/$sample.report.d8.txt
        #    -v xxxxx_result.txt : Need to set the output file from the HLA-VBSeq
        #    -a Allelelist.txt : IMGT HLA Allelelist
        #    -r 90 : mean single read length (mean_rlen)
        #    -d 4 : HLA call resolution�i4 or 6 or 8�j
        #    --ispaired : if set, twice the mean rlen for depth calculation (need to specify when the sequenced data is paired-end protocol)

        cp $folder/HLA/hlavbseq/$sample.report.d8.txt $folder/HLA/$sample.hlavbseq.result
        cat $folder/HLA/$sample.hlavbseq.result| sed 1d |awk -v FS='\t' '{ if ($1 ~ "MIC" || $1 ~ "TAP") print $2"\n"$3; else print "HLA-"$2"\nHLA-"$3 }' > $folder/HLA/$sample.hlavbseq.f.result

        #For single-end read data:
        #java -jar HLAVBSeq.jar hla_all_v2.fasta NA12878_part.sam NA12878_result.txt --alpha_zero 0.01
    
    #############
    ##########################
    ### HLA-HD 1.2.0.1
        echo "HLA-HD"
        mkdir $folder/HLA/hla_hd
        mkdir -p $folder/HLA/hla_hd/estimation
        #    #Extract MHC region
        #    #:for GRCh38.p12
        #    samtools view -h -b $folder/$sample.bam chr6:28,510,120-33,480,577 > $folder/HLA/hla_hd/$sample.mhc.bam
        #    #:for GRCh37
        #    #samtools view -h -b sample.hgmap.sorted.bam chr6:28,477,797-33,448,354 > sample.mhc.bam
        #    #Extract unmap reads
        #    samtools view -b -f 4 $folder/$sample.bam > $folder/HLA/hla_hd/$sample.unmap.bam
        #    #Merge bam files
        #    samtools merge -f $folder/HLA/hla_hd/$sample.merge.bam $folder/HLA/hla_hd/$sample.unmap.bam $folder/HLA/hla_hd/$sample.mhc.bam
        #    #rm $folder/HLA/hla_hd/$sample.unmap.bam $folder/HLA/hla_hd/$sample.mhc.bam
        ##    #Create fastq
        #    samtools bam2fq $folder/HLA/hla_hd/$sample.merge.bam > $folder/HLA/hla_hd/$sample.hlatmp.fastq 
        #    cat $folder/HLA/hla_hd/$sample.hlatmp.fastq | grep '^@.*/1$' -A 3 --no-group-separator > $folder/HLA/hla_hd/$sample.hlatmp.1.fastq 
        #    cat $folder/HLA/hla_hd/$sample.hlatmp.fastq | grep '^@.*/2$' -A 3 --no-group-separator > $folder/HLA/hla_hd/$sample.hlatmp.2.fastq
        #    ##Change fastq ID
        #    cat $folder/HLA/hla_hd/$sample.hlatmp.1.fastq |awk '{if(NR%4 == 1){O=$0;gsub("/1"," 1",O);print O}else{print $0}}' > $folder/HLA/hla_hd/$sample.hla.1.fastq
        #    cat $folder/HLA/hla_hd/$sample.hlatmp.2.fastq |awk '{if(NR%4 == 1){O=$0;gsub("/2"," 2",O);print O}else{print $0}}' > $folder/HLA/hla_hd/$sample.hla.2.fastq
        #    #HLA-HD can not adopt to multiple fastq, so merge them in advance.
        #    #cat sample.1_1.fastq sample.1_2.fastq > sample_1.fastq
        #    #cat sample.1_2.fastq sample.2_2.fastq > sample_2.fastq
        #    #rm $folder/HLA/hla_hd/*.hlatmp.*.fastq
        #    # hlahd.sh -t [thread_num] -m [minimum length of reads] -c [trimming rate] -f [path_to freq_data directory] fastq_1 fastq_2 gene_split_filt path_to_dictionary_directory IDNAME[any name] output_directory
            
        #    #export PATH=$PATH:/tools/hlahd.1.2.0.1/bin
        #    hlahd.sh -t 8 -m 100 -c 0.95 -f /tools/hlahd.1.2.0.1/freq_data/ $folder/HLA/hla_hd/$sample.hla.1.fastq $folder/HLA/hla_hd/$sample.hla.2.fastq /tools/hlahd.1.2.0.1/HLA_gene.split.txt /tools/hlahd.1.2.0.1/dictionary/ $sample $folder/HLA/hla_hd/estimation
        #use kourami fq instead (store in hlabvseq/)
        #run hlahd in background
        if [ 1 -gt 0 ]; then
            hlahd.sh -t 8 -m 100 -c 0.95 -f /tools/hlahd.1.2.0.1/freq_data/ $folder/HLA/hlavbseq/${sample}_extract_1.fq $folder/HLA/hlavbseq/${sample}_extract_2.fq /tools/hlahd.1.2.0.1/HLA_gene.split.txt /tools/hlahd.1.2.0.1/dictionary/ $sample $folder/HLA/hla_hd/estimation


            cp $folder/HLA/hla_hd/estimation/$sample/result/${sample}_final.result.txt $folder/HLA/$sample.hlahd.result
            #format the result
            for i in $(cat $folder/HLA/$sample.hlahd.result | grep -v "Not typed" | awk '{if ($3 == "-") $3=$2; print $2,$3}'); do 
                for p in $i; do 
                    echo $p 
                done
            done > $folder/HLA/$sample.hlahd.f.result
        fi &
    #####################
    ### HLA-miner v1.4 ##########

        HLA_miner="/tools/HLAminer-1.4/HLAminer_v1.4"
        fq1="$folder/HLA/hlavbseq/${sample}_extract_1.fq"
        fq2="$folder/HLA/hlavbseq/${sample}_extract_2.fq"
        hlaminer_out="$HLA_miner/test"
        #hlaminer_final="$folder/HLA/hlaminer"
        mkdir -p $hlaminer_out
        cd $hlaminer_out

        ### HPRAwgs_classI-II
            ### Run bwa or your favorite short read aligner
            echo "Running bwa..."
            #bwa index ../database/HLA-I_II_GEN.fasta
            bwa aln -e 0 -o 0 ../database/HLA-I_II_GEN.fasta $fq1 > $hlaminer_out/aln_test.1.sai
            bwa aln -e 0 -o 0 ../database/HLA-I_II_GEN.fasta $fq2 > $hlaminer_out/aln_test.2.sai
            bwa sampe -o 1000 ../database/HLA-I_II_GEN.fasta $hlaminer_out/aln_test.1.sai $hlaminer_out/aln_test.2.sai $fq1 $fq2 > $hlaminer_out/aln.sam
            ### Predict HLA
            echo "Predicting HLA..."
            ../bin/HLAminer.pl -a $hlaminer_out/aln.sam -h ../database/HLA-I_II_GEN.fasta -s 500
            ### install bio module on perl
            #cpan App::cpanminus
            #cpanm Bio::SearchIO
            #cpanm Bio::Perl 
            ###
            #apt-get install bioperl
        ### HPTASRwgs_classI-II
            echo $fq1 > patient.fof
            echo $fq2 >> patient.fof
            #perl_path=$(which perl)
            #cp ../bin/parseXMLblast.pl ../bin/parseXMLblast_test.pl 
            #sed "s:\/home\/martink\/bin\/perl:$perl_path:" ../bin/parseXMLblast.pl > ../bin/parseXMLblast_test.pl 
            #chmod +x ../bin/parseXMLblast_test.pl 
            ###Run TASR
            echo "Running TASR..."
            #TASR Default is -k 15 for recruiting reads. You may increase k, as long as k < L/2 where L is the minimum shotgun read length
            ../bin/TASR -f patient.fof -m 20 -k 20 -s ../database/HLA-I_II_GEN.fasta -i 1 -b TASRhla -w 1
            ###Restrict 200nt+ contigs
            cat TASRhla.contigs |perl -ne 'if(/size(\d+)/){if($1>=200){$flag=1;print;}else{$flag=0;}}else{print if($flag);}' > TASRhla200.contigs
            ###Create a [NCBI] blastable database
            echo "Formatting blastable database..."
            ../bin/formatdb -p F -i TASRhla200.contigs
            ###Align contigs against database
            echo "Aligning TASR contigs to HLA references..."
            ../bin/parseXMLblast_test.pl -c ../bin/ncbiBlastConfig.txt -d ../database/HLA-I_II_GEN.fasta -i TASRhla200.contigs -o 0 -a 1 > tig_vs_hla-ncbi.coord
            ###Align HLA references to contigs
            echo "Aligning HLA references to TASR contigs (go have a coffee, it may take a while)..."
            ../bin/parseXMLblast_test.pl -c ../bin/ncbiBlastConfig.txt -i ../database/HLA-I_II_GEN.fasta -d TASRhla200.contigs -o 0 > hla_vs_tig-ncbi.coord
            ###Predict HLA alleles
            echo "Predicting HLA alleles..."
            ../bin/HLAminer.pl -b tig_vs_hla-ncbi.coord -r hla_vs_tig-ncbi.coord -c TASRhla200.contigs -h ../database/HLA-I_II_GEN.fasta

        mv $hlaminer_out $folder/HLA/hlaminer
        cd $folder/HLA/hlaminer
        echo -e $(echo \
             $( cat HLAminer_HPRA.csv|grep "Prediction #" -A1 -B1 | grep -v '^--' | awk '{print $1}' | awk -v FS=',' '{print $1}' | sed -E 's/([[:digit:]])([[:alpha:]])$/\1/') \
            | sed 's/HLA/\\nHLA/g' ) > $folder/HLA/$sample.hlaminer_hpra.result
        cat $folder/HLA/$sample.hlaminer_hpra.result | sed 1d \
        | awk -v FS=' Prediction ' '{if ($3 == "") $3=$2; print "HLA-"$2"\nHLA-"$3}' \
        |sed 's/ ,/,/g' | sed 's/ .*$//' > $folder/HLA/$sample.hlaminer_hpra.f.result

        echo -e $(echo \
             $( cat HLAminer_HPTASR.csv|grep "Prediction #" -A1 -B1 | grep -v '^--' | awk '{print $1}' | awk -v FS=',' '{print $1}' | sed -E 's/([[:digit:]])([[:alpha:]])$/\1/') \
            | sed 's/HLA/\\nHLA/g' ) > $folder/HLA/$sample.hlaminer_hptasr.result
        cat $folder/HLA/$sample.hlaminer_hptasr.result | sed 1d \
        | awk -v FS=' Prediction ' '{if ($3 == "") $3=$2; print "HLA-"$2"\nHLA-"$3}' \
        |sed 's/ ,/,/g' | sed 's/ .*$//' > $folder/HLA/$sample.hlaminer_hptasr.f.result

    wait
    ls $folder/HLA/*.f.result

    mv $folder/HLA/*.f.result $folder
    
    mv $folder/HLA/kourami/${sample}_on_KouramiPanel.bam $folder/${sample}_hla.bam

    ############

    

  #done

