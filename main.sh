#!/bin/bash

smallwordlist=test.txt
wordlist=test.txt
resolvers=resolver.txt
date=$(date +%d_%b_%Y)
mkdir "Project_$1"
cd "Project_$1"
cp ../$1 .

# top level subdomain scan
for i in $(cat $1)
do
    # amass subdomain scan
    amass enum -active -df $i -o amass_$i.txt

    # subfinder subdomain scan
    subfinder -d $i -nW -rL $resolvers -silent -nC -o subfinder_$i.txt

    # shuffle dns scan
    shuffledns -d $i -nC -r $resolvers -silent -w $wordlist -o shuffle_$i.txt

    # combine all results 
    cat *_$i.txt | sort | uniq >> temp.txt
    rm -rf *_$i.txt
done

# third level domains (use small list)
for i in $(cat temp.txt)
do
    shuffledn -d $i -nC -silent -w $smallwordlist -r $resolvers -o third_temp_$i.txt
    cat *_$i.txt | sort | uniq >> temp.txt
    rm -rf *_$i.txt
done

cat temp.txt | sort | uniq > subdomains.txt
rm -rf temp.txt

for i in $(cat subdomains.txt)
do
    mkdir $i
    cd $i
    echo "SCAN STARTED ON $date" > SCANDATE.txt

    # template scanning (nuclei)
    # subdomain takeover
    # port scanning (naabu)
    # url extraction (waybackurl , gao)
    # parameter discovery (paramspider)
        # xss (delfox) 
    # github scanning (githound) 
    # favicon hash extraction (favfreak) 
    # javascript (jsscan)
    # secret finding (secretfinder)
    # directory scanning (dirsearch)
    # s3 bucket scan (s3bucketscan.py)
    # screenshot (eyewitness)
    # github dork list (jhaddix script)
    # google dork list (custom script)
    # whatweb
    # probing (httpx)
    # vuln pattern search (gfpatterns)
    
    echo "SCAN COMPLETED ON $date" >> SCANDATE.txt
    cd ..
done

    
