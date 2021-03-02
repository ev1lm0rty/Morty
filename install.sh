#!/bin/bash
#------------------------------#
## Resources
# https://github.com/dwisiswant0/go-dork
# https://github.com/hahwul/WebHackersWeapons
# https://github.com/internetwache/CT_subdomains
# https://github.com/dwisiswant0/awesome-oneliner-bugbounty
# https://github.com/sehno/Bug-bounty/blob/master/bugbounty_checklist.md
#------------------------------#

base_i(){
    mkdir Tools
    cd Tools
    sudo apt update && sudo apt full-upgrade -y
    sudo apt install git vim nano tmux rlwrap \
    jq python3 python3-pip net-tools \
    nmap gawk curl wget fping toilet whatweb masscan chromium-browser gcc make libpcap-dev jq -y
    python3 -m pip install --user virtualenv

    git clone https://github.com/mrjoker05/DotFiles
    cp ~/.tmux.conf ~/.tmux.conf.oldd
    cp ~/.vimrc ~/.vimrc.oldd
    cp DotFiles/tmux.conf ~/.tmux.conf
    cp DotFiles/vimrc ~/.vimrc
    cd ..
}

go_i(){
    wget "https://golang.org/dl/go1.15.5.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf go1.15.5.linux-amd64.tar.gz
    mkdir -p ~/go_projects/{bin,src,pkg}
    export GOPATH="$HOME/go_projects"
    export GOBIN="$GOPATH/bin"
    export PATH=$PATH:/usr/local/go/bin
    echo "export PATH=$PATH:/usr/local/go/bin:$GOBIN" | tee -a ~/.bashrc ~/.zshrc
    echo 'export GOBIN="$GOPATH/bin"' | tee -a ~/.bashrc ~/.zshrc
    echo 'export GOPATH="$HOME/go_projects"' | tee -a ~/.bashrc ~/.zshrc
    rm -rf *.tar.gz
}

gotools_i(){
    GO111MODULE=on go get -u github.com/projectdiscovery/naabu/v2/cmd/naabu
    GO111MODULE=on go get -u github.com/lc/gau
    GO111MODULE=on go get -u github.com/ffuf/ffuf
    GO111MODULE=on go get -u github.com/hahwul/dalfox
    GO111MODULE=on go get -u github.com/projectdiscovery/nuclei/v2/cmd/nuclei
    GO111MODULE=on go get -u github.com/projectdiscovery/subfinder/v2/cmd/subfinder
    GO111MODULE=on go get -u github.com/projectdiscovery/shuffledns/cmd/shuffledns
    GO111MODULE=on go get -u github.com/projectdiscovery/httpx/cmd/httpx
    GO111MODULE=on go get -u github.com/tomnomnom/qsreplace
    GO111MODULE=on go get -u github.com/tomnomnom/waybackurls
    GO111MODULE=on go get -u github.com/tomnomnom/hacks/filter-resolved
    GO111MODULE=on go get -u github.com/haccer/subjack
    GO111MODULE=on go get -u -v github.com/lukasikic/subzy
    GO111MODULE=on go install -v github.com/lukasikic/subzy
    GO111MODULE=on go get -v -u github.com/OWASP/Amass/v3/...
    GO111MODULE=on go get -u github.com/hahwul/s3reverse
}

masscan_i(){
    cd Tools
    git clone https://github.com/robertdavidgraham/masscan
    cd masscan
    make -j
    mv bin/masscan ../m
    cd ..
    rm -rf masscan
    mv m masscan
    cd ..
}

massdns_i(){
    cd Tools
    git clone https://github.com/blechschmidt/massdns
    cd massdns
    make
    mv bin/massdns ../m
    cd ..
    rm -rf massdns
    mv m massdns
    cd ..
}

