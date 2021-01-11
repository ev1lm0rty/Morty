# About
* This is my personal recon script that I use to find P4-P5 bugs.
* This script is meant to be run on a VPS rather than a personal computer.


# Usage
* `./install.sh` to fresh install the tools.
* `./install.sh u` to update the installed tools.
* `./morty.sh <targetfile>` to run the script on the scope defined in target file.
* `./morty.sh <targetfile> <outofscopefile>` to exclude subdomains in the _outofscope_ file


# Scope file
* Should contain domain names in a list (without any regex) to enumerate on.
* Same goes for out of scope file


# Recon
0. Brute force subdomain scan
1. Subdomain enumeration from passive sources
2. Third leve subdomain scan
3. Subdomain to IP conversion
4. Nmap vuln scan on open ports
5. Nmap connect scan on open ports
6. Aquatone to capture screenshots of active hosts
7. Httpx to find active urls
8. Waybackurls, gau to find archived links
9. Favicon scan
10. Template scan 
11. Automated xss finder (kxss + dalfox)
12. Pattern Search (gf)
13. Secret finder
14. S3 bucket scan
15. Directory fuzzing
16. Cors misconfig
17. Subdomain takeover


# To be added
* Shodan api
* Censys api
* Vhost enum