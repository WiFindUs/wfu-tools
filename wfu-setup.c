//===============================================================
// File: wfu-setup.c
// Author: Mark Gillard
// Target environment: Raspbian
// Description:
//   Sets the PI unit up according to it's ID number (1-254).
//===============================================================
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
#define VERSION_STR "v1.2" 
#endif
#ifndef SRC_DIR
#define SRC_DIR "/home/pi/src" 
#endif

int quietMode = FALSE;
int uninstallMode = FALSE;
char sbuf[256], nbuf[256], opString[50];

int min(int a, int b)
{
	if (a < b)
		return a;
	return b;
}

void print_usage(char * argv0)
{
	if (quietMode)
		return;
	
	fprintf(stderr, "Usage: %s [options] [1-254]\n",argv0);
	fprintf(stderr, "Options:\n");
	fprintf(stderr, "  -r or --reboot: auto reboot after completion.\n");
	fprintf(stderr, "  -s or --shutdown: auto halt after completion.\n");
	fprintf(stderr, "  -h or --help: print full description only.\n");
	fprintf(stderr, "  -q or --quiet: quiet mode (no text output).\n");
	fprintf(stderr, "  -u or --uninstall: reverts scripts to pre-wfu defaults,\n\
instead of writing them out to disk.\n");
	fprintf(stderr, "Remarks:\n");
	fprintf(stderr, "  If the number is omitted, the value stored in %s/wfu-brain-num\n\
will be used (if it exists; otherwise 1 is used as default).\n",SRC_DIR);
}

void print_detailed_help()
{
	if (quietMode)
		return;

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
	/etc/default/udhcpd\n\
    /etc/network/interfaces\n\
    /usr/local/etc/serval/serval.conf\n\
    %s/wfu-brain-num\n\n",
	SRC_DIR
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
	
	sprintf(nbuf,"/etc/hosts");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"127.0.0.1 localhost\n");
	fprintf(file,"::1 localhost ip6-localhost ip6-loopback\n");
	fprintf(file,"fe00::0 ip6-localnet\n");
	fprintf(file,"ff00::0 ip6-mcastprefix\n");
	fprintf(file,"ff02::1 ip6-allnodes\n");
	fprintf(file,"ff02::2 ip6-allrouters\n\n");
	
	if (!uninstallMode)
	{
		fprintf(file,"192.168.1.2 m-beast\n");
		fprintf(file,"192.168.1.1 m-server\n\n");
		fprintf(file,"192.168.2.254 m-beast-mesh\n\n");
		
		fprintf(file,"192.168.2.255 brains-broadcast\n");
		fprintf(file,"192.168.0.255 clients-broadcast\n\n");
		
		for (i = 1; i < 255; i++)
		{
			if (i == num)
				fprintf(file,"127.0.1.1 wfu-brain-%d\n",i);
			else
				fprintf(file,"192.168.2.%d wfu-brain-%d\n",i,i);
		}
	}
	else
		fprintf(file,"127.0.1.1 wfu-brain-%d\n",num);
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	return TRUE;
}

int write_hostname(int num)
{
	FILE* file = NULL;

	sprintf(nbuf,"/etc/hostname");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"wfu-brain-%d\n",num);
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	return TRUE;
}

