#!/bin/bash

#-----------------------------------------------#
resolvers=/opt/resolvers.txt
smallwordlist=/opt/SecLists-master/Discovery/DNS/deepmagic.com-prefixes-top500.txt
wordlist=/opt/SecLists-master/Discovery/DNS/subdomains-top1million-20000.txt
fuzzword=/opt/SecLists-master/Discovery/Web-Content/raft-small-words.txt
templatefile=/opt/nuclei.txt
eye=/opt/EyeWitness/Python/EyeWitness.py
date=$(date +%d_%b_%Y)

if [[ ! -d "Project_$1" ]]
then
  mkdir "Project_$1"
fi

cd "Project_$1"
cp ../$1 .

nuclei -update-templates
find ~/nuclei-templates -type f -not -path '*/\.*' | grep .yaml > /tmp/nuclei.txt
sudo cp /tmp/nuclei.txt /opt

gf -list > /tmp/gf.txt
sudo mv /tmp/gf.txt /opt

clear

#-----------------------------------------------#

subdomain_scan() {
    echo "#------------------------------------#"
    echo "RUNNING SUBDOMAIN SCAN"
    echo "#------------------------------------#"

    for i in $(cat $1)
    do
        echo "#~~~~~~~~~~#"
        echo $i
        echo "#~~~~~~~~~~#"
        # amass enum -active -d $i -o amass_$i.txt -timeout 10
        subfinder -silent -d $i -timeout 10 -t 100 -nW -nC -o subfinder_$i.txt
        shuffledns -massdns /opt/massdns -d $i -nC -r $resolvers -silent -w $wordlist -o shuffle_$i.txt
        cat *_$i.txt | sort | uniq >> temp.txt
        rm -rf *_$i.txt
    done

}

third_level() {
    echo "#------------------------------------#"
    echo "RUNNING THIRD LEVEL SUBDOMAIN SCAN"
    echo "#------------------------------------#"

    for i in $(cat temp.txt)
    do
        echo "#~~~~~~~~~~#"
        echo $i
        echo "#~~~~~~~~~~#"
        shuffledns -massdns /opt/massdns -d $i -nC -silent -w $smallwordlist -r $resolvers -o third_temp_$i.txt
        cat *_$i.txt | sort | uniq >> temp.txt
        rm -rf *_$i.txt
    done

    cat temp.txt | sort | uniq > subdomains.txt
    rm -rf temp.txt
}

sub_to_ip() {
    echo "#------------------------------------#"
    echo "SUBDOMAIN TO IP"
    echo "#------------------------------------#"

    cat subdomains.txt | while read domain
    do
        dig +short $domain |grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> tempip.txt
    done
    cat tempip.txt | sort | uniq > ip.txt && rm -rf tempip.txt
}

url_extract() {
    echo "#------------------------------------#"
    echo "URL EXTRACTION"
    echo "#------------------------------------#"
    waybackurls $i >> urls.txt
    gau -subs $i >> urls.txt
    cat urls.txt | httpx -no-color -silent -title -status-code -content-length -fc 404 -o httpx.txt

}

param_discover(){
    echo "#------------------------------------#"
    echo "PARAMETER DISCOVERY"
    echo "#------------------------------------#"
    python3 /opt/ParamSpider/paramspider.py --level high -d $i -o $(pwd)/paramspider.txt
}

dal_fox(){
    echo "#------------------------------------#"
    echo "XSS SCAN"
    echo "#------------------------------------#"
    dalfox file urls.txt -o $(pwd)/dalfox.txt 
}

template_scan(){
    echo "#------------------------------------#"
    echo "TEMPLATE SCAN"
    echo "#------------------------------------#"
    mkdir template_scan
    cd template_scan
    for line in $(cat /opt/nuclei.txt) 
    do
      nuclei -l ../urls.txt -silent -t $line -no-color -o ${line}_scan.txt
    done
    cd ..
}

favicon_scan(){
    echo "#------------------------------------#"
    echo "FAVICON SCAN"
    echo "#------------------------------------#"
    cat urls.txt | python3 /opt/FavFreak/favfreak.py -o favfreak.txt
}

dirfuzz(){
    echo "#------------------------------------#"
    echo "DIR FUZZING"
    echo "#------------------------------------#"
    #ffuf -s -u  https://$1/FUZZ -w $fuzzword -o $1_ffuf.txt
    /opt/gobuster dir -u $1 -w $fuzzword -o $1_gobuster.txt -q -t 100 
}

port_scan(){
    echo "#------------------------------------#"
    echo "PORT SCAN"
    echo "#------------------------------------#"
    sudo $naabu -iL ip.txt -p - -nC -o portscan.txt -nmap
}

s3_scan(){
    echo "#------------------------------------#"
    echo "S3 SCAN"
    echo "#------------------------------------#"
    python3 /opt/S3Scanner/s3scanner.py -l subdomains.txt -o buckets.txt
}

pattern_search(){
    echo "#------------------------------------#"
    echo "PATTERN SEARCH" 
    echo "#------------------------------------#" 
    mkdir pattern
    for i in $(cat /opt/gf.txt)
    do
      cat urls.txt paramspider.txt | gf $i > pattern/${i}.txt
    done
}

screen_shot(){
    echo "#------------------------------------#"
    echo "SCREENSHOT" 
    echo "#------------------------------------#" 
    python3 $eye -d $1_SCREEN -f subdomains.txt
}

main(){
   toilet -f pagga --metal "MORTY SCAN"
   if [[ ! -f subdomains.txt ]]
   then
    subdomain_scan $1
    third_level
   fi

   if [[ ! -f ip.txt ]]
   then
    sub_to_ip
   fi

   if [[ ! -f buckets.txt ]]
   then
    s3_scan
   fi

    #screen_shot $1

    for i in $(cat subdomains.txt)
    do
      if [[ ! -f $i/COMPLETED ]]
      then
        mkdir $i
        cd $i
        url_extract
        param_discover
        dal_fox
        template_scan
        favicon_scan
        dirfuzz $i
        pattern_search
        touch COMPLETED
        cd ..
      fi
    done
    port_scan
}

main $1
