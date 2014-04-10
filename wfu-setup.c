#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef NULL
#define NULL 0
#endif
#ifndef VERSION_STR
#define VERSION_STR "v1.0" 
#endif

int min(int a, int b)
{
	if (a < b)
		return a;
	return b;
}

void print_usage(char * argv0)
{
	fprintf(stderr, "Usage: %s [options] [1-254]\n",argv0);
	fprintf(stderr, "Options:\n");
	fprintf(stderr, "  -r or --reboot: auto reboot after completion.\n");
	fprintf(stderr, "  -s or --shutdown: auto halt after completion.\n");
	fprintf(stderr, "  -w or --wallpaper: do not automatically change wallpaper.\n");
	fprintf(stderr, "  -h or --help: print full description only.\n");
	fprintf(stderr, "Remarks:\n");
	fprintf(stderr, "  If the number is omitted the value stored in /home/pi/src/wfu-brain-num\
will be used (if it exists).\n");
}

void print_detailed_help()
{
	printf("[WiFindUs Brain Auto-Setup %s]\n\n",VERSION_STR);
	printf(
"This program assigns this brain unit with it's unique ID number\n\
(1-254, provided as a parameter), and generates all the associated\n\
scripts needed to set up the mesh network.\n\n"
	);

	printf(
"The following files are automatically generated/overwritten:\n\
    /etc/hosts\n\
    /etc/hostname\n\
    /etc/rc.local\n\
    /etc/hostapd/hostapd.conf\n\
    /etc/udhcpd.conf\n\
    /etc/wpa_supplicant/wpa_supplicant.conf\n\
    /etc/network/interfaces\n\
    /usr/local/etc/serval/serval.conf\n\
    /home/pi/src/wfu-brain-num\n\n\
If you wish to make changes to these files yourself, either back them\n\
up and re-apply them after running the program, or change the program\n\
in /home.pi/projects/wfu-setup/wfu-setup.c.\n\n"
	);
		
	printf(
"The changes made within won't fully take effect until the Pi is\n\
rebooted; run the program with the -r switch to automatically reboot\n\
it upon completion.\n\n"
	);
}

int write_hosts(int num)
{
	FILE* file = NULL;
	int i;
	
	printf("Writing /etc/hosts...");
	file = fopen("/etc/hosts","w");
	if (file == NULL)
	{
		printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"127.0.0.1 localhost\n");
	fprintf(file,"::1 localhost ip6-localhost ip6-loopback\n");
	fprintf(file,"fe00::0 ip6-localnet\n");
	fprintf(file,"ff00::0 ip6-mcastprefix\n");
	fprintf(file,"ff02::1 ip6-allnodes\n");
	fprintf(file,"ff02::2 ip6-allrouters\n\n");
	
	fprintf(file,"192.168.1.2 m-beast\n");
	fprintf(file,"192.168.1.1 m-server\n\n");
	
	
	fprintf(file,"192.168.2.255 brains-broadcast\n");
	fprintf(file,"192.168.0.255 clients-broadcast\n\n");
	
	for (i = 1; i < 255; i++)
	{
		if (i == num)
			fprintf(file,"127.0.1.1 wfu-brain-%d\n",i);
		else
			fprintf(file,"192.168.2.%d wfu-brain-%d\n",i,i);
	}
	
	
	fclose(file);
	printf(" [ok]\n");
	return TRUE;
}

int write_hostname(int num)
{
	FILE* file = NULL;

	printf("Writing /etc/hostname...");
	file = fopen("/etc/hostname","w");
	if (file == NULL)
	{
		printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"wfu-brain-%d\n",num);
	
	fclose(file);
	printf(" [ok]\n");
	return TRUE;
}

