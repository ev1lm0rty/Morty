#!/bin/bash

#-----------------------------------------------#
resolvers=/opt/resolvers.txt
smallwordlist=/opt/SecLists-master/Discovery/DNS/deepmagic.com-prefixes-top500.txt
wordlist=/opt/SecLists-master/Discovery/DNS/subdomains-top1million-20000.txt
fuzzword=/opt/SecLists-master/Discovery/Web
templatefile=/opt/nuclei.txt
date=$(date +%d_%b_%Y)
mkdir "Project_$1"
cd "Project_$1"
cp ../$1 .
#-----------------------------------------------#

subdomain_scan() {
    echo "#------------------------------------#"
    echo "RUNNING SUBDOMAIN SCAN"
    echo "#------------------------------------#"

    for i in $(cat $1)
    do
        echo "#------------------------------------#"
        echo $i
        echo "#------------------------------------#"
        # amass enum -active -d $i -o amass_$i.txt -timeout 10
        subfinder -silent -d $i -timeout 10 -t 100 -nC -o subfinder_$i.txt
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
        echo "#------------------------------------#"
        echo $i
        echo "#------------------------------------#"
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
    echo "------------URL EXTRACTION-------------"
    waybackurls $i >> urls.txt
    gau -subs $i >> urls.txt
    cat urls.txt | httpx -silent -title -status-code -content-length -fc 404 -o httpx.txt
}

param_discover(){
    echo "------------PARAMETER DISCOVERY-------------"
    python3 /opt/ParamSpider/paramspider.py --level high -d $i -o $(pwd)/paramspider.txt
}

dal_fox(){
    echo "------------DALFOX-------------" 
    cat paramspider.txt httpx.txt > dalurls.txt 
    dalfox file dalurls.txt -o $(pwd)/dalfox.txt 
}

template_scan(){
    nuclei -update-templates
    find ~/nuclei-templates -type f | grep .yaml > /tmp/nuclei.txt
    sudo cp /tmp/nuclei.txt /opt
     echo "------------TEMPLATE SCANNING-------------"

    cat $templatefile | while read line
    do
      nuclei -l dalurls.txt -silent -t $line >> template_scan.txt
      echo "------------------" >> template_scan.txt
    done
}

favicon_scan(){
     echo "------------FAVICON SCANNING-------------" 
    cat paramspider.txt httpx.txt | python3 /opt/FavFreak/favfreak.py -o favfreak.txt
}

dirfuzz(){
    echo  echo "------------FAVICON SCANNING-------------" 
    ffuf -u $1/FUZZ -w $fuzzword -o $1_ffuf.txt
}

main(){
    url_extract
    param_discover
    dal_fox
    template_scan
    favicon_scan
    dirfuzz $1
}


subdomain_scan
third_level
sub_to_ip

for i in $(cat subdomains.txt)
do
    mkdir $i
    cd $i
    main $i
    cd ..
done