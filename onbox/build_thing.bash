#!/opt/csw/bin/bash
set -e
set -o pipefail

# 
# Script for building things from source
#

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

patches_dir="${script_path}/patches"

cd ~/src

if [ ! -d logs ]; then
	mkdir logs
fi


######### Functions ############

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

function readlink() {
	if [ "$#" -ne 1 ]; then 
		die "bad params to readlink: $*"
	fi
	pkg install python 1>&2
	python -c '
import os, sys
src=sys.argv[1]
target=os.readlink(src)
if not os.path.isabs(target):
	target=os.path.abspath(os.path.join(os.path.dirname(src), target))
print target' "$1"
	#python -c 'import os, sys; src=sys.argv[1]; target=os.readlink(src); target=target if os.path.isabs(target) else os.path.abspath(os.path.join(os.path.dirname(src), target)); print target' "$1"
}

function ensure_link() {
	if [ "$#" -ne 2 ]; then 
		die "bad params to ensure_link: $*"
	fi
	symlink="$1"
	target="$2"

	if [ -f "$symlink" ] && [ "$(readlink "$symlink")" != "$target" ]; then
        	sudo rm "$symlink"
	fi      
                                      
	if [ ! -f "$symlink" ]; then
        	sudo mkdir -p "$(dirname "$symlink")"
        	sudo ln -s "$target" "$symlink"
	fi
}

function verify_sha() {
	if [ "$#" -ne 2 ]; then 
		die "bad params to verify_sha: $*"
	fi
	archive="$1"
	sha_expected="$2"

	sha_expected_len=$(echo -n "$sha_expected" | wc -c | awk '{print $1}')

	case $sha_expected_len in
	40)
		sha_args="-a 1"
		;;
	64)
		sha_args="-a 256"
		;;
	32)
		# md5
		sha_actual=$(openssl md5 "$archive" | awk '{print $2}')
		[ "$sha_actual" == "$sha_expected" ]
		return
		;;
	*)
		echo "don't know what sha algorithm uses a $sha_expected_len digit key, using sha1"
		sha_args="-a 1"
		;;
	esac

	sha_actual=$(shasum $sha_args "$archive" | awk '{print $1}')
	[ "$sha_actual" == "$sha_expected" ]
}

function download_and_sha() {
	if [ "$#" -ne 2 ]; then 
		die "bad params to download_and_sha: $*"
	fi
	url="$1"
	sha_expected="$2"

	archive="$(basename "$url")"
	if [ ! -f "$archive" ]; then
		wget "$url"
	fi	
	verify_sha "$archive" "$sha_expected"
}

