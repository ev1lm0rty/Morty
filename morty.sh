#!/bin/bash

#-----------------------------------------------#
date=$(date +%d_%b_%Y)
resolvers=/opt/resolvers.txt
templatefile=/opt/nuclei.txt
eye=/opt/EyeWitness/Python/EyeWitness.py
wordlist=/opt/SecLists-master/Discovery/DNS/dns-Jhaddix.txt
fuzzword=/opt/SecLists-master/Discovery/Web-Content/raft-large-words.txt
smallwordlist=/opt/SecLists-master/Discovery/DNS/deepmagic.com-prefixes-top500.txt
#-----------------------------------------------#

subdomain_brute(){
  echo "#------------------------------------#"
  echo "RUNNING SUBDOMAIN-BRUTE"
  echo "#------------------------------------#"

  for i in $(cat $1)
  do
    shuffledns -silent -massdns /opt/massdns -d $i -w $wordlist -r $resolvers -o ${i}.btemp
  done

  cat *.btemp | sort -u > bf.stemp
  rm -rf *.btemp
}

subdomain_scan() {
    echo "#------------------------------------#"
    echo "RUNNING SUBDOMAIN SCAN"
    echo "#------------------------------------#"

    #amass enum -active -df $1 -o amass.txt -timeout 1 -max-dns-queries 150 -noresolvrate
    #curl -v -silent https://$1 --stderr - | awk '/^content-security-policy:/' | grep -Eo "[a-zA-Z0-9./?=_-]*" |  sed -e '/\./!d' -e '/[^A-Za-z0-9._-]/d' -e 's/^\.//' | sort -u > csp.stemp
    #curl -s "https://crt.sh/?q=%25.$1&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u >> crt.stemp 
    subfinder -silent -dL $1 -timeout 5 -t 100 -nW -nC -o subfinder.stemp &
    shuffledns -silent -massdns /opt/massdns -list $1 -nC -r $resolvers -silent -o shuffle.stemp &
    wait
    
    #test=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    #wget https://chaos-data.projectdiscovery.io/$test.zip 2>/dev/null 
    
    #if [[ -f $test.zip ]]
    #then
      #unzip $test.zip && rm -rf $test.zip
    #fi

    cat *.stemp $test.txt 2> /dev/null | sort -u >> subdomains.txt
    sed -i '/ /d' subdomains.txt
    rm -rf *.stemp

}

