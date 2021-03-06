//===============================================================
// File: wfu-setup.c
// Author: Mark Gillard
// Target environment: Nodes
// Description:
//   Sets the brain unit up according to it's ID number (1-254).
//===============================================================
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdarg.h>
#include <sys/stat.h>

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef NULL
#define NULL 0
#endif

#define VERSION_STR "v1.6" 
#define WFU_HOME "/usr/local/wifindus" 

int quietMode = FALSE;
char sbuf[256], nbuf[256];
char hex[3];

void qprintf(const char * format, ...)
{
	if (quietMode)
		return;
	va_list args;
	va_start (args, format);
	vprintf (format, args);
	va_end (args);
}

int min(int a, int b)
{
	if (a < b)
		return a;
	return b;
}

int dtoh(int decimal, char* hex)
{
	int i = 0, j = 0, remainders[30], length = 0;
	while(decimal > 0)
	{
		remainders[i++] = decimal%16;
		decimal=decimal/16;
		length++;
	}
	
	for(i = length-1; i >= 0; i--)
		hex[j++]= remainders[i] >= 10 ? (char)(((int)'A')+(remainders[i]-10)) : (char)(((int)'0')+remainders[i]);
	hex[length] = '\0';
}

void print_usage(char * argv0)
{
	qprintf("Usage: %s [options] [1-254]\n",argv0);
	qprintf("Options:\n");
	qprintf("  -r:  reboot after completion.\n");
	qprintf("  -hl: print full description only.\n");
	qprintf("  -q:  quiet mode (no text output).\n");
	qprintf("Remarks:\n");
	qprintf("  If the number is omitted, the value stored in %s/.brain-num\n\
will be used (if it exists; otherwise 1 is used as default).\n",WFU_HOME);
}

