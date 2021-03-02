#!/bin/bash

#-----------------------------------------------#
date=$(date +%d_%b_%Y)
dns1=Tools/SecLists-master/Discovery/DNS/dns-Jhaddix.txt
dns2=Tools/SecLists-master/Discovery/DNS/deepmagic.com-prefixes-top500.txt
w1=Tools/SecLists-master/Discovery/Web-Content/raft-large-files.txt
w2=Tools/SecLists-master/Discovery/Web-Content/raft-large-words.txt
res1=Tools/resolvers.txt
templates=Tools/nuclei-templates
s3scanner=Tools/S3Scanner/s3scanner.py
gf=Tools/patterns.txt
#-----------------------------------------------#

subdomain_brute(){
  echo "#------------------------------------#"
  echo "RUNNING SUBDOMAIN-BRUTE"
  echo "#------------------------------------#"

  for i in $(cat $1)
  do
    shuffledns -silent -massdns /opt/massdns -d $i -w ../$dns1 -r ../$res1 -o ${i}.btemp
  done

  cat *.btemp | sort -u > bf.stemp
  rm -rf *.btemp
}

subdomain_scan(){
    echo "#------------------------------------#"
    echo "RUNNING SUBDOMAIN SCAN"
    echo "#------------------------------------#"

    subfinder -silent -dL $1 -timeout 5 -t 100 -nW -nC -o subfinder.stemp &
    shuffledns -silent -massdns /opt/massdns -list $1 -nC -r $res1 -silent -o shuffle.stemp &
    wait
    cat *.stemp | sort -u | sed '/ /d'>> subdomains.txt
    rm -rf *.stemp
}

third_level(){
    echo "#------------------------------------#"
    echo "RUNNING THIRD LEVEL SUBDOMAIN SCAN"
    echo "#------------------------------------#"

    for i in $(cat subdomains.txt)
    do
     shuffledns -silent -massdns /opt/massdns -d $i -r $res1 -o $i.third -w $dns2
    done
  
}

clean_domain(){
    echo "#------------------------------------#"
    echo "CLEANING DOMAIN LIST"
    echo "#------------------------------------#"

    cat *.third subdomains.txt | sort -u > temp.tdtemp
    rm -rf *.third
    if [[ $# -eq 1 ]]
    then
      comm -23 <(sort temp.tdtemp) <(sort $1 ) > temp.txt
      mv temp.txt temp.tdtemp
    fi
    cat temp.tdtemp | sort -u | filter-resolved > subdomains.txt
}

sub_to_ip(){
    echo "#------------------------------------#"
    echo "SUBDOMAIN TO IP"
    echo "#------------------------------------#"

    cat subdomains.txt | while read domain
    do
        dig +short $domain |grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> tempip.txt
    done
    cat tempip.txt | sort -u > ip.txt && rm -rf tempip.txt
}

url_extract(){
    echo "#------------------------------------#"
    echo "URL EXTRACTION ( $1 )"
    echo "#------------------------------------#"

    waybackurls -no-subs $i >> raw_urls.txt
    gau $i >> raw_urls.txt
    cat raw_urls | sort -u | qsreplace -a | gf files | httpx -silent -status-code -title -fc 404 -o httpx.txt
    cat httpx.txt | awk '{print $1}'| sort -u > urls.txt
    touch URL
}

dal_fox(){
    echo "#------------------------------------#"
    echo "XSS SCAN ( $1 )"
    echo "#------------------------------------#"
  
    cat urls.txt | /opt/kxss | awk '{print $NF}' | sed 's/=.*/=/' > kxss.txt
    cat urls.txt | gf xss | dalfox pipe -w 1000 -o ./dalfox.txt 
    touch DALFOX
}

template_scan(){
    echo "#------------------------------------#"
    echo "TEMPLATE SCAN ( $1 )"
    echo "#------------------------------------#"
    
    nuclei -l urls.txt -silent -c 900 -t $templates -o template_scan.txt
    touch TEMPLATE
}

favicon_scan(){
    echo "#------------------------------------#"
    echo "FAVICON SCAN ( $1 )"
    echo "#------------------------------------#"
    
    cat urls.txt | python3 /opt/FavFreak/favfreak.py -o favfreak.txt
    touch FAV
}

dirfuzz(){
    echo "#------------------------------------#"
    echo "DIR FUZZING ( $1 )"
    echo "#------------------------------------#"

    ffuf -u $1/FUZZ -w $fuzzword -t 100 -ac -ic -sa -se -sf -o $1_ffuf.txt 
    touch FUZZ
}

port_scan(){
    echo "#------------------------------------#"
    echo "PORT SCAN "
    echo "#------------------------------------#"
 
    sudo masscan -iL ip.txt -p 1-65535 -oL portscan.txt --rate=1000 -Pn
    cat portscan.txt  | awk '{print $3}' | sort -u | sed '/^$/d' | tr '\n' ',' | sed 's/,$//' > open_ports.txt
}

nmap_scan(){
  echo "#------------------------------------#"
  echo "NMAP SCAN "
  echo "#------------------------------------#"

  mkdir nmap
  sudo nmap -sCV -oA nmap/connect_scan -Pn -p $(cat open_ports.txt) -iL ip.txt
}

s3_scan(){
    echo "#------------------------------------#"
    echo "S3 SCAN ( $1 )"
    echo "#------------------------------------#"

    python3 ../$s3scanner -l subdomains.txt -o buckets.txt 
    touch S3
}

pattern_search(){
    echo "#------------------------------------#"
    echo "PATTERN SEARCH ( $1 )" 
    echo "#------------------------------------#" 

    mkdir pattern
    for i in $(cat $gf)
    do
      cat urls.txt  | gf $i > pattern/${i}.txt
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
    # cat raw_urls.txt | grep -E ".*\.js$" | sort -u > sf.txt
    mkdir sf
    for url in $(cat urls.txt)
    do
      python3 /opt/secretfinder/SecretFinder.py -i $url -o sf/$url.secretfinder.html 
    done
    touch SECRET
}

takeover(){
  echo "#------------------------------------#"
  echo "SUBDOMAIN TAKEOVER ( $1 )" 
  echo "#------------------------------------#" 
  
  subjack -w subdomains.txt -t 500 -o subdomain_takeover.txt -ssl -a
  subzy -https -targets subdomains.txt >> subdomain_takeover.txt
}

cleanup(){
  echo "#------------------------------------#"
  echo "CLEANUP" 
  echo "#------------------------------------#" 

  find . -empty -delete
  mkdir PORT_SCAN SUBDOMAINS INFO
  mv nmap ip.txt open_ports.txt portscan.txt PORT_SCAN
  mv subdomain_takeover.txt SUBDOMAINS
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
    third_level

    if [[ $# -eq 2  ]]
    then
      clean_domain $2
    else
      clean_domain
    fi
   fi

   if [[ ! -f subdomain_takeover.txt ]]
   then
     takeover &
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
  gf -list > /tmp/gf.txt
  sudo mv /tmp/gf.txt /opt
  rm -rf ../Tools/resolvers.txt
  wget https://github.com/janmasarik/resolvers/raw/master/resolvers.txt
  mv resolvers.txt ../Tools
  clear

  if [[ $# -eq 1 ]]
  then
    main $1
  else
    main $1 $2
  fi

fi
