#!/bin/bash
#--------------------------------------------------------------------#
resolvers=/opt/resolvers.txt
smallwordlist=/opt/SecLists-master/Discovery/DNS/deepmagic.com-prefixes-top500.txt
wordlist=/opt/SecLists-master/Discovery/DNS/subdomains-top1million-20000.txt
templatefile=/opt/nuclei.txt
date=$(date +%d_%b_%Y)
mkdir "Project_$1"
cd "Project_$1"
cp ../$1 .
nuclei -update-templates
find ~/nuclei-templates -type f | grep .yaml > /tmp/nuclei.txt
sudo cp /tmp/nuclei.txt /opt
clear
#--------------------------------------------------------------------#

echo "#------------------------------------#"
echo "RUNNING SUBDOMAIN SCAN"
echo "#------------------------------------#"

for i in $(cat $1)
do
    echo "#------------------------------------#"
    echo $i
    echo "#------------------------------------#"
    
    # AMASS
    #amass enum -active -d $i -o amass_$i.txt -timeout 10
    
    # SUBFINDER
    subfinder -silent -d $i -timeout 10 -t 100 -nC -o subfinder_$i.txt

    # SHFFLEDNS
    shuffledns -massdns /opt/massdns -d $i -nC -r $resolvers -silent -w $wordlist -o shuffle_$i.txt

    # MERGING 
    cat *_$i.txt | sort | uniq >> temp.txt
    rm -rf *_$i.txt
done

#--------------------------------------------------------------------#

echo "#------------------------------------#"
echo "RUNNING THIRD LEVEL SUBDOMAIN SCAN"
echo "#------------------------------------#"

for i in $(cat temp.txt)
do
    shuffledns -massdns /opt/massdns -d $i -nC -silent -w $smallwordlist -r $resolvers -o third_temp_$i.txt
    cat *_$i.txt | sort | uniq >> temp.txt
    rm -rf *_$i.txt
done

cat temp.txt | sort | uniq > subdomains.txt
rm -rf temp.txt

#--------------------------------------------------------------------#

# SUBDOMAIN TO IP
echo "#------------------------------------#"
echo "SUBDOMAIN TO IP"
echo "#------------------------------------#"

cat subdomains.txt | while read domain
do
	dig +short $domain |grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> tempip.txt
done
cat tempip.txt | sort | uniq > ip.txt && rm -rf tempip.txt

#--------------------------------------------------------------------#

echo "#------------------------------------#"
echo "RUNNING MAIN RECON SCAN"
echo "#------------------------------------#"

for i in $(cat subdomains.txt)
do
    echo "#------------------------------------#"
    echo $i
    echo "#------------------------------------#"
    mkdir $i
    cd $i
    echo "SCAN STARTED ON $date" > SCANDATE.txt


    echo "------------URL EXTRACTION-------------"
    waybackurls $i >> urls.txt
    gau -subs $i >> urls.txt

    echo "------------PROBING-------------"
    cat urls.txt | httpx -silent -title -status-code  -fc 404 -o httpx.txt
    
    echo "------------PARAMETER DISCOVERY-------------"
    python3 /opt/ParamSpider/paramspider.py --level high -d $i -o $(pwd)/paramspider.txt

    echo "------------DALFOX-------------" 
    cat paramspider.txt httpx.txt > dalurls.txt 
    #dalfox file dalurls.txt -o $(pwd)/dalfox.txt 
    #mkdir dalfox #for url in $(cat paramspider.txt httpx.txt) #do
    # dalfox url $url -o dalfox/dalfox.txt
    #done

    echo "------------TEMPLATE SCANNING-------------"

    cat $templatefile | while read line
    do
      nuclei -l dalurls.txt -silent -t $line >> template_scan.txt
      echo "------------------" >> template_scan.txt
    done
    #echo "------------GITHOUND-------------"

    echo "------------FAVICON SCANNING-------------" 
    cat paramspider.txt httpx.txt | python3 /opt/FavFreak/favfreak.py -o favfreak.txt

    # javascript (jsscan)
    #
    # secret finding (secretfinder)
    #
    # directory scanning (dirsearch)
    python3 /opt/dirsearch/dirsearch.py -R 1 -u $i --simple-report=$(pwd)/dirsearch.txt
    # s3 bucket scan (s3bucketscan.py)
    #

    #echo "------------GF-PATTERNS-------------"

    echo "SCAN COMPLETED ON $date" >> SCANDATE.txt
    cd ..
done

#--------------------------------------------------------------------#
