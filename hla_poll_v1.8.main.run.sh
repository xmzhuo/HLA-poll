

#### hla_poll_v1.8.main.run.sh
###############################
bash hla_poll_v1.8.main.run.sh /data/in/ /data/out/ *.sub.sh
######## body of code ########

  folder="$1"
  out_folder="$2"
  sub_script="$3"
  sample=$4
  cd $folder
  
    sample=$(echo $sample | sed 's/\.bam//')
    
    echo $sample
    #index the bam file if bai not existed
    if [ ! -f $sample.bam.bai ] && [ ! -f $sample.bai ]; then
        echo "indexing $sample.bam"
        docker run --name ${sample}_samtools -v $1:/mydata -it xmzhuo/hla:0.0.9 /samtools/bin/samtools index $folder/$sample.bam
    else echo "bai file exist"
    fi


    wait

    ls *.bai
    
    ############

    if [ 1 == 1 ]; then

        ##polysolver###
        echo "run polysolver"
        #base on sachet/polysolver:v4
        container_NAME="${sample}_polysolver"
        d_jobs=$(docker container ls -a |grep "${sample}_polysolver" |wc -l)
        if [ $d_jobs -ge 1 ]; then docker rm ${sample}_polysolver -f; fi

        mkdir -p $folder/HLA/polysolver/$sample
        #polysolver parameters
        #-bam: path to the BAM file to be used for HLA typing
        #-race: ethnicity of the individual (Caucasian, Black, Asian or Unknown)
        #-includeFreq: flag indicating whether population-level allele frequencies should be used as priors (0 or 1)
        #-build: reference genome used in the BAM file (hg18 or hg19)
        #-format: fastq format (STDFQ, ILMFQ, ILM1.8 or SLXFQ; see Novoalign documentation)
        #-insertCalc: flag indicating whether empirical insert size distribution should be used in the model (0 or 1)
        #-outDir: output directory
        
        docker run -d -P --name $container_NAME -v $folder:/home/docker xmzhuo/polysolver:v4m2 \
            bash /home/polysolver/scripts/shell_call_hla_type /home/docker/$sample.bam Unknown 1 hg38 STDFQ 0 /home/docker/HLA/polysolver/$sample
        
        #check the status of running
        while :; do
            if [ -f $folder/HLA/polysolver/$sample/winners.hla.txt ]; then break; else sleep 10; fi
        done

        cp $folder/HLA/polysolver/$sample/winners.hla.txt $folder/HLA/$sample.polysolver.result

        cat $folder/HLA/$sample.polysolver.result | sed 's/[a-z]*_[a-z]_//g' | sed 's/_/:/g' | awk '{print $1"*"$2"\n"$1"*"$3}' > $folder/HLA/$sample.polysolver.f.result

        docker rm $container_NAME -f

    fi &
    ####

    if [ 1 == 1 ]; then
        echo "## run hla-hd, hla-scan and kourami, hla-vbseq, hlaminer"
        #launch docker of xmzhuo/hla:0.0.9 for kourami, hlascan, hlahd, hlavbseq and hlaminer
        #docker load -i ~/xmzhuo_hla_0.0.7.tar
        
        #close any running container with the same name
        d_jobs=$(docker container ls -a |grep "${sample}_hla" |wc -l)
        if [ $d_jobs -ge 1 ]; then docker rm ${sample}_hla -f; fi

        docker run -d -P --name ${sample}_hla -v $1:/mydata xmzhuo/hla:0.0.9 bash /mydata/$sub_script $sample.bam $folder

        wait

        while :; do
            if [ -f $folder/HLA/$sample.hlaminer_hptasr.f.result ]; then break; else sleep 10; fi
        done

        docker rm ${sample}_hla

    fi
    #check if all container closed and exit
    while :; do
        docker container ls -a |grep "$sample"
        d_jobs=$(docker container ls -a |grep "$sample" |wc -l)
        if [ $d_jobs -lt 1 ]; then break; else sleep 10; fi
    done

    #summaryize the f.results
    ### generate a summary HLA typing report
        cd $folder/HLA
        echo "summary"

        cat *.f.result | grep -vw "-" | grep -vw "*" > all.temp
        cat all.temp | awk -v FS=':' '{print $1}' >all_1.temp
        cat all.temp | awk -v FS=':' '{print $1":"$2}' | sed 's/:$//' >all_2.temp
        cat all.temp | awk -v FS=':' '{print $1":"$2":"$3}' | sed 's/:$//' >all_3.temp

        echo "HLA_Poll V1.6 by Xinming Zhuo <xmzhuo@gmail.com>" > $folder/HLA/$sample.summary.csv
        echo $sample,$(echo $(ls $folder/HLA/$sample*.f.result | sed "s/^.*$sample\.//"|sed 's/\..*$//') | sed 's/ /,/g'),Num_Caller,F_1,F_2,F_3,F_4 > $folder/HLA/$sample.summary.csv
        hla_list="HLA-A HLA-B HLA-C HLA-E HLA-F HLA-G MICA MICB HLA-DMA HLA-DMB HLA-DOA HLA-DOB HLA-DPA1 HLA-DPB1 HLA-DQA1 HLA-DQB1 HLA-DRA HLA-DRB1 HLA-DRB5 TAP1 TAP2"
        for p in $hla_list; do
            echo $p
            rm $p.type -f
            for i in $(ls $folder/HLA/$sample*.f.result); do
                caller=$(echo $i| sed "s/^.*$sample\.//"|sed 's/\..*$//')
                type=$(echo $(cat $i | grep $p) | sed 's/ /\//')
                echo $type >> $p.type
                if [ -z $type ]; then echo "-" >> $p.type; fi
            done
            digit1=$(echo $(cat all_1.temp | sort | uniq -c | sort -n -r | grep "$p" | awk '{if ($1 > 1) print $1"_"$2}'| head -n3) |sed 's/ /\//g')
            digit2=$(echo $(cat all_2.temp | sort | uniq -c | sort -n -r | grep "$p" | awk '{if ($1 > 1) print $1"_"$2}'| head -n3) |sed 's/ /\//g')
            digit3=$(echo $(cat all_3.temp | sort | uniq -c | sort -n -r | grep "$p" | awk '{if ($1 > 1) print $1"_"$2}'| head -n3) |sed 's/ /\//g')
            digit4=$(echo $(cat all.temp | sort | uniq -c | sort -n -r | grep "$p" | awk '{if ($1 > 1) print $1"_"$2}'| head -n3) |sed 's/ /\//g')
            num_caller=$( cat $p.type | grep "." | grep -wv "-" |wc -l )
            echo $p,$(cat $p.type),$num_caller,$digit1,$digit2,$digit3,$digit4 | sed 's/ /,/g' | sed 's/,,-,/,-,/' >> $folder/HLA/$sample.summary.csv
            rm $p.type -f
        done
        rm *.temp -f
    
    bash $folder/HLA/$sample.summary.csv