int write_rc_local(int num)
{
	FILE* file = NULL;
	
	printf("Writing /etc/rc.local...");
	file = fopen("/etc/rc.local","w");
	if (file == NULL)
	{
		printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"#!/bin/sh -e\n");
	fprintf(file,"sleep 5\n");

	fprintf(file,"echo \"[WFU Mesh Setup] - creating node...\"\n");
	fprintf(file,"sudo ifconfig wlan0 down\n");
	//fprintf(file,"sudo iwconfig wlan0 mode managed\n");
	fprintf(file,"sudo iwconfig wlan0 mode Ad-Hoc channel 1 rts 250 frag 256\n");
	fprintf(file,"sudo iwconfig wlan0 essid wifindus_mesh\n");
	fprintf(file,"sudo iwconfig wlan0 key off\n");
	//fprintf(file,"sudo iwconfig wlan0 key s:PWbDq39QQ8632\n");
	//fprintf(file,"sudo iwconfig wlan0 ap 02:11:87:AF:99:FF\n");
	//fprintf(file,"sudo ifconfig wlan0 up\n");
	fprintf(file,"sudo ifconfig wlan0 192.168.2.%d/24 up\n",num);
	
	fprintf(file,"sleep 1\n");
	fprintf(file,"sudo babeld wlan0\n");

	fprintf(file,"exit 0\n");
	
	fclose(file);
	printf(" [ok]\n");
	
	return TRUE;
}

int write_hostapd(int num)
{
	FILE* file = NULL;
	
	printf("Writing /etc/hostapd/hostapd.conf...");
	file = fopen("/etc/hostapd/hostapd.conf","w");
	if (file == NULL)
	{
		printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"interface=wlan1\n");
	fprintf(file,"driver=rtl871xdrv\n");
	fprintf(file,"ssid=wifindus_public\n");
	fprintf(file,"hw_mode=g\n");
	fprintf(file,"channel=6\n");
	fprintf(file,"macaddr_acl=0\n");
	fprintf(file,"auth_algs=3\n");
	fprintf(file,"ignore_broadcast_ssid=0\n");
	fprintf(file,"wpa=3\n");
	fprintf(file,"wpa_passphrase=a8jFIVcag82H461\n");
	fprintf(file,"wpa_key_mgmt=WPA-PSK\n");
	fprintf(file,"wpa_pairwise=TKIP\n");
	fprintf(file,"rsn_pairwise=CCMP\n");
	fprintf(file,"ieee80211n=1\n");
	fprintf(file,"ieee80211d=1\n");
	fprintf(file,"ieee80211h=1\n");
	fprintf(file,"country_code=AU\n");
	fprintf(file,"wmm_enabled=1\n");
	
	fclose(file);
	printf(" [ok]\n");
	
	return TRUE;
}