third_level() {
    echo "#------------------------------------#"
    echo "RUNNING THIRD LEVEL SUBDOMAIN SCAN"
    echo "#------------------------------------#"

    #for i in $(cat subdomains.txt)
    #do
    #  shuffledns -silent -massdns /opt/massdns -d $i -r $resolvers -o $i_third.txt -w $smallwordlist
    #done

    #cat *_third.txt subdomains.txt | sort -u > temp.tdtemp
    #rm -rf *_third.txt
  
    if [[ $# -eq 1 ]]
    then
      comm -23 <(sort temp.tdtemp) <(sort $1 ) > mm.txt
      mv mm.txt temp.tdtemp
    fi

    #tac temp.tdtemp | filter-resolved > subdomains.txt
    sed -i '/ /d' subdomains.txt
    mv subdomains.txt original.txt
    cat original.txt | filter-resolved > subdomains.txt
    
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
    echo "URL EXTRACTION ( $1 )"
    echo "#------------------------------------#"

    waybackurls -no-subs $i >> raw_urls.txt
    gau $i >> raw_urls.txt
    python3 /opt/ParamSpider/paramspider.py --level high -d $i -o $(pwd)/paramspider.txt  2>/dev/null >/dev/null
    cat paramspider.txt >> raw_urls.txt && rm -rf paramspider.txt
    cat raw_urls | sort -u | gf files | httpx -no-color -silent -title -status-code -fc 404 -content-length -o httpx.txt  2>/dev/null
    cat httpx.txt | awk '{print $1}'| sort -u > alive_urls.txt
    cat alive_urls.txt | qsreplace -a > urls.txt
    touch URL
}

dal_fox(){
    echo "#------------------------------------#"
    echo "XSS SCAN ( $1 )"
    echo "#------------------------------------#"
    
    cat urls.txt | /opt/kxss | awk '{print $NF}' | sed 's/=.*/=/' > kxss.txt
    cat kxss.txt | dalfox pipe -w 1000  -o $(pwd)/dalfox.txt
    touch DALFOX
}

template_scan(){
    echo "#------------------------------------#"
    echo "TEMPLATE SCAN ( $1 )"
    echo "#------------------------------------#"
    
    nuclei -l urls.txt -silent -c 900 -t ~/nuclei-templates -o template_scan.txt
    touch TEMPLATE
}

favicon_scan(){
    echo "#------------------------------------#"
    echo "FAVICON SCAN ( $1 )"
    echo "#------------------------------------#"
    
    cat urls.txt | python3 /opt/FavFreak/favfreak.py -o favfreak.txt 2>/dev/null >/dev/null
    touch FAV
}

dirfuzz(){
    echo "#------------------------------------#"
    echo "DIR FUZZING ( $1 )"
    echo "#------------------------------------#"
    
    /opt/gobuster dir -u $1 -w $fuzzword -o $1_gobuster.txt -q -t 100  2>/dev/null
    touch FUZZ
}

port_scan(){
    echo "#------------------------------------#"
    echo "PORT SCAN "
    echo "#------------------------------------#"
 
    sudo masscan -iL ip.txt -p 1-65535 -oL portscan.txt --rate=1000 -Pn 2>/dev/null
    cat portscan.txt  | awk '{print $3}' | sort -u | sed '/^$/d' | tr '\n' ',' | sed 's/,$//' > open_ports.txt
}

nmap_scan(){
  echo "#------------------------------------#"
  echo "NMAP SCAN "
  echo "#------------------------------------#"

  mkdir nmap
  sudo nmap -sCV --script=vuln -oA nmap/nmap_connect_scan.txt -Pn -p $(cat open_ports.txt) -iL ip.txt
}

s3_scan(){
    echo "#------------------------------------#"
    echo "S3 SCAN ( $1 )"
    echo "#------------------------------------#"

    python3 /opt/S3Scanner/s3scanner.py -l subdomains.txt -o buckets.txt 2>/dev/null
    touch S3
}

pattern_search(){
    echo "#------------------------------------#"
    echo "PATTERN SEARCH ( $1 )" 
    echo "#------------------------------------#" 

    mkdir pattern
    for i in $(cat /opt/gf.txt)
    do
      cat urls.txt  2>/dev/null | gf $i > pattern/${i}.txt
    done
    touch PATTERN
}

screen_shot(){
    echo "#------------------------------------#"
    echo "SCREENSHOT ( $1 )" 
    echo "#------------------------------------#" 

    #python3 $eye -d $1_EYE -f subdomains.txt --no-prompt --threads 100 --max-retries 0 2>/dev/null 
    mkdir SCREENSHOT
    cat subdomains.txt | /opt/aquatone -out ./SCREENSHOT -silent -threads 100 2>/dev/null
    touch SCREEN
}

secret_find(){
    echo "#------------------------------------#"
    echo "SECRETFINDER ( $1 )" 
    echo "#------------------------------------#" 
    cat raw_urls.txt | grep .js | sort -u > sf.txt
    python3 /opt/secretfinder/SecretFinder.py -i sf.txt -o secretfinder.html 2>/dev/null 
    touch SECRET
}

cors_misconfig(){
  # wont use, too slow
  cat urls.txt | while read url;do target=$(curl -s -I -H "Origin: https://evil.com" -X GET $url) | if grep 'https://evil.com'; then echo "[Potentional CORS Found] $url" | tee -a cors.txt; fi;done
}

takeover(){
  echo "#------------------------------------#"
  echo "SUBDOMAIN TAKEOVER ( $1 )" 
  echo "#------------------------------------#" 
  
  #subjack -w subdomains.txt -t 500 -o subdomain_takeover.txt -ssl -a
  subzy -targets subdomains.txt | tee subdomain_takeover.txt
}

cleanup(){
  echo "#------------------------------------#"
  echo "CLEANUP" 
  echo "#------------------------------------#" 

  find . -empty -delete
  mkdir PORT_SCAN SUBDOMAINS INFO
  mv nmap ip.txt open_ports.txt portscan.txt PORT_SCAN
  mv $1 INFO
  for i in $(cat subdomains.txt) ; do mv $i SUBDOMAINS/ ; done
  mv subdomains.txt INFO
}

main(){
   toilet -f pagga --metal "MORTY SCAN"
   echo "--------------------------------------"
   echo
   echo "#~~~~~~~~( Project: $1 )~~~~~~~~#"
   echo

   if [[ ! -f subdomains.txt ]]
   then
    subdomain_brute $1
    subdomain_scan $1

    if [[ $# -eq 2  ]]
    then
      third_level $2
    else
      third_level
    fi
   fi

   if [[ ! -f subdomain_takeover.txt ]]
   then
     takeover
   fi

   if [[ ! -f ip.txt ]]
   then
    sub_to_ip &
   fi

   if [[ ! -f buckets.txt ]]
   then
    s3_scan $1 &
   fi

   if [[ ! -f SCREEN ]]
   then
    screen_shot $1 &
   fi

    for i in $(cat subdomains.txt)
    do
      if [[ ! -f $i/COMPLETED ]]
      then
        if [[ ! -d $i ]]
        then
            mkdir $i
        fi
        cd $i

        if [[ ! -f URL ]]
        then
          url_extract $i 
        fi

        if [[ ! -f DALFOX ]]
        then
         dal_fox $i  &
        fi

        if [[ ! -f TEMPLATE ]]
        then
         template_scan $i & 
        fi

        if [[ ! -f FAV ]]
         then
          favicon_scan $i & 
        fi

        if [[ ! -f FUZZ ]]
        then
         dirfuzz $i &
        fi

        if [[ ! -f PATTERN ]]
        then
         pattern_search $i & 
        fi

        if [[ ! -f SECRET ]]
        then
         secret_find $i &
        fi
        wait
        touch COMPLETED
        rm -rf URL PARAM DALFOX SECRET PATTERN FUZZ FAV TEMPLATE
        cd ..
      fi
    done

    if [[ ! -f portscan.txt ]]
    then
      port_scan
    fi

    if [[ ! -f nmap_connect_scan.txt ]]
    then
      nmap_scan
    fi

    cleanup $1
    echo "Finished on $date" >> COMPLETED
    cd ..
    zip -r $1.zip Project_$1 && rm -rf Project_$1 $1 $2
}

if [[ $# -lt 1 ]]
then
  echo -e "Usage ./morty.sh <targetfile> <outofscopefile>\n\n"
else
  if [[ ! -d "Project_$1" ]]
  then
    mkdir "Project_$1"
  fi

  # Setting up environment
  cd "Project_$1" 2> /dev/null
  cp ../$1 . 2> /dev/null
  cp ../$2 . 2>/dev/null
  nuclei -update-templates -silent
  find ~/nuclei-templates -type f -not -path '*/\.*' | grep .yaml > /tmp/nuclei.txt
  sudo cp /tmp/nuclei.txt /opt
  gf -list > /tmp/gf.txt
  sudo mv /tmp/gf.txt /opt
  clear

  if [[ $# -eq 1 ]]
  then
    main $1
  else
    main $1 $2
  fi

fi
