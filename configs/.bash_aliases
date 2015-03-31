alias wure='wfu-update; sudo reboot'
alias wuwu='wfu-update; wfu-update'
alias wusr='wfu-update; sudo wfu-setup -r'
alias rcedit='sudo nano /etc/rc.local'
alias rclog="cat /usr/local/wifindus/rc.local.log"
alias cdtools="cd /usr/local/wifindus/wfu-tools"
alias cdhome="cd /usr/local/wifindus"
alias fakegps="wfu-fake-gps"
alias hbconfig="wfu-heartbeat-config"
alias brinfo="wfu-brain-info"
alias fullinfo="brinfo; hbconfig; fakegps"
alias dumpmesh="sudo iw dev mesh0 mpath dump 2>&1"

for NUMBER in $(seq 1 254); do 
	alias ssh${NUMBER}="echo 'Attempting to auto-ssh into wfu-brain-${NUMBER}...' 1>&2; sshpass -p 'omgwtflol87' ssh -o StrictHostKeyChecking=no wifindus@wfu-brain-${NUMBER}"
done