int write_supplicant(int num)
{
	FILE* file = NULL;
	
	printf("Writing /etc/wpa_supplicant/wpa_supplicant.conf...");
	file = fopen("/etc/wpa_supplicant/wpa_supplicant.conf","w");
	if (file == NULL)
	{
		printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n");
	fprintf(file,"update_config=1\n\n");
	
	fclose(file);
	printf(" [ok]\n");
	
	return TRUE;
}

int write_network_interfaces(int num)
{
	FILE* file = NULL;
	
	printf("Writing /etc/network/interfaces...");
	file = fopen("/etc/network/interfaces","w");
	if (file == NULL)
	{
		printf("error. are you root?\n");
		return FALSE;
	}

	fprintf(file,"auto lo\n");
	fprintf(file,"iface lo inet loopback\n\n");
	
	fprintf(file,"iface eth0 inet static\n");
	fprintf(file,"        address 192.168.1.%d\n",min(100+num,254));
	fprintf(file,"        netmask 255.255.255.0\n");
	fprintf(file,"        gateway 192.168.1.254\n\n");

	/* //shouldn't need this since/etc/rc.local explicitly enables wlan0
	fprintf(file,"auto wlan0\n");
	fprintf(file,"iface wlan0 inet static\n");
	fprintf(file,"        address 192.168.2.%d\n",num);
	fprintf(file,"        netmask 255.255.255.0\n");
	*/
	
	/* //wlan1 is currently AWOL
	fprintf(file,"auto wlan1\n");
	fprintf(file,"iface wlan1 inet static\n");
	fprintf(file,"        address 192.168.0.1\n");
	fprintf(file,"        netmask 255.255.255.0\n\n");
	*/
	fprintf(file,"iface default inet dhcp\n");

	fclose(file);
	printf(" [ok]\n");
	
	return TRUE;
}

int write_udhcpd(int num)
{
	FILE* file = NULL;
	
	printf("Writing /etc/udhcpd.conf...");
	file = fopen("/etc/udhcpd.conf","w");
	if (file == NULL)
	{
		printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"start      192.168.0.2\n");
	fprintf(file,"end        192.168.0.254\n");
	fprintf(file,"interface  wlan1\n");
	fprintf(file,"remaining  yes\n");
	fprintf(file,"opt lease 86400\n");
	fprintf(file,"opt subnet 255.255.255.0\n");
	fprintf(file,"opt router 192.168.0.1\n");

	fclose(file);
	printf(" [ok]\n");
	
	return TRUE;
}

int write_servald(int num)
{
	FILE* file = NULL;
	
	printf("Writing /usr/local/etc/serval/serval.conf...");
	file = fopen("/usr/local/etc/serval/serval.conf","w");
	if (file == NULL)
	{
		printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"interfaces.0.match=wlan0\n");
	fprintf(file,"interfaces.0.type=wifi\n");
	
	fclose(file);
	printf(" [ok]\n");
	
	return TRUE;
}

int write_brain_num(int num)
{
	FILE* file = NULL;
	
	printf("Writing /home/pi/src/wfu-brain-num...");
	file = fopen("/home/pi/src/wfu-brain-num","w");
	if (file == NULL)
	{
		printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"%d\n",num);
	
	fclose(file);
	printf(" [ok]\n");
	
	return TRUE;
}

int read_brain_num()
{
	FILE* file = NULL;
	int val = FALSE;
	
	file = fopen("/home/pi/src/wfu-brain-num","r");
	if (file == NULL)
		return FALSE;
	fscanf(file, "%d", &val);
	fclose(file);
	if (val < 1 || val > 254)
		return FALSE;
	return val;	
}

int main(int argc, char **argv)
{
	//vars
	int i = 0;
	int num = FALSE;
	int autoReboot = FALSE;
	int autoHalt = FALSE;
	int detailedHelpMode = FALSE;
	int autoWallpaper = TRUE;
	char sbuf[256], nbuf[256];
	
	//end vars

	for (i = 1; i < argc; i++)
	{
		if (strcmp(argv[i],"-r") == 0 || strcmp(argv[i],"--reboot") == 0)
			autoReboot = TRUE;
		else if (strcmp(argv[i],"-s") == 0 || strcmp(argv[i],"--shutdown") == 0)
			autoHalt = TRUE;
		else if (strcmp(argv[i],"-h") == 0 || strcmp(argv[i],"--help") == 0)
			detailedHelpMode = TRUE;
		else if (strcmp(argv[i],"-w") == 0 || strcmp(argv[i],"--wallpaper") == 0)
			autoWallpaper = FALSE;
		else
		{
			num = atoi(argv[i]);
			if (num < 1 || num > 254)
				num = FALSE;
		}
	}
	
	if (detailedHelpMode)
	{
		print_detailed_help();
		return 0;
	}
	
	if (num == FALSE)
		num = read_brain_num();
	if (num == FALSE)
	{
		print_usage(argv[0]);
		return 2;
	}
	printf("[WiFindUs Brain Auto-Setup %s]\nUnit: wfu-brain-%d\n\n",VERSION_STR,num);
	
	if (!write_hosts(num))
		return 3;
	if (!write_hostname(num))
		return 4;
	if (!write_rc_local(num))
		return 5;
	if (!write_hostapd(num))
		return 6;
	if (!write_udhcpd(num))
		return 7;
	if (!write_supplicant(num))
		return 8;
	if (!write_network_interfaces(num))
		return 9;
	if (!write_servald(num))
		return 10;
	if (!write_brain_num(num))
		return 11;
	if (autoWallpaper)
	{
		sprintf(nbuf,"/home/pi/wfu-setup-images/wfu-brain-%d.png",num);
		
		if (access(nbuf, F_OK) == 0)
		{
			sprintf(sbuf,"sudo -u pi pcmanfm --set-wallpaper %s > /dev/null",nbuf);
			
			pid_t proc = fork();
			if (proc == 0)
				return system(sbuf);
			else if (proc < 0)
				return 40;
		}
	}
	if (autoReboot || autoHalt)
	{
		pid_t proc = fork();
		if (proc == 0)
		{
			if (autoHalt)
				sprintf(sbuf,"shutdown -h now");
			else
				sprintf(sbuf,"shutdown -r now");
			return system(sbuf);
		}
		else if (proc < 0)
			return 50;
	}
	
	return 0;
}