function populate_certificates() {
	if [ "$#" -ne 1 ]; then
		die "bad params to populate_certificates: $*"
	fi
	
	ssl_dir="$1"

	[ -d "${ssl_dir}" ]

	if fgrep -x "${ssl_dir}" ~/certs/populated_certs; then
		return
	fi

	sudo pkg install gawk

	certs_dir=~/certs
	if [ ! -d "${certs_dir}" ]; then
		mkdir "${certs_dir}"
	fi
	wget "https://curl.haxx.se/ca/cacert.pem" --ca-certificate "${script_path}/GlobalSign_Root_CA.pem"

	pushd "${certs_dir}"
	cat ~/src/cacert.pem | gawk 'split_after==1{n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > "cert" n ".pem"}'
	popd

	sudo cp "${certs_dir}"/*.pem "${ssl_dir}/certs"

	sudo "${ssl_dir}/bin/c_rehash" "${ssl_dir}/certs"

	echo "${ssl_dir}" >> ~/certs/populated_certs
}

function wtcmmi() {

	# a function to build things
	# wget - tar - configure - make - make install

	if [ "$#" -lt 2 ]; then 
		die "bad params to wtcmmi: $*"
	fi

	set -x

	url="$1"
	sha_expected="$2"
	shift 2

	if [ "$archive_filename" == "" ]; then
		archive="$(basename "$url")"
		wget_options=""
	else
		archive="$archive_filename"
		wget_options='-O '"$archive_filename"
	fi

	if [ "$use_dirname" == "" ]; then
		dirname="${archive%.tar.gz}"
		dirname="${dirname%.tar.bz2}"
		dirname="${dirname%.tar.xz}"
	else
		dirname="$use_dirname"
	fi
	build_tag="installed-${dirname}"

	make_clean=no

	if [ "$tag_must_contain" == "" ]; then
		if [ -f "$build_tag" ]; then
			return
		fi
	else
		if fgrep -- "$tag_must_contain" "$build_tag"; then
			return
		else
			make_clean=yes
		fi
	fi

	if [ ! -f "$archive" ]; then
		wget "$url" $wget_options
	fi
	verify_sha "$archive" "$sha_expected"

	gtar xf "$archive"

	pushd "$dirname"

	if [ "$configure_name" == "" ]; then
		configure_name=configure
	fi

	if [ "$(echo "$configure_name" | cut -c1)" != "/" ]; then
		configure_name="./$configure_name"
	fi

	if [ "$patch_before_configure" != "" ] && [ -f "${patches_dir}/${dirname}.patch" ]; then
		gpatch -p1 -i "${patches_dir}/${dirname}.patch" 2>&1 | tee ~/src/logs/${dirname}.patch.out
	fi

	# configure
	if [ "$noconfig" == "" ]; then	
		${configure_name} "$@" 2>&1 | tee ~/src/logs/${dirname}.configure.out
		if [ -f config.log ]; then
			cp config.log ~/src/logs/${dirname}.config.log
		fi
	fi

	# apply a patch if there is one to apply post-config so it can change makefiles
	if [ "$patch_before_configure" == "" ] && [ -f "${patches_dir}/${dirname}.patch" ]; then
		# for easy patch creation make a .orig copy of the directory if we don't already have one
		if [ ! -d ../${dirname}.orig ]; then
			cp -R ../${dirname} ../${dirname}.orig
		fi

		gpatch -p1 -i "${patches_dir}/${dirname}.patch" 2>&1 | tee ~/src/logs/${dirname}.patch.out
	fi

	if [ "$make_subdir" != "" ]; then
		cd "$make_subdir"
	fi

	if [ "$make_clean" == "yes" ]; then
		gmake clean 2>&1 | tee ~/src/logs/${dirname}.make_clean.out
	fi

	if [ "$make_command" == "" ]; then
		make_command=gmake
	fi

	${make_command} ${make_params} 2>&1 | tee ~/src/logs/${dirname}.make.out

	sudo ${make_command} install ${make_install_params} 2>&1 | tee ~/src/logs/${dirname}.make_install.out

	popd	
	
	echo "installed $url $sha_expected $*" > "$build_tag"
}

################ Main script

## text mode / dev quality of life packages

pkg install git hexdump lynx

## avahi 0.7

if false; then

# libdaemon 0.14

wtcmmi "http://0pointer.de/lennart/projects/libdaemon/libdaemon-0.14.tar.gz" 78a4db58cf3a7a8906c35592434e37680ca83b8f

# needs better libintl / gettext
pkg install ggettext
# gettext utilites have alternate names
for tool in xgettext msgfmt; do
	if [ ! -f /opt/csw/bin/$tool ]; then
		sudo ln -s /opt/csw/bin/g${tool} /opt/csw/bin/${tool}
	fi
done

# avahi-0.7

#make_params="V=1" \
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
wtcmmi "http://avahi.org/download/avahi-0.7.tar.gz" 8a062878968c0f8e083046429647ad33b122542f --with-distro=none --disable-qt3 --disable-qt4  --disable-gtk --disable-gtk3 --disable-dbus --with-xml=expat LDFLAGS="-L/opt/csw/lib -R/opt/csw/lib" CFLAGS="-I/opt/csw/include/" --disable-pygobject --disable-autoipd

sudo /usr/sbin/useradd avahi
sudo /usr/sbin/groupadd avahi

fi

## wget 1.19.5 -- first build, with opencsw openssl

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

# requires: libast, imlib2
# wants: gdb, ncurses

if true; then

# pkg dependencies: gdb for automatic Eterm gdb tracebacks, ncurses for more appropriate terminfo
pkg install gdb ncurses

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

# setup terminfo for Eterm
ensure_link "/usr/share/lib/terminfo/E/Eterm" "/opt/csw/share/terminfo/x/xterm-256color"

fi # ETerm-0.9.6


## Eterm-0.8.10
# requires: libast, imlib 1.x

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

fi # Eterm-0.8.10


## OpenSSL 1.0.2o

configure_name=config \
wtcmmi https://www.openssl.org/source/openssl-1.0.2o.tar.gz a47faaca57b47a0d9d5fb085545857cc92062691

populate_certificates "/usr/local/ssl"


## Wget 1.19.5 -- second build, with OpenSSL 1.0.x we just built
# Requires: openssl

tag_must_contain=--with-openssl=/usr/local/ssl \
wtcmmi https://ftp.gnu.org/gnu/wget/wget-1.19.5.tar.gz 43b3d09e786df9e8d7aa454095d4ea2d420ae41c --with-ssl=openssl --with-openssl=/usr/local/ssl LDFLAGS="-ldl"


## Qt 4.8.5

if false; then

sudo pkg install gcc4g++ gcc4g++rt

LD_RUN_PATH=/opt/csw/gcc4/lib \
wtcmmi https://download.qt.io/archive/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz 76aef40335c0701e5be7bb3a9101df5d22fe3666 -opensource -confirm-license -platform "solaris-g++"

fi


## Qt 4.6.4

sudo pkg install gcc4g++ gcc4g++rt

make_params=-j2 \
LD_RUN_PATH=/opt/csw/gcc4/lib \
wtcmmi https://mirror.csclub.uwaterloo.ca/qtproject/archive/qt/4.6/qt-everywhere-opensource-src-4.6.4.tar.gz df3a8570cfec2793a76818c9b31244f3ba8a2f3b -opensource -confirm-license -platform "solaris-g++" -nomake examples -no-sse -no-sse2

QT464=/usr/local/Trolltech/Qt-4.6.4


## Boost 1.67

if false; then

noconfig=1 \
make_command="/bin/bash ./bootstrap.sh" \
wtcmmi https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.bz2 2684c972994ee57fc5632e03bf044746f6eb45d4920c343937a465fd67a5adba

fi


## Boost 1.52.0

if false; then

configure_name="/bin/bash ./bootstrap.sh" \
make_command="./b2" \
wtcmmi https://sourceforge.net/projects/boost/files/boost/1.52.0/boost_1_52_0.tar.bz2 cddd6b4526a09152ddc5db856463eaa1dc29c5d9

fi


## Launchy 2.5
# requires: Qt 4.6.x+, Boost

pkg install boost_devel boost_rt

boost_dir=/opt/csw/include

configure_name="${QT464}/bin/qmake -r -unix Launchy.pro" \
wtcmmi https://www.launchy.net/downloads/src/launchy-2.5.tar.gz 7a6317168fe7aa219c138fbbc0f84539be9bce9e "INCLUDEPATH+=$boost_dir" "LIBS+=-L/usr/openwin/lib -R/usr/openwin/lib -lX11" 


## VIM 7.4

use_dirname=vim74 \
wtcmmi ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2 601abf7cc2b5ab186f40d8790e542f86afca86b7


## zaycakitayca/gnome-menu-editor-qt

# form of github tarball link is https://api.github.com/repos/User/repo/tarball/master

archive_filename=zaycakitayca-gnome-menu-editor-qt-c50bc7a.tar.gz \
configure_name="${QT464}/bin/qmake gnome-menu-editor-qt.pro " \
patch_before_configure=1 \
wtcmmi https://api.github.com/repos/zaycakitayca/gnome-menu-editor-qt/tarball/c50bc7a e590696de0180369f27a0fba9a5a09e3575546c7

sudo cp -r zaycakitayca-gnome-menu-editor-qt-c50bc7a/gnome-menu-editor-qt /usr/local/bin/gnome-menu-editor-qt


if false; then

## Imagemagick 7
wtcmmi https://www.imagemagick.org/download/ImageMagick-7.0.8-6.tar.xz 4c1a95ea1dfb04d197568ecf9a1084347f15e51c CFLAGS="-fvisibility=default" CXXFLAGS="-fvisibility=default"

fi

exit 1


## Gtk3 3.22.30

#pkg install gtk_doc 
pkg install libffi

LDFLAGS="-R/opt/csw/gcc4/lib" \
wtcmmi https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.bz2 085b6aa253e0f91cae70b3cdbe8c1ac2 --enable-unicode-properties --enable-utf8

#archive_filename="gobject-introspection-1.56.1.tar.gz" \
#configure_name="autogen.sh" \
#wtcmmi https://github.com/GNOME/gobject-introspection/archive/1.56.1.tar.gz c37114c348176e1321f81e2332c4e89d0dbef37a

wtcmmi https://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.8.1.tar.xz e0fe90ede22f7f16bbde7bdea791a835f2773fc9 LDFLAGS=-R/opt/csw/lib

LDFLAGS="-R/usr/local/lib" \
CFLAGS=-march=prescott \
wtcmmi http://ftp.gnome.org/pub/gnome/sources/glib/2.56/glib-2.56.1.tar.xz 988af38524804ea1ae6bc9a2bad181ff

wtcmmi http://ftp.gnome.org/pub/gnome/sources/gtk+/3.22/gtk+-3.22.30.tar.xz 1be769c97b4dac9221d63f62f61ef724c55a14a3

