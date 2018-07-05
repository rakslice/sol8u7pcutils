#!/opt/csw/bin/bash

set -e
set -o pipefail

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

patches_dir="${script_path}/patches"

cd ~/src

if [ ! -d logs ]; then
	mkdir logs
fi

function die() {
	echo "$1" 1>&2
	exit 1
}

function installed() {
	dirname="$1"
	build_tag="installed-${dirname}"
	if [ ! -f "$build_tag" ]; then
		return 1
	fi
}	

function download_and_sha() {
	if [ "$#" -ne 2 ]; then 
		die "bad params to download_and_sha: $*"
	fi
	url="$1"
	sha_expected="$2"
	archive=$(basename "$url")
	if [ ! -f "$archive" ]; then
		wget "$url"
	fi	
	sha_actual=$(shasum "$archive" | awk '{print $1}')
	[ "$sha_actual" == "$sha_expected" ]
}

function wtcmmi() {
	# a function to build a thing
	# wget - tar - configure - make - make install
	if [ "$#" -lt 2 ]; then 
		die "bad params to wtcmmi: $*"
	fi

	set -x

	url="$1"
	sha_expected="$2"
	shift 2

	archive=$(basename "$url")
	dirname="${archive%.tar.gz}"
	build_tag="installed-${dirname}"
	if [ -f "$build_tag" ]; then
		return
	fi

	if [ ! -f "$archive" ]; then
		wget "$url"
	fi
	sha_actual=$(shasum "$archive" | awk '{print $1}')
	[ "$sha_actual" == "$sha_expected" ]

	gtar xf "$archive"

	pushd "$dirname"

	# configure
	if [ "$noconfig" == "" ]; then	
		./configure "$@" 2>&1 | tee ~/src/logs/${dirname}.configure.out
		if [ -f config.log ]; then
			cp config.log ~/src/logs/${dirname}.config.log
		fi
	fi

	# apply a patch if there is one to apply post-config so it can change makefiles
	if [ -f "${patches_dir}/${dirname}.patch" ]; then
		# for easy patch creation make a .orig copy of the directory if we don't already have one
		if [ ! -d ../${dirname}.orig ]; then
			cp -R ../${dirname} ../${dirname}.orig
		fi

		gpatch -p1 -i "${patches_dir}/${dirname}.patch" 2>&1 | tee ~/src/logs/${dirname}.patch.out
	fi

	if [ "$make_subdir" != "" ]; then
		cd "$make_subdir"
	fi

	gmake ${make_params} 2>&1 | tee ~/src/logs/${dirname}.make.out

	sudo gmake install ${make_install_params} 2>&1 | tee ~/src/logs/${dirname}.make_install.out

	popd	
	
	touch "$build_tag"
}


if false; then

wtcmmi "http://0pointer.de/lennart/projects/libdaemon/libdaemon-0.14.tar.gz" 78a4db58cf3a7a8906c35592434e37680ca83b8f

# needs better libintl / gettext
pkg install ggettext
# gettext utilites have alternate names
for tool in xgettext msgfmt; do
	if [ ! -f /opt/csw/bin/$tool ]; then
		sudo ln -s /opt/csw/bin/g${tool} /opt/csw/bin/${tool}
	fi
done


#make_params="V=1" \
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
wtcmmi "http://avahi.org/download/avahi-0.7.tar.gz" 8a062878968c0f8e083046429647ad33b122542f --with-distro=none --disable-qt3 --disable-qt4  --disable-gtk --disable-gtk3 --disable-dbus --with-xml=expat LDFLAGS="-L/opt/csw/lib -R/opt/csw/lib" CFLAGS="-I/opt/csw/include/" --disable-pygobject --disable-autoipd

sudo /usr/sbin/useradd avahi
sudo /usr/sbin/groupadd avahi

fi

wtcmmi https://ftp.gnu.org/gnu/wget/wget-1.19.5.tar.gz 43b3d09e786df9e8d7aa454095d4ea2d420ae41c --with-ssl=openssl --with-openssl=/opt/csw/ssl LDFLAGS=-R/opt/csw/lib

if ! installed mDNSResponder-878.30.4; then

if [ ! -d /etc/rc4.d ]; then
	sudo mkdir /etc/rc4.d
	sudo chown root:sys /etc/rc4.d
	sudo chmod 755 /etc/rc4.d
fi

if [ ! -d /usr/share/man/man8 ]; then
	sudo mkdir /usr/share/man/man8
fi

if [ -f /usr/lib/libdns_sd.so ]; then
	sudo rm /usr/lib/libdns_sd.so
fi

fi

noconfig=1 \
make_subdir=mDNSPosix \
make_params="os=solaris CC=gcc" \
make_install_params="os=solaris" \
LD_RUN_PATH=/opt/csw/lib \
wtcmmi https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-878.30.4.tar.gz 6661247c232e296c8646130a26686b904db7c912

wtcmmi http://www.eterm.org/download/libast-0.7.tar.gz 8449049642c5a945336a326b8d512e4d261232d0

libast_lib=$(libast-config --prefix)/lib


## Eterm-0.9.6

if true; then

# pkg dependencies: gdb for automatic Eterm gdb tracebacks
pkg install gdb

# We need the separate backgrounds archive extracted within the source directory
download_and_sha http://eterm.org/download/Eterm-bg-0.9.6.tar.gz 26e81a1e91228c971c70ba06e006ef69490ef208
if [ ! -d Eterm-0.9.6 ]; then mkdir Eterm-0.9.6; fi
pushd Eterm-0.9.6
gtar xf ../Eterm-bg-0.9.6.tar.gz
popd

# Workaround a problem with the path in the install-sh command lines used
pushd Eterm-0.9.6/bg
if [ ! -f install-sh ]; then
	ln -s ../install-sh install-sh
fi
popd

wtcmmi http://eterm.org/download/Eterm-0.9.6.tar.gz b4cb00f898ffd2de9bf7ae0ecde1cc3a5fee9f02 --with-imlib=/opt/csw LDFLAGS="-L$libast_lib /opt/csw/X11/lib/libXdmcp.so -R/opt/csw/X11/lib -R/opt/csw/lib" --disable-xim

fi



## Eterm-0.8.10

if false; then

# package dependencies: imlib 1
sudo pkg install imlib

# Can't find an older version of this, let's try the newer one
# We need the separate backgrounds archive extracted within the source directory
download_and_sha http://eterm.org/download/Eterm-bg-0.9.6.tar.gz 26e81a1e91228c971c70ba06e006ef69490ef208
if [ ! -d Eterm-0.8.10 ]; then mkdir Eterm-0.8.10; fi
pushd Eterm-0.8.10
gtar xf ../Eterm-bg-0.9.6.tar.gz
popd

wtcmmi http://ftp.gnome.org/mirror/archive/ftp.sunet.se/pub/vendor/sco/skunkware/uw7/emulators/rxvt/src/Eterm-0.8.10.tar.gz 0cafeec2c9d79c874c6b312dcb105b912168ad0d --with-imlib=/opt/csw --prefix=/usr/local

fi

