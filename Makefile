default: wfu-setup

wfu-setup.o: wfu-setup.c
	gcc -c wfu-setup.c -o wfu-setup.o

wfu-setup: wfu-setup.o
	gcc wfu-setup.o -o wfu-setup

clean:
	-rm -f wfu-setup.o
	-rm -f wfu-setup