param_i(){
    cd Tools
    if [[ $# -ne 0 ]]
    then
        rm -rf ParamSpider
    fi

    git clone https://github.com/devanshbatham/ParamSpider
    cd ParamSpider
    pip3 install -r requirements.txt
    cd ../../
}

git_i(){
    cd Tools
    wget "https://github.com/tillson/git-hound/releases/download/v1.3/git-hound_1.3_Linux_x86_64.tar.gz"
    tar -xvf git-hound_1.3_Linux_x86_64.tar.gz
    cd ..
}

fav_i(){
    cd Tools
    if [[ $# -ne 0 ]]
    then
        sudo rm -rf FavFreak
    fi

    git clone https://github.com/devanshbatham/FavFreak
    python3 -m pip install mmh3
    cd ..
}

secret_i(){
    cd Tools
    if [[ $# -ne 0 ]]
    then
        rm -rf secretfinder
    fi

    git clone https://github.com/m4ll0k/SecretFinder.git secretfinder
    cd secretfinder
    python3 -m pip install -r requirements.txt or pip install -r requirements.txt
    cd ../../
}

dirsearch_i(){
    cd Tools
    if [[ $# -ne 0 ]]
    then
        rm -rf dirsearch
    fi

    git clone https://github.com/maurosoria/dirsearch.git
    pip3 install -r dirsearch/requirements.txt
    cd ../../
}

gf_i(){
    cd Tools
    go get -u github.com/tomnomnom/gf
    #echo 'source $GOPATH/src/github.com/tomnomnom/gf/gf-completion.bash' >> ~/.bashrc
    go get -u github.com/tomnomnom/waybackurls
    mkdir ~/.gf
    cp -r $GOPATH/src/github.com/tomnomnom/gf/examples ~/.gf
    git clone https://github.com/1ndianl33t/Gf-Patterns
    mv Gf-Patterns/*.json ~/.gf
    rm -rf Gf-Patterns

    echo "{
        "flags": "-ivE",
        "patterns": [

            ".pdf",
            ".jpg",
            ".gif",
            ".mp3",
            ".mp4",
            ".jpeg",
            ".img",
            ".ttf",
            ".ico",
            ".png",
            ".css"
    ]
    }
    " > ~/.gf/files.txt

    cd ..
}

s3_i(){
    cd Tools
    if [[ $# -ne 0 ]]
    then
         rm -rf S3Scanner
    fi

    git clone https://github.com/sa7mon/S3Scanner
    cd S3Scanner
    pip3 install -r requirements.txt
    cd ..
}

eye_i(){
    cd Tools
    git clone https://github.com/FortyNorthSecurity/EyeWitness
    cd EyeWitness/setup
    sudo bash setup.sh
    cd ../../
}

aqua_i(){

    cd Tools
    if [[ $# -ne 0 ]]
    then
       echo "Manually update aquatone"
    else
        wget "https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip"
        unzip *.zip
        rm -rf *.zip
    fi
    cd ..
}

gob_i(){
    cd Tools
    git clone https://github.com/OJ/gobuster
    cd gobuster
    make
    mv gobuster ../
    cd ..
    rm -rf gobuster
    cd ..
}

wordlist_i(){

    cd Tools
    if [[ ! -d /opt/Payloadallthings ]]
    then
        git clone https://github.com/swisskyrepo/PayloadsAllTheThings
    fi

    if [[ ! -d /opt/SecLists-master ]]
    then
        wget "https://github.com/danielmiessler/SecLists/archive/master.zip"
        unzip master.zip
        rm -rf master.zip

    fi

    rm -rf resolvers.txt
    wget https://github.com/janmasarik/resolvers/raw/master/resolvers.txt
    cd ..
}

tom_i(){
    cd Tools
    git clone https://github.com/tomnomnom/hacks
    cd hacks/kxss
    go build
    mv kxss ../../
    cd ..
}

if [[ $# -ne 0 ]]
then
    echo "UPDATING..."
    base_i
    go_i
    gotools_i
    masscan_i
    amass_i
    massdns_i
    gf_i
    gob_i
    wordlist_i
    tom_i
    #git_i
    #eye_i 
    aqua_i 1
    s3_i 1
    #dirsearch_i 1
    secret_i 1
    fav_i 1
    param_i 1
else
    echo "INSTALLING..."
    base_i
    go_i
    gotools_i
    masscan_i
    amass_i
    massdns_i
    gf_i
    gob_i
    wordlist_i
    tom_i
    #git_i
    #eye_i
    aqua_i 
    s3_i 
    #dirsearch_i 
    secret_i 
    fav_i 
    param_i
fi
