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
    shuffledns -massdns /opt/massdns -d $i -w $wordlist -r $resolvers -o ${i}_brute.txt
  done

  cat *brute.txt | sort | uniq > brute_force_domain.txt
  rm -rf *brute.txt
  
}

subdomain_scan() {
    echo "#------------------------------------#"
    echo "RUNNING SUBDOMAIN SCAN"
    echo "#------------------------------------#"

    #amass enum -active -df $1 -o amass.txt -timeout 1 -max-dns-queries 150 -noresolvrate 
    subfinder -silent -dL $1 -timeout 5 -t 100 -nW -nC -o subfinder.txt &
    shuffledns -massdns /opt/massdns -list $1 -nC -r $resolvers -silent -w $wordlist -o shuffle.txt &
    wait
    cat *brute.txt amass.txt subfinder.txt shuffle.txt brute_force_domain.txt 2>/dev/null | sort | uniq >> subdomains.txt
    rm -rf *brute.txt amass.txt subfinder.txt shuffle.txt

}

third_level() {
    echo "#------------------------------------#"
    echo "RUNNING THIRD LEVEL SUBDOMAIN SCAN"
    echo "#------------------------------------#"

    for i in $(cat subdomains.txt)
    do
      shuffledns -massdns /opt/massdns -d $i -r $resolvers -o $i_third.txt 
    done

    cat *third.txt subdomains.txt | sort | uniq > temp.txt
    mv temp.txt subdomains.txt

    if [[ $# -eq 1 ]]
    then
      comm -23 <(sort subdomains.txt) <(sort $1 ) | tac > mm.txt
      mv mm.txt subdomains.txt
    fi
    rm -rf temp.txt third_temp.txt
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
    cat raw_urls.txt | sort | uniq | gf files > urls.txt
    cat urls.txt | httpx -no-color -silent -title -status-code -content-length -fc 404 -o httpx.txt  2>/dev/null
    cat httpx.txt | awk '{print $1}'| sort | uniq > urls.txt
    python3 /opt/ParamSpider/paramspider.py --level high -d $i -o $(pwd)/paramspider.txt  2>/dev/null >/dev/null
    cat paramspider.txt >> urls.txt
    cat urls.txt | sed 's/=.*//' > temp_url.txt
    mv temp_url.txt urls.txt
    touch URL
}

dal_fox(){
    echo "#------------------------------------#"
    echo "XSS SCAN ( $1 )"
    echo "#------------------------------------#"
    cat urls.txt  | sort | uniq | /opt/kxss | awk '{print $NF}' | gf files | sed 's/=.*/=/' | dalfox pipe -w 1000  -o $(pwd)/dalfox.txt
    touch DALFOX
}

template_scan(){
    echo "#------------------------------------#"
    echo "TEMPLATE SCAN ( $1 )"
    echo "#------------------------------------#"
    nuclei -l urls.txt -silent -t ~/nuclei-templates -o template_scan.txt
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
    cat portscan.txt  | awk '{print $3}' | sort | uniq | tr '\n' ',' | sed 's/.$//' > open_ports.txt
}

nmap_scan(){
  echo "#------------------------------------#"
  echo "PORT SCAN "
  echo "#------------------------------------#"

  sudo nmap -sCV -oN nmap_connect_scan.txt -Pn -p $(cat open_ports.txt) -iL ip.txt
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
    mkdir AQUATONE
    cat subdomains.txt | /opt/aquatone -out ./AQUATONE -silent -threads 100 2>/dev/null
    touch SCREEN
}

secret_find(){
    echo "#------------------------------------#"
    echo "SECRETFINDER ( $1 )" 
    echo "#------------------------------------#" 
    cat *.txt | grep .js > js.txt
    python3 /opt/secretfinder/SecretFinder.py -i js.txt -o secretfinder.html 2>/dev/null 
    touch SECRET
}

cleanup(){
  rm -rf gecko*
  find . -empty > DELETED_EMPTYFILES.txt
  find . -empty -delete
}

main(){
   toilet -f pagga --metal "MORTY SCAN"
   echo "--------------------------------------"
   echo
   echo "#~~~~~~~~( $1 )~~~~~~~~#"
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

        # if [[ ! -f FAV ]]
        # then
        #  favicon_scan $i & 
        # fi

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

    cleanup
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
