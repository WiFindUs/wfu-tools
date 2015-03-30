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

for NUMBER in $(seq 1 254); do 
	alias sshwfu${NUMBER}="sshpass -p 'omgwtflol87' ssh -o StrictHostKeyChecking=no wifindus@wfu-brain-${NUMBER}"
done