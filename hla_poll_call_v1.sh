# Xinming Zhuo PhD; xmzhuo@gmail.com
#This is the script used in master script; it also can stand alone for calling previous result. Also can modified for selection of callers for polling.
#call hla with optimized setting
#input 1. call summary report 2. resolution (2,default 4,6,8)
#bash hla_poll_call.sh sample.summary.csv resolution

sample_hla=$1
if [ -z $2 ]; then
    resolution=2
else
    resolution=$(awk -v var=$2 'BEGIN{print int(var/2)}')
fi

echo $sample_hla
echo Field $resolution

header=$(sed -n 1p $sample_hla)
output=$(echo $sample_hla | sed 's/summary.csv/hla_poll.csv/g')
echo $header,hla_poll > $output
for linei in $(sed 1d $sample_hla); do
    init_call=$(echo $linei | awk -v FS=',' -v var=$resolution '{print $(9+var)}')
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

    echo $fin_call >> $output

done
