#!/bin/bash

#-----------------------------------------------#
resolvers=/opt/resolvers.txt
smallwordlist=/opt/SecLists-master/Discovery/DNS/deepmagic.com-prefixes-top500.txt
wordlist=/opt/SecLists-master/Discovery/DNS/subdomains-top1million-20000.txt
fuzzword=/opt/SecLists-master/Discovery/Web-Content/raft-small-words.txt
templatefile=/opt/nuclei.txt
eye=/opt/EyeWitness/Python/EyeWitness.py
date=$(date +%d_%b_%Y)


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
    echo "URL EXTRACTION ( $1 )"
    echo "#------------------------------------#"
    waybackurls -no-subs $i >> raw_urls.txt
    gau $i >> raw_urls.txt
    cat raw_urls.txt | sort | uniq | gf files > urls.txt
    cat urls.txt | httpx -no-color -silent -title -status-code -content-length -fc 404 -o httpx.txt
    touch URL

}

param_discover(){
    echo "#------------------------------------#"
    echo "PARAMETER DISCOVERY ( $1 )"
    echo "#------------------------------------#"
    python3 /opt/ParamSpider/paramspider.py --level high -d $i -o $(pwd)/paramspider.txt
    touch PARAM
}

dal_fox(){
    echo "#------------------------------------#"
    echo "XSS SCAN ( $1 )"
    echo "#------------------------------------#"
    dalfox file urls.txt -o $(pwd)/dalfox.txt -w 1000
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
    cat urls.txt | python3 /opt/FavFreak/favfreak.py -o favfreak.txt 2>/dev/null
    touch FAV
}

dirfuzz(){
    echo "#------------------------------------#"
    echo "DIR FUZZING ( $1 )"
    echo "#------------------------------------#"
    #ffuf -s -u  https://$1/FUZZ -w $fuzzword -o $1_ffuf.txt
    /opt/gobuster dir -u $1 -w $fuzzword -o $1_gobuster.txt -q -t 100 
    touch FUZZ
}

port_scan(){
    echo "#------------------------------------#"
    echo "PORT SCAN "
    echo "#------------------------------------#"
    sudo $naabu -iL ip.txt -p - -nC -o portscan.txt -nmap
}

s3_scan(){
    echo "#------------------------------------#"
    echo "S3 SCAN ( $1 )"
    echo "#------------------------------------#"
    python3 /opt/S3Scanner/s3scanner.py -l subdomains.txt -o buckets.txt
    touch S3
}

pattern_search(){
    echo "#------------------------------------#"
    echo "PATTERN SEARCH ( $1 )" 
    echo "#------------------------------------#" 
    mkdir pattern
    for i in $(cat /opt/gf.txt)
    do
      cat urls.txt paramspider.txt 2>/dev/null | gf $i > pattern/${i}.txt
    done
    touch PATTERN
}

screen_shot(){
    echo "#------------------------------------#"
    echo "SCREENSHOT ( $1 )" 
    echo "#------------------------------------#" 
    python3 $eye -d $1_EYE -f subdomains.txt --no-prompt
    touch SCREEN
}

secret_find(){
    echo "#------------------------------------#"
    echo "SECRETFINDER ( $1 )" 
    echo "#------------------------------------#" 
    cat *.txt | grep .js > js.txt
    python3 /opt/secretfinder/SecretFinder.py -i js.txt -o secretfinder.html
    touch SECRET
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

        if [[ ! -f PARAM ]]
        then
          param_discover $i
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
    rm -rf gecko* SCREEN S3
    cd ..
    zip -r $1.zip Project_$1
}

if [[ $# -ne 1 ]]
then
  echo "Usage ./morty.sh <targetfile>"
else
  if [[ ! -d "Project_$1" ]]
  then
    mkdir "Project_$1"
  fi

  cd "Project_$1" 2> /dev/null
  cp ../$1 . 2> /dev/null

  nuclei -update-templates -silent
  find ~/nuclei-templates -type f -not -path '*/\.*' | grep .yaml > /tmp/nuclei.txt
  sudo cp /tmp/nuclei.txt /opt

  gf -list > /tmp/gf.txt
  sudo mv /tmp/gf.txt /opt

  clear
  main $1
fi
