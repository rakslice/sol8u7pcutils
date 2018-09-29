
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


wtcmmi https://www.cabextract.org.uk/cabextract-1.7.tar.gz 30ca948d4204f51cb4b51fae282d867ec6697161 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/tgcware/lib -L/usr/local/lib /usr/tgcware/lib/libintl.so" CPPFLAGS=-I/usr/local/include

mkdir -p ~/src/msttfonts
pushd ~/src/msttfonts

function fetch_font() {
	msfont="$1"
	sha="$2"
	[ "$msfont" != "" ]
	[ "$sha" != "" ]
	output_filename="${msfont}.exe" \
	download_and_sha "http://sourceforge.net/projects/corefonts/files/the%20fonts/final/${msfont}.exe/download" "$sha"
}

fetch_font andale32 c4db8cbe42c566d12468f5fdad38c43721844c69
fetch_font arial32 6d75f8436f39ab2da5c31ce651b7443b4ad2916e
fetch_font arialb32 d45cdab84b7f4c1efd6d1b369f50ed0390e3d344
fetch_font comic32 2371d0327683dcc5ec1684fe7c275a8de1ef9a51
fetch_font courie32 06a745023c034f88b4135f5e294fece1a3c1b057
fetch_font georgi32 90e4070cb356f1d811acb943080bf97e419a8f1e
fetch_font impact32 86b34d650cfbbe5d3512d49d2545f7509a55aad2
fetch_font times32 20b79e65cdef4e2d7195f84da202499e3aa83060
fetch_font trebuc32 50aab0988423efcc9cf21fac7d64d534d6d0a34a
fetch_font verdan32 f5b93cedf500edc67502f116578123618c64a42a
fetch_font webdin32 2fb4a42c53e50bc70707a7b3c57baf62ba58398f

for msfont in andale32 arial32 arialb32 comic32 courie32 georgi32 impact32 times32 trebuc32 verdan32 webdin32
do
mkdir -p $msfont
cabextract $msfont.exe -d $msfont
cd $msfont
for f in *.[tT][tT][fF]; do 
	new_name="${f:0:-3}ttf"
	if [ "$f" != "$new_name" ]; then
		mv "$f" "$new_name"
	fi
done
ls -l
sudo ginstall -v -d -m755 /usr/share/fonts/$msfont
sudo ginstall -v -m644 *.ttf /usr/share/fonts/$msfont
sudo fc-cache -v /usr/share/fonts/$msfont
cd ..
rm -rf $msfont
done

popd

