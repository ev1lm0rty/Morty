#!/bin/bash


mkdir "$1_$date"
cd "$1_$date"

for i in $(cat $1)
do
    # amass subdomain scan
    # subfinder subdomain scan
    # shuffle dns scan
    # shuffle dns bruteforce scan
    # third level domains (use small list)
    # combine all results 
    # create a subdomains.txt file
done

for i in $(cat subdomains.txt)
do
    mkdir $i
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
done

    