#making hla_poll call
    sample_hla=$folder/HLA/$sample.summary.csv
    resolution=2
    header=$(sed -n 1p $sample_hla)
    hlapoll_output=$(echo $sample_hla | sed 's/summary.csv/hla_poll.csv/g')
    echo $header,hla_poll > $hlapoll_output
    for linei in $(sed 1d $sample_hla); do
        init_call=$(echo $linei | awk -v FS=',' -v var=$resolution '{print $(9+var)}')
        #echo $init_call
        #caller_num=$(echo $linei | awk -v FS=',' -v var=$resolution '{print $9}')
        caller_num=0;for numa in $(echo "$init_call" | sed "s/\//\n/g" | sed "s/\_.*//"); do caller_num=$(expr $caller_num + $numa); done
        #control at least 20% to call a hla type, when more than 5 callers, need at lease 3 call to call a type
        if [ $caller_num -le 10 ]; then
            #count_threshold=$(awk -v var=$caller_num 'BEGIN{print int(2*var*0.2-0.1)}')
            count_threshold=1
        else
            count_threshold=2
        fi
        #echo $caller_num:$count_threshold
        sec_call=$(echo $init_call | sed 's/\//\n/g' | grep -v "^${count_threshold}_")
        #echo $sec_call
        #need at least two caller agree (rule out the condition of one caller make homozygous call)
        
        for linep in $sec_call; do
            call_chk=$(echo $linep | sed 's/^.*_//g')
        
            call_temp=$(echo $call_chk | sed 's/\*/\\*/g')
            #echo $call_temp
            call_count=$(echo $linei | awk -v FS=',' '{print $2"\n"$3"\n"$4"\n"$5"\n"$6"\n"$7"\n"$8}' | grep "${call_temp}" | wc -l)
            if [ $call_count -gt 1 ]; then
                echo $call_chk >> call.temp
            fi

        done

        hla_poll=$(echo $(cat call.temp)| sed 's/ /\//g')

        if [ $(cat call.temp |wc -l) -eq 1 ];then
            hla_poll=$(echo $hla_poll"/"$hla_poll)
        fi
    
        rm call.temp -f

        #echo $hla_poll
        
        fin_call=$(echo $linei,$hla_poll)

        echo $fin_call >> $hlapoll_output

    done

    cd $folder
    mkdir -p $out_folder/$sample.HLA/
    mv $folder/HLA/*.result $out_folder/$sample.HLA/
    mv $folder/HLA/*.csv $out_folder/$sample.HLA/
    rm $sample.bam $sample.bai

#  done

##############################################
