#!/bin/bash
#------------------------------#
## Resources
# https://github.com/dwisiswant0/go-dork
# https://github.com/hahwul/WebHackersWeapons
# https://github.com/internetwache/CT_subdomains
# https://github.com/sehno/Bug-bounty/blob/master/bugbounty_checklist.md
#------------------------------#

base_i(){
    sudo apt update && sudo apt full-upgrade -y
    sudo apt install git vim nano tmux rlwrap \
    jq python3 python3-pip net-tools \
    nmap gawk curl wget fping toilet whatweb masscan chromium-browser gcc make libpcap-dev -y
    python3 -m pip install --user virtualenv

    git clone https://github.com/mrjoker05/DotFiles
    cp DotFiles/tmux.conf ~/.tmux.conf
    cp DotFiles/vimrc ~/.vimrc
    sudo mv DotFiles /opt
    rm -rf DotFiles
    
}

go_i(){
    cd /tmp
    wget "https://golang.org/dl/go1.15.5.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf go1.15.5.linux-amd64.tar.gz
    mkdir -p ~/go_projects/{bin,src,pkg}
    export GOPATH="$HOME/go_projects"
    export GOBIN="$GOPATH/bin"
    export PATH=$PATH:/usr/local/go/bin
    echo "export PATH=$PATH:/usr/local/go/bin:$GOBIN" >> ~/.bashrc
    echo 'export GOBIN="$GOPATH/bin"' >> ~/.bashrc
    echo 'export GOPATH="$HOME/go_projects"' >> ~/.bashrc
    rm -rf *.tar.gz
}

gotools_i(){
    GO111MODULE=on go get -u -v github.com/projectdiscovery/naabu/v2/cmd/naabu
    go get github.com/tomnomnom/waybackurls
    GO111MODULE=on go get -u -v github.com/lc/gau
    go get -u github.com/hahwul/dalfox
    go get -u github.com/ffuf/ffuf
    GO111MODULE=on go get -u -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei
    GO111MODULE=on go get -u -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
    GO111MODULE=on go get -u -v github.com/projectdiscovery/shuffledns/cmd/shuffledns
    GO111MODULE=on go get -u -v github.com/projectdiscovery/httpx/cmd/httpx
}

masscan_i(){
    cd /tmp
    git clone https://github.com/robertdavidgraham/masscan
    cd masscan
    make -j
    sudo mv bin/masscan /opt    
}

amass_i(){
    # cd /tmp
    # wget "https://github.com/OWASP/Amass/releases/download/v3.10.5/amass_linux_amd64.zip"
    # unzip amass*
    # sudo mv amass* /opt/amass
    export GO111MODULE=on
    go get -v -u github.com/OWASP/Amass/v3/...
}

massdns_i(){
    cd /tmp
    git clone https://github.com/blechschmidt/massdns
    cd massdns
    make
    sudo cp bin/massdns /opt
}

param_i(){

    if [[ $# -ne 0 ]]
    then
        sudo rm -rf /opt/ParamSpider
    fi

    git clone https://github.com/devanshbatham/ParamSpider
    cd ParamSpider
    pip3 install -r requirements.txt
    cd /tmp 
    sudo mv /tmp/ParamSpider /opt
}

git_i(){
    cd /tmp
    wget "https://github.com/tillson/git-hound/releases/download/v1.3/git-hound_1.3_Linux_x86_64.tar.gz"
    tar -xvf git-hound_1.3_Linux_x86_64.tar.gz
    cd /tmp
}

fav_i(){
    
    if [[ $# -ne 0 ]]
    then
        sudo rm -rf /opt/FavFreak
    fi

    git clone https://github.com/devanshbatham/FavFreak
    python3 -m pip install mmh3
    sudo mv FavFreak /opt
    cd /tmp
}

secret_i(){
    if [[ $# -ne 0 ]]
    then
        sudo rm -rf /opt/secretfinder
    fi

    git clone https://github.com/m4ll0k/SecretFinder.git secretfinder
    cd secretfinder
    python3 -m pip install -r requirements.txt or pip install -r requirements.txt
    cd /tmp
    sudo mv /tmp/secretfinder /opt
}

dirsearch_i(){
    if [[ $# -ne 0 ]]
    then
        sudo rm -rf /opt/dirsearch
    fi

    git clone https://github.com/maurosoria/dirsearch.git
    pip3 install -r dirsearch/requirements.txt
    sudo mv dirsearch /opt
    chmod +x /opt/dirsearch/dirsearch.py
}

gf_i(){
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
}

s3_i(){
    if [[ $# -ne 0 ]]
    then
        sudo rm -rf /opt/S3Scanner
    fi

    cd /tmp
    git clone https://github.com/sa7mon/S3Scanner
    cd S3Scanner
    pip3 install -r requirements.txt
    cd ..
    sudo mv S3Scanner /opt
    go get -u github.com/hahwul/s3reverse
}

eye_i(){
    git clone https://github.com/FortyNorthSecurity/EyeWitness
    sudo mv EyeWitness /opt
    cd /opt/EyeWitness/setup
    sudo bash setup.sh
}

aqua_i(){

    if [[ $# -ne 0 ]]
    then
       echo "Manually update aquatone"
    else
        cd /tmp
        wget "https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip"
        unzip *.zip
        rm -rf *.zip
        sudo mv aquatone /opt
    fi
}

gob_i(){
    cd /tmp
    git clone https://github.com/OJ/gobuster
    cd gobuster
    make
    sudo mv gobuster /opt
    cd ..
    rm -rf gobuster
}

wordlist_i(){


    if [[ ! -d /opt/Payloadallthings ]]
    then
        cd /opt
        sudo git clone https://github.com/swisskyrepo/PayloadsAllTheThings
    fi

    if [[ ! -d /opt/SecLists-master ]]
    then
        cd /opt
        sudo wget "https://github.com/danielmiessler/SecLists/archive/master.zip"
        sudo unzip master.zip
        sudo rm -rf master.zip

    fi
    
    cd /opt
    sudo rm -rf resolvers.txt
    sudo wget https://github.com/janmasarik/resolvers/raw/master/resolvers.txt

}

tom_i(){
    cd /tmp
    git clone https://github.com/tomnomnom/hacks
    cd ./hacks/kxss
    go build
    sudo mv kxss /opt
    cd /tmp 
    sudo mv hacks /opt
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
