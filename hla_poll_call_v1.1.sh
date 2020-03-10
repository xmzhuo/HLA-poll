#call hla with optimized setting
#input 1. call summary report 2. resolution (2,default 4,6,8)
#bash hla_poll_call.sh sample.summary.csv resolution
#for i in $(ls AFR/*summary.csv); do echo $i; bash hla_poll_call_v1.1.sh $i 4; done
#compare with v1, v1.1 reduce the impact of hlaminer(at least hlaminer + one another to make a call), also allow dynamic filtering at >10 caller (allow future increase number of callers)

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
echo $output
echo $header,hla_poll > $output
Num_caller_pos=$(cat $sample_hla | sed -n 1p |sed 's/,/\n/g' | awk '/Num_Caller/{print NR}')

for linei in $(sed 1d $sample_hla); do
    #get the corresponding calling info such as F_2 for 4 digit resolution (2 field)
    init_call=$(echo $linei | awk -v FS=',' -v var1=$Num_caller_pos -v var2=$resolution '{print $(var1+var2)}')
    #caller_num=$(echo $linei | awk -v FS=',' -v var=$resolution '{print $9}')
    #count total calling number in F_2
    caller_num=0;for numa in $(echo "$init_call" | sed "s/\//\n/g" | sed "s/\_.*//"); do caller_num=$(expr $caller_num + $numa); done
    #control at least 20% to call a hla type, when less than 5 callers, at least 2 call, when more than 5 callers, need at lease 3 call to call a type
    #if [ $caller_num -le 10 ]; then
    #    #count_threshold=$(awk -v var=$caller_num 'BEGIN{print int(2*var*0.2-0.1)}')
    #    count_threshold=1
    #else
    #    count_threshold=2
    #fi
    count_threshold=$(awk -v var=$caller_num 'BEGIN{print int((var-1)*0.2)}')
    #echo $caller_num:$count_threshold
    #filter the call with threshold
    #sec_call=$(echo $init_call | sed 's/\//\n/g' | grep -v "^${count_threshold}_")
    sec_call=$(echo $init_call | sed 's/\//\n/g' | awk -F'_' -v var=${count_threshold} '{ if ( $1 > var ) print}')
    #echo $sec_call

    #need at least two caller agree (except hlaminer-hpra and hptasr, treat as one) (rule out the condition of one caller make homozygous call)
    
    for linep in $sec_call; do
        call_chk=$(echo $linep | sed 's/^.*_//g')
       
        call_temp=$(echo $call_chk | sed 's/\*/\\*/g')
        #echo $call_temp
        call_count=$(echo $linei | awk -v FS=',' '{print $2"\n"$3"\n"$4"\n"$5"\n"$6"\n"$7"\n"$8}' | grep "${call_temp}" | wc -l)
        #treat hlaminer-hpra and hptasr as the same for counting differnt caller, $3 and $4
        call_count=$(echo $linei | awk -v FS=',' '{print $2"\n"$3","$4"\n"$5"\n"$6"\n"$7"\n"$8}' | grep "${call_temp}" | wc -l)
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