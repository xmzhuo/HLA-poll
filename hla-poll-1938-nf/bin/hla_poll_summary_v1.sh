#summaryize the f.results
### generate a summary HLA typing report
resolution=$1
echo "summary"

cat *.f.result | grep -vw "-" | grep -vw "*" > all.temp
cat all.temp | awk -v FS=':' '{print $1}' >all_1.temp
cat all.temp | awk -v FS=':' '{print $1":"$2}' | sed 's/:$//' >all_2.temp
cat all.temp | awk -v FS=':' '{print $1":"$2":"$3}' | sed 's/:$//' >all_3.temp

sample=$(ls *.f.result | head -n1 | sed 's/\..*//')

echo "HLA_Poll V1.6 by Xinming Zhuo <xmzhuo@gmail.com>" > $sample.summary.csv
echo $sample,$(echo $(ls $sample*.f.result | sed "s/^.*$sample\.//"|sed 's/\.f.result$//') | sed 's/ /,/g'),Num_Caller,F_1,F_2,F_3,F_4 > $sample.summary.csv
hla_list="HLA-A HLA-B HLA-C HLA-E HLA-F HLA-G MICA MICB HLA-DMA HLA-DMB HLA-DOA HLA-DOB HLA-DPA1 HLA-DPB1 HLA-DQA1 HLA-DQB1 HLA-DRA HLA-DRB1 HLA-DRB5 TAP1 TAP2"
for p in $hla_list; do
    echo $p
    rm $p.type -f
    for i in $(ls $sample*.f.result); do
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
    echo $p,$(cat $p.type),$num_caller,$digit1,$digit2,$digit3,$digit4 | sed 's/ /,/g' | sed 's/,,-,/,-,/' >> $sample.summary.csv
    rm $p.type -f
done
rm *.temp -f
#hla-poll call
bash hla_poll_call*.sh $sample.summary.csv $resolution