void print_detailed_help(char * argv0)
{
	qprintf("[WiFindUs Brain Auto-Setup %s]\n\n",VERSION_STR);
	qprintf(
"This program assigns this brain unit with it's unique ID number\n\
(1-254, provided as a parameter), and generates all the associated\n\
scripts needed to set up the mesh network.\n\n"
	);
	
	print_usage(argv0);
	qprintf("\n");
	
	qprintf(
"The following files are automatically generated/overwritten:\n\
    /etc/hosts\n\
    /etc/hostname\n\
    /etc/dhcp/dhcpd.conf\n\
    /etc/network/interfaces\n\
    %s/.brain-num\n\n",
	WFU_HOME
	);
		
	qprintf(
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
	qprintf("Writing %s...",nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		qprintf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"127.0.0.1 localhost\n");
	fprintf(file,"127.0.1.1 wfu-brain-%d wb%d wfu%d\n",num,num,num);
	fprintf(file,"::1 localhost ip6-localhost ip6-loopback\n");
	fprintf(file,"fe00::0 ip6-localnet\n");
	fprintf(file,"ff00::0 ip6-mcastprefix\n");
	fprintf(file,"ff02::1 ip6-allnodes\n");
	fprintf(file,"ff02::2 ip6-allrouters\n");
	fprintf(file,"192.168.1.1 wfu-server m-server\n\n");
	
	for (i = 1; i < 255; i++)
	{
		if (i == num)
			continue;
		fprintf(file,"10.1.0.%d wfu-brain-%d wb%d wfu%d\n",i,i,i,i);
	}
	
	fclose(file);
	qprintf(" [ok]\n");
	return TRUE;
}

int write_hostname(int num)
{
	FILE* file = NULL;

	sprintf(nbuf,"/etc/hostname");
	qprintf("Writing %s...",nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		qprintf("error. are you root?\n");
		return FALSE;
	}
	
	fprintf(file,"wfu-brain-%d\n",num);
	
	fclose(file);
	qprintf(" [ok]\n");
	return TRUE;
}

int write_network_interfaces(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/network/interfaces");
	qprintf("Writing %s...",nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		qprintf("error. are you root?\n");
		return FALSE;
	}

	fprintf(file,"auto lo\n");
	fprintf(file,"iface lo inet loopback\n\n");
	
	fprintf(file,"auto eth0\n");
	fprintf(file,"iface eth0 inet static\n");
	fprintf(file,"        address 192.168.1.%d\n",min(100+num,254));
	fprintf(file,"        netmask 255.255.255.0\n");
	fprintf(file,"        network 192.168.1.0\n");
	fprintf(file,"        broadcast 192.168.1.255\n");
	fprintf(file,"\n");

	fprintf(file,"iface wlan0 inet manual\n");
	fprintf(file,"        post-up iwconfig wlan0 power off\n");
	fprintf(file,"iface wlan1 inet manual\n");
	fprintf(file,"        post-up iwconfig wlan1 power off\n");

	fclose(file);
	qprintf(" [ok]\n");
	
	return TRUE;
}

int write_dhcpd(int num)
{
	FILE* file = NULL;
	
	sprintf(nbuf,"/etc/dhcp/dhcpd.conf");
	qprintf("Writing %s...",nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		qprintf("error. are you root?\n");
		return FALSE;
	}
		
	fprintf(file,"ddns-update-style none;\n");
	fprintf(file,"option domain-name \"wfu-brain-%d.local\";\n",num);
	fprintf(file,"default-lease-time 600;\n");
	fprintf(file,"max-lease-time 7200;\n");
	fprintf(file,"authoritative;\n");
	fprintf(file,"log-facility local7;\n");
	fprintf(file,"subnet 172.16.%d.0 netmask 255.255.255.0 {\n",num);
	fprintf(file,"  range 172.16.%d.2 172.16.%d.254;\n",num,num);
	fprintf(file,"  option routers 172.16.%d.1;\n",num);
	fprintf(file,"  option subnet-mask 255.255.255.0;\n");
	fprintf(file,"  option broadcast-address 172.16.%d.255;\n",num);
	fprintf(file,"  option domain-name-servers 8.8.8.8, 8.8.4.4;\n");
	fprintf(file,"}\n");

	fclose(file);
	qprintf(" [ok]\n");
	
	return TRUE;
}

int write_brain_num(int num)
{
	FILE* file = NULL;

	//num, normal
	sprintf(nbuf,"%s/.brain-num",WFU_HOME);
	qprintf("Writing %s...",nbuf);
	if ((file = fopen(nbuf,"w")) == NULL)
	{
		qprintf("error. are you root?\n");
		return FALSE;
	}
	fprintf(file,"%d\n",num);
	fclose(file);
	sprintf(sbuf,"WFU_BRAIN_NUM=%d; export WFU_BRAIN_NUM", num);
	system(sbuf);
	sprintf(sbuf,"WFU_BRAIN_NUM_HEX=%s; export WFU_BRAIN_NUM_HEX", hex);
	system(sbuf);
	sprintf(sbuf,"WFU_AP_CHANNEL=%d; export WFU_AP_CHANNEL", num % 2 == 0 ? 6 : 11);
	system(sbuf);
	chmod(nbuf, S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);
	qprintf(" [ok]\n");
	
	return TRUE;
}

int read_brain_num()
{
	FILE* file = NULL;
	int val = FALSE;
	
	sprintf(nbuf,"%s/.brain-num",WFU_HOME);
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
	int detailedHelpMode = FALSE;
	//end vars
	
	for (i = 1; i < argc; i++)
	{
		if (strcmp(argv[i],"-r") == 0)
			autoReboot = TRUE;
		else if (strcmp(argv[i],"-hl") == 0)
			detailedHelpMode = TRUE;
		else if (strcmp(argv[i],"-q") == 0)
			quietMode = TRUE;
		else
		{
			numExplicit = TRUE;
			num = atoi(argv[i]);
			if (num < 1 || num > 254)
				num = FALSE;
		}
	}
	
	if (detailedHelpMode)
	{
		print_detailed_help(argv[0]);
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
	
	dtoh(num,hex);

	qprintf("[WiFindUs Brain Auto-Setup %s]\nUnit: wfu-brain-%d (%s)\n",VERSION_STR,num,hex);
	if (numDefault)
	{
		qprintf("  -- Notice --\n\
You did not provide a unit number, and\n\
one has not previously been used on this\n\
system. 1 has been used as default.\n",VERSION_STR,num);
	}
	qprintf("\n");
	
	if (!write_hosts(num))
		return 3;
	if (!write_hostname(num))
		return 4;
	if (!write_dhcpd(num))
		return 7;
	if (!write_network_interfaces(num))
		return 9;
	if (!write_brain_num(num))
		return 11;
	if (autoReboot)
	{
		pid_t proc = fork();
		if (proc == 0)
		{
			sprintf(sbuf,"reboot");
			return system(sbuf);
		}
		else if (proc < 0)
			return 50;
	}
	
	return 0;
}