int write_rc_local(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/rc.local");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"#!/bin/sh -e\n");

	if (!uninstallMode)
	{
		fprintf(file,"echo \"[WFU Mesh Setup] - creating node...\"\n");
		
		fprintf(file,"sudo ifconfig wlan0 down\n");
		fprintf(file,"sudo iw dev wlan0 del\n");
		fprintf(file,"sudo iw reg set AU\n");
		fprintf(file,"sudo iw phy phy0 interface add mesh0 type mp mesh_id wifindus_mesh\n");
		//fprintf(file,"sudo ip link set dev mesh0 address 50:50:50:50:50:50\n");
		fprintf(file,"sudo iw phy phy0 interface add ap0 type managed\n");
		fprintf(file,"sudo ip link set dev ap0 address 60:60:60:60:60:60\n");
		fprintf(file,"sudo ifconfig mesh0 192.168.2.%d up\n",num);	
		fprintf(file,"sudo ifconfig ap0 up\n");	
		
		fprintf(file,"echo \"[WFU Mesh Setup] - launching daemons...\"\n");
		fprintf(file,"sleep 3\n");
		fprintf(file,"sudo servald start\n");
		fprintf(file,"sudo gpsd /dev/ttyACM0 -F /var/run/gpsd.sock\n");
		fprintf(file,"sudo hostapd -B /etc/hostapd/hostapd.conf\n");
		fprintf(file,"sudo service udhcpd start\n");
	}

	fprintf(file,"exit 0\n");
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_hostapd(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/hostapd/hostapd.conf");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((uninstallMode && remove(nbuf) != 0) || (!uninstallMode && (file = fopen(nbuf,"w")) == NULL))
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	if (uninstallMode)
		return TRUE;
	
	fprintf(file,"interface=ap0\n");
	fprintf(file,"country_code=AU\n");
	fprintf(file,"driver=nl80211\n"); //old: rtl871xdrv
	fprintf(file,"ssid=wifindus_public\n");
	fprintf(file,"hw_mode=g\n");
	fprintf(file,"ieee80211n=1\n");
	fprintf(file,"channel=1\n");
	fprintf(file,"macaddr_acl=0\n");
	fprintf(file,"auth_algs=3\n");
	fprintf(file,"wpa=3\n");
	fprintf(file,"wpa_passphrase=a8jFIVcag82H461\n");
	fprintf(file,"wpa_key_mgmt=WPA-PSK\n");
	fprintf(file,"wpa_pairwise=TKIP\n");
	fprintf(file,"rsn_pairwise=CCMP\n");
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_network_interfaces(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/network/interfaces");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}

	fprintf(file,"auto lo\n");
	fprintf(file,"iface lo inet loopback\n\n");
	
	fprintf(file,"iface eth0 inet static\n");
	fprintf(file,"        address 192.168.1.%d\n",min(100+num,254));
	fprintf(file,"        netmask 255.255.255.0\n");
	fprintf(file,"        gateway 192.168.1.254\n\n");

	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_udhcpd(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/udhcpd.conf");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((uninstallMode && remove(nbuf) != 0) || (!uninstallMode && (file = fopen(nbuf,"w")) == NULL))
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	if (uninstallMode)
		return TRUE;
	
	fprintf(file,"start      192.168.0.2\n");
	fprintf(file,"end        192.168.0.254\n");
	fprintf(file,"interface  ap0\n");
	fprintf(file,"remaining  yes\n");
	fprintf(file,"opt lease 86400\n");
	fprintf(file,"opt subnet 255.255.255.0\n");
	fprintf(file,"opt router 192.168.0.1\n");

	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_udhcpd_default(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/default/udhcpd");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	
	if (uninstallMode)
		fprintf(file,"DHCPD_ENABLED=\"no\"\n");
	fprintf(file,"DHCPD_OPTS=\"-S\"\n");

	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_servald(int num)
{
	FILE* file = NULL;

	sprintf(nbuf,"/usr/local/etc/serval/serval.conf");
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	
	if ((uninstallMode && remove(nbuf) != 0) || (!uninstallMode && (file = fopen(nbuf,"w")) == NULL))
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	if (uninstallMode)
		return TRUE;
	
	fprintf(file,"interfaces.0.match=mesh*,ap*\n");
	fprintf(file,"interfaces.0.type=wifi\n");
	fprintf(file,"server.respawn_on_crash=true\n");
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int write_brain_num(int num)
{
	FILE* file = NULL;

	sprintf(nbuf,"%s/wfu-brain-num",SRC_DIR);
	if (!quietMode)
		printf("%s %s...",opString,nbuf);
	
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		if (!quietMode)
			printf("error. are you root?\n");
		return FALSE;
	}
	fprintf(file,"%d\n",num);
	
	fclose(file);
	if (!quietMode)
		printf(" [ok]\n");
	
	return TRUE;
}

int read_brain_num()
{
	FILE* file = NULL;
	int val = FALSE;
	
	sprintf(nbuf,"%s/wfu-brain-num",SRC_DIR);
	if ((file = fopen(nbuf,"r")) == NULL)
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
	int numDefault = FALSE;
	int numExplicit = FALSE;
	int autoReboot = FALSE;
	int autoHalt = FALSE;
	int detailedHelpMode = FALSE;
	//end vars
	
	for (i = 1; i < argc; i++)
	{
		if (strcmp(argv[i],"-r") == 0 || strcmp(argv[i],"--reboot") == 0)
			autoReboot = TRUE;
		else if (strcmp(argv[i],"-s") == 0 || strcmp(argv[i],"--shutdown") == 0)
			autoHalt = TRUE;
		else if (strcmp(argv[i],"-h") == 0 || strcmp(argv[i],"--help") == 0)
			detailedHelpMode = TRUE;
		else if (strcmp(argv[i],"-q") == 0 || strcmp(argv[i],"--quiet") == 0)
			quietMode = TRUE;
		else if (strcmp(argv[i],"-u") == 0 || strcmp(argv[i],"--uninstall") == 0)
			uninstallMode = TRUE;
		else
		{
			numExplicit = TRUE;
			num = atoi(argv[i]);
			if (num < 1 || num > 254)
				num = FALSE;
		}
	}
	
	strcpy(opString,uninstallMode ? "Reverting" : "Writing");
	
	if (detailedHelpMode)
	{
		print_detailed_help();
		return 0;
	}
	
	if (!num)
		num = read_brain_num();
	if (!num && !numExplicit)
	{
		num = 1;
		numDefault = TRUE;
	}
	if (!num)
	{
		print_usage(argv[0]);
		return 2;
	}
	if (!quietMode)
	{
		printf("[WiFindUs Brain Auto-Setup %s]\nUnit: wfu-brain-%d\n",VERSION_STR,num);
		if (uninstallMode)
			printf("## UNINSTALL MODE ##\n");
		if (numDefault)
		{
			printf("  -- Notice --\n\
You did not provide a unit number, and\n\
one has not previously been used on this\n\
system. 1 has been used as default.\n",VERSION_STR,num);
		}
		printf("\n");
	}
	
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
	if (!write_udhcpd_default(num))
		return 8;
	if (!write_network_interfaces(num))
		return 9;
	if (!write_servald(num))
		return 10;
	if (!write_brain_num(num))
		return 11;
	if (autoReboot || autoHalt)
	{
		pid_t proc = fork();
		if (proc == 0)
		{
			sprintf(sbuf,"shutdown -%s now > /dev/null", autoHalt ? "h" : "r");
			return system(sbuf);
		}
		else if (proc < 0)
			return 50;
	}
	
	return 0;
}
