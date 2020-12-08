#!/bin/bash

#------------------------------#
## Resources

# https://github.com/swisskyrepo/PayloadsAllTheThings
# https://github.com/danielmiessler/SecLists
# https://github.com/projectdiscovery
# https://github.com/hahwul/WebHackersWeapons
# https://github.com/sehno/Bug-bounty/blob/master/bugbounty_checklist.md
# https://github.com/tomnomnom
# https://github.com/internetwache/CT_subdomains
# https://github.com/hahwul/s3reverse
# https://github.com/dwisiswant0/go-dork
# https://github.com/lc/gau

#------------------------------#
## Basic Utils

# Installing base
sudo apt update && sudo apt full-upgrade
sudo apt install git vim nano tmux rlwrap \
    jq python3 python3-pip net-tools \
    nmap gawk curl wget 

# Installing virtualenv
python3 -m pip install --user virtualenv

# Installing go
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

#------------------------------#

## Tools

# ffuf
go get -u github.com/ffuf/ffuf

# masscan
cd /tmp
sudo apt-get install git gcc make libpcap-dev
git clone https://github.com/robertdavidgraham/masscan
cd masscan
make -j
sudo mv bin/masscan /opt

# shuffledns
GO111MODULE=on go get -u -v github.com/projectdiscovery/shuffledns/cmd/shuffledns

# amass
cd /tmp
wget "https://github.com/OWASP/Amass/releases/download/v3.10.5/amass_linux_amd64.zip"
unzip amass*
sudo mv amass* /opt
echo "export PATH=$PATH:/opt/amass_linux_amd64" >> ~/.bashrc
echo "export PATH=$PATH:/opt/amass_linux_amd64" >> ~/.zshrc

# subfinder
GO111MODULE=on go get -u -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder

# massdns
cd /tmp
git clone https://github.com/blechschmidt/massdns
cd massdns
make
sudo cp bin/massdns /opt

# nuclei
GO111MODULE=on go get -u -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei
nuclei -update-templates

# naabu
GO111MODULE=on go get -u -v github.com/projectdiscovery/naabu/v2/cmd/naabu

# waybackurls
go get github.com/tomnomnom/waybackurls

# gao
GO111MODULE=on go get -u -v github.com/lc/gau

# paramspider
git clone https://github.com/devanshbatham/ParamSpider
cd ParamSpider
pip3 install -r requirements.txt
cd /tmp 
sudo mv /tmp/ParamSpider /opt
echo "export PATH=$PATH:/opt/ParamSpider" >> ~/.bashrc
echo "export PATH=$PATH:/opt/ParamSpider" >> ~/.zshrc

# delfox
go get -u github.com/hahwul/dalfox

# githound
cd /tmp
wget "https://github.com/tillson/git-hound/releases/download/v1.3/git-hound_1.3_Linux_x86_64.tar.gz"
tar -xvf git-hound_1.3_Linux_x86_64.tar.gz
cd /tmp

# favfreak
git clone https://github.com/devanshbatham/FavFreak
python3 -m pip install mmh3
sudo mv FavFreak /opt
cd /tmp

# jsscan
# secretfinder
git clone https://github.com/m4ll0k/SecretFinder.git secretfinder
cd secretfinder
python -m pip install -r requirements.txt or pip install -r requirements.txt
cd /tmp
sudo mv /tmp/secretfinder /opt
echo "export PATH=$PATH:/opt/secretfinder" >> ~/.bashrc
echo "export PATH=$PATH:/opt/secretfinder" >> ~/.zshrc


# dirsearch
git clone https://github.com/maurosoria/dirsearch.git
pip3 install -r dirsearch/requirements.txt
sudo mv dirsearch /opt
chmod +x /opt/dirsearch/dirsearch.py
echo "export PATH=$PATH:/opt/dirsearch" >> ~/.bashrc
echo "export PATH=$PATH:/opt/dirsearch" >> ~/.zshrc

# s3reverse
go get -u github.com/hahwul/s3reverse

# httpx
GO111MODULE=on go get -u -v github.com/projectdiscovery/httpx/cmd/httpx

# gf
go get -u github.com/tomnomnom/gf
echo 'source $GOPATH/src/github.com/tomnomnom/gf/gf-completion.bash' >> ~/.bashrc

# gf-patterns
go get -u github.com/tomnomnom/waybackurls
mkdir ~/.gf
cp -r $GOPATH/src/github.com/tomnomnom/gf/examples ~/.gf
git clone https://github.com/1ndianl33t/Gf-Patterns
mv ~/Gf-Patterns/*.json ~/.gf

# whatweb
sudo apt install whatweb

#------------------------------#

## Wordlists and Payloads

# payloadallthings
cd /opt
sudo git clone https://github.com/swisskyrepo/PayloadsAllTheThings

# seclists
cd /opt
#sudo wget "https://github.com/danielmiessler/SecLists/archive/master.zip"
#sudo unzip master.zip
cd /tmp

cd /opt
sudo wget https://github.com/janmasarik/resolvers/raw/master/resolvers.txt
