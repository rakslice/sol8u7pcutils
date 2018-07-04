
CC=gcc

CFLAGS=-G -fpic

all: xinekludge.so

xinekludge.so: xinekludge.c
	$(CC) -o $@ $(CFLAGS) $<


install: /usr/lib/secure/xinekludge.so


/usr/lib/secure/xinekludge.so: xinekludge.so /opt/csw/bin/sudo
	/opt/csw/bin/sudo cp $< $@

user-install: /usr/lib/secure/xinekludge.so
	if fgrep "export LD_PRELOAD=/usr/lib/secure/xinekludge.so" $(HOME)/.dtprofile > /dev/null ; then true; else echo "export LD_PRELOAD=/usr/lib/secure/xinekludge.so" >> $(HOME)/.dtprofile ; fi

