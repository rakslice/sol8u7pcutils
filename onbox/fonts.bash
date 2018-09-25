
mkdir -p ~/src/dejavu-fonts-ttf-2.37/ttf

cat > ~/src/dejavu-fonts-ttf-2.37/Makefile <<\EOF
all:

install:
	$(MAKE) -C ttf install

uninstall:
	$(MAKE) -C ttf uninstall
EOF

cat > ~/src/dejavu-fonts-ttf-2.37/ttf/Makefile <<\EOF
install:
	ginstall -v -d -m755 /usr/share/fonts/dejavu
	ls *.ttf
	ginstall -v -m644 *.ttf /usr/share/fonts/dejavu
	fc-cache -v /usr/share/fonts/dejavu

uninstall:
	rm -rf /usr/share/fonts/dejavu
	fc-cache -r -v
EOF

noconfig=1 \
wtcmmi https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2 7fa15e7b9676fc3915338c41e76ad454c344fff5
