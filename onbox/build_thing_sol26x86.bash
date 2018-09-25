#!/usr/bin/env bash
set -e
set -x

set -o pipefail || ( \
	tgcpkg install libgcc_s1 && \
	tgcpkg install readline && \
	tgcpkg install libstdc++6 && \
	tgcpkg install gettext && \
	tgcpkg install libiconv && \
	tgcpkg install gawk && \
	tgcpkg install bash )
set -o pipefail

# 
# Script for building things from source
#

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

patches_dir="${script_path}/patches"

main_packages_prefix=/usr/local

cd ~/src

if [ ! -d logs ]; then
	mkdir logs
fi


######### Functions ############

function die() {

	# Show an error message and exit

	msg="$1"

	echo "$msg" 1>&2
	exit 1
}

function installed() {

	# Check if a thing is already installed.

	dirname="$1"

	build_tag="installed-${dirname}"

	if [ ! -f "$build_tag" ]; then
		return 1
	fi
}	

function readlink() {

	# Print the target of a symlink.

	if [ "$#" -ne 1 ]; then 
		die "bad params to readlink: $*"
	fi

	symlink="$1"

	pkg install python 1>&2
	python -c '
import os, sys
src=sys.argv[1]
target=os.readlink(src)
if not os.path.isabs(target):
	target=os.path.abspath(os.path.join(os.path.dirname(src), target))
print target' "$symlink"
	#python -c 'import os, sys; src=sys.argv[1]; target=os.readlink(src); target=target if os.path.isabs(target) else os.path.abspath(os.path.join(os.path.dirname(src), target)); print target' "$1"
}

function ensure_link() {

	# Ensure there is a symlink at the given location that points to
        # the given target.

	if [ "$#" -ne 2 ]; then 
		die "bad params to ensure_link: $*"
	fi

	symlink="$1"
	target="$2"

	if [ -h "$symlink" ] && [ "$(readlink "$symlink")" != "$target" ]; then
        	sudo rm "$symlink"
	fi      
                                      
	if [ ! -h "$symlink" ]; then
        	sudo mkdir -p "$(dirname "$symlink")"
        	sudo ln -s "$target" "$symlink"
	fi
}

function verify_sha() {

	# Verify that the given file matches the given expected hash.
        # Guesses the hash algorithm from the length of the expected hash.

	if [ "$#" -ne 2 ]; then 
		die "bad params to verify_sha: $*"
	fi

	archive="$1"
	sha_expected="$2"

	sha_expected_len=$(echo -n "$sha_expected" | wc -c | awk '{print $1}')

	case $sha_expected_len in
	40)
		sha_args="-a 1"
		sha_alt="sha1sum"
		;;
	64)
		sha_args="-a 256"
		sha_alt="sha256sum"
		;;
	32)
		# md5
		sha_actual=$(openssl md5 "$archive" | awk '{print $2}')
		[ "$sha_actual" == "$sha_expected" ]
		return
		;;
	*)
		echo "don't know what sha algorithm uses a $sha_expected_len digit key, using sha1"
		echo "md5 is $(openssl md5 "$archive" | awk '{print $2}')"
		sha_args="-a 1"
		sha_alt="sha1sum"
		;;
	esac

	if type shasum; then
		sha_actual=$(shasum $sha_args "$archive" | awk '{print $1}')
	else
		sha_actual=$($sha_alt "$archive" | awk '{print $1}')
	fi
	[ "$sha_actual" == "$sha_expected" ]
}

function download_and_sha() {

	# Download the given URL and ensure that the downloaded file matches the 
        # given expected hash.

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

uname_rm="$(uname -r) $(uname -m)"

function need_util() {
	util_name="$1"

	case $util_name in 
	gawk | gdb | sed | xgettext )
		if [ "$util_name" == "xgettext" ]; then
			pkg_name=gettext
		else
                	pkg_name="$util_name"
		fi

		if [ "$uname_rm" == "5.6 i86pc" ]; then
			tgcpkg install $pkg_name
			if [ ! -f /usr/tgcware/bin/$util_name ] && [ -f /usr/tgcware/bin/g$util_name ]; then
				ensure_link /usr/tgcware/bin/$util_name /usr/tgcware/bin/g$util_name
			fi
		else
			pkg install $pkg_name
		fi
		;;
	*)
		die "unknown util $util_name"
		;;
	esac

}

function populate_certificates() {

	# Populate the given OpenSSL-compatibile install with known-good root certs
        # from haxx.se's CA cert set derived from Mozilla's set

	# A note about SSL paths:
	# When you build openssl 1.0.x from source with a --prefix
	# it puts the bin and lib dirs right in the prefix directory
	# and makes a subdirectory of the prefix directory ssl for
	# the usual configuration directories like certs.

	# The packaged openssl 1.0.x for solaris /usr/local instead puts
	# the bin, lib, and configuration stuff like cert all in
	# /usr/local/ssl

	# populate_certificates takes the directory containing the certs directory,
	# usually a directory called "ssl"

	if [ "$#" -ne 1 ]; then
		die "bad params to populate_certificates: $*"
	fi

	ssl_dir="$1"

	[ -d "${ssl_dir}" ]

	if fgrep -x "${ssl_dir}" ~/certs/populated_certs > /dev/null; then
		return
	fi

	need_util gawk

	certs_dir=~/certs
	if [ ! -d "${certs_dir}" ]; then
		mkdir "${certs_dir}"
	fi
	if [ -f "cacert.pem" ]; then
		rm cacert.pem
	fi
	wget "https://curl.haxx.se/ca/cacert.pem" --ca-certificate "${script_path}/GlobalSign_Root_CA.pem"

	pushd "${certs_dir}"
	cat ~/src/cacert.pem | gawk 'split_after==1{n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > "cert" n ".pem"}'
	popd

	sudo cp "${certs_dir}"/*.pem "${ssl_dir}/certs"

	# try to find the c_rehash util that goes with this ssl dir

	c_rehash=
	for rel in . .. ../..; do
		if [ -f "${ssl_dir}/${rel}/bin/c_rehash" ]; then
			c_rehash="${ssl_dir}/${rel}/bin/c_rehash"
		fi
	done

	if [ "${c_rehash}" == "" ]; then
		die "can't find c_rehash for ssl dir $ssl_dir"
	fi

	sudo "${c_rehash}" "${ssl_dir}/certs"

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
		internal_wget_options=""
	else
		archive="$archive_filename"
		internal_wget_options='-O '"$archive_filename"
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

	# 1) wget

	if [ ! -f "$archive" ]; then
		wget "$url" $wget_options $internal_wget_options
	fi
	verify_sha "$archive" "$sha_expected"

	# 2) tar

	gtar xf "$archive"

	pushd "$dirname"

	# 3) configure

	# apply a patch if there is one to apply and patch_before_configure is specified
	if [ "$patch_before_configure" != "" ] && [ -f "${patches_dir}/${dirname}.patch" ]; then
		gpatch -p1 -i "${patches_dir}/${dirname}.patch" 2>&1 | tee ~/src/logs/${dirname}.patch.out
	fi

	if [ "$configure_name" == "" ]; then
		configure_name=configure
	fi

	if [ "$(echo "$configure_name" | cut -c1)" != "/" ]; then
		configure_name="./$configure_name"
	fi

	if [ "$noconfig" == "" ]; then	
		${configure_name} "$@" 2>&1 | tee ~/src/logs/${dirname}.configure.out
		if [ -f config.log ]; then
			cp config.log ~/src/logs/${dirname}.config.log
		fi
	fi

	# 4) make

	# apply a patch if there is one to apply, post-config by default so it can change makefiles
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

	# 5) install

	sudo ${make_command} install ${make_install_params} 2>&1 | tee ~/src/logs/${dirname}.make_install.out

	popd	

	# write an installation tag, indicating that it was successfully installed with the given settings.
	echo "installed $url $sha_expected $*" > "$build_tag"
}

################ Main script

tgcpkg install patch

ensure_link /usr/local/bin/gpatch /usr/local/bin/patch

tgcpkg install gawk
ensure_link /usr/tgcware/bin/awk /usr/tgcware/bin/ggawk

tgcpkg install grep
ensure_link /usr/tgcware/bin/grep /usr/tgcware/bin/ggrep

if true; then  # BIG JUMP

# we'll need a minimal wget install to at least do simple package downloads
tgcpkg install wget

## text mode / dev quality of life packages

tgcpkg install git
tgcpkg install lynx
tgcpkg install less

#tgcpkg install hexdump
# moved below certificates init

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

## wtcmmi requisites for the wget we already have

tgcpkg install tar
tgcpkg install bzip2
tgcpkg install xzutils
tgcpkg install make
# terrible pkg config for our needs
wtcmmi http://ftp.gnome.org/pub/GNOME/sources/pkg-config/0.19/pkg-config-0.19.tar.bz2 a93d762d70866983dfdc2ec6588989386dd33674 

## wget 1.19.5 -- first build, with tgcware openssl

tgcpkg install openssl-devel

tgcpkg install binutils  # wget configure's RAND_egd check hangs stock ld, so let's try binutils
for util in ld as objdump ar addr2line "c++filt" gprof nm objcopy ranlib readelf size strings strip; do
	[ -f "/usr/tgcware/bin/g${util}" ]
	ensure_link "/usr/tgcware/bin/${util}" "/usr/tgcware/bin/g${util}"
done
# this didn't fix it, but applying the patches to the OS did

# let's upgrade gcc
tgcpkg install mpfr
tgcpkg install gcc-4.3

# build the wget with existing openssl
wtcmmi ftp://ftp.gnu.org/gnu/wget/wget-1.19.5.tar.gz 43b3d09e786df9e8d7aa454095d4ea2d420ae41c --with-ssl=openssl --with-openssl=/opt/csw/ssl LDFLAGS=-R/opt/csw/lib

# let's populate that with certs
populate_certificates /usr/tgcware/share/ssl

if false; then

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

fi

fi # BIG JUMP

## Eterm-0.9.6

# requires: libast, imlib2
# wants: gdb, ncurses

if [ "$uname_rm" == "5.6 i86pc" ]; then

#wtcmmi http://downloads.sourceforge.net/freetype/freetype-2.3.7.tar.bz2 f16f849d6e739ce8842008586af36371a32ac064

tgcpkg install automake
tgcpkg install autoconf
tgcpkg install libtool

configure_name="$(which bash) autogen.sh" \
wtcmmi http://downloads.sourceforge.net/freetype/freetype-2.3.9.tar.bz2 db08969cb5053879ff9e973fe6dd2c52c7ea2d4e
wtcmmi http://xmlsoft.org/sources/libxml2-2.7.7.tar.gz 8592824a2788574a172cbddcdc72f734ff87abe3 LDFLAGS="-R/usr/tgcware/lib"
wtcmmi http://fontconfig.org/release/fontconfig-2.4.2.tar.gz cd5e30625680a0435563b586275156eaf8d0d34a LDFLAGS="-R/usr/tgcware/lib"
#wtcmmi ftp://ftp.deu.edu.tr/pub/Solaris/sunfreeware/SOURCES/fontconfig-2.4.2.tar.gz cd5e30625680a0435563b586275156eaf8d0d34a

# we also need image format libraries
use_dirname=jpeg-8d \
wtcmmi http://www.ijg.org/files/jpegsrc.v8d.tar.gz f080b2fffc7581f7d19b968092ba9ebc234556ff LDFLAGS="-R/usr/tgcware/lib"
tgcpkg install zlib-devel
wtcmmi http://downloads.sourceforge.net/libpng/libpng-1.5.13.tar.xz a6c0fc33b2031e4a9154da03c7d4e7807bc039e7 --disable-static LDFLAGS="-R/usr/tgcware/lib"
wtcmmi http://download.osgeo.org/libtiff/old/tiff-3.9.1.tar.gz 675ad1977023a89201b80cd5cd4abadea7ba0897 --disable-static LDFLAGS="-L/usr/tgcware/lib -R/usr/tgcware/lib" --with-jpeg-include-dir=/usr/local/include --with-jpeg-lib-dir=/usr/local/lib

#wtcmmi https://downloads.sourceforge.net/enlightenment/imlib2-1.5.1.tar.bz2 3e97e7157380f0cfbdf4f3c950a7a00bdfa6072c LDFLAGS="-L/usr/local/lib -R/usr/local/lib -L/usr/tgcware/lib -R/usr/tgcware/lib" CPPFLAGS="-I/usr/local/include -I/usr/tgcware/include -D__EXPORT__=" --disable-visibility-hiding
wtcmmi https://downloads.sourceforge.net/enlightenment/imlib2-1.4.4.tar.bz2 aca2cf5d40ddcd8a3acfde605f319fccce7c2a2b LDFLAGS="-L/usr/local/lib -R/usr/local/lib -L/usr/tgcware/lib -R/usr/tgcware/lib" CPPFLAGS="-I/usr/local/include -I/usr/tgcware/include -D__EXPORT__="

else

pkg install imlib2

fi

if true; then

wtcmmi http://www.eterm.org/download/libast-0.7.tar.gz 8449049642c5a945336a326b8d512e4d261232d0

libast_lib=$(libast-config --prefix)/lib

# pkg dependencies: gdb for automatic Eterm gdb tracebacks, ncurses for more appropriate terminfo
need_util gdb
#pkg install ncurses
tgcpkg install ncurses

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

#wtcmmi http://eterm.org/download/Eterm-0.9.6.tar.gz b4cb00f898ffd2de9bf7ae0ecde1cc3a5fee9f02 --with-imlib=/opt/csw LDFLAGS="-L$libast_lib /opt/csw/X11/lib/libXdmcp.so -R/opt/csw/X11/lib -R/opt/csw/lib" --disable-xim
wtcmmi http://eterm.org/download/Eterm-0.9.6.tar.gz b4cb00f898ffd2de9bf7ae0ecde1cc3a5fee9f02 --with-imlib=/opt/csw LDFLAGS="-L$libast_lib /usr/lib/libresolv.so.2 -R$libast_lib" --disable-xim

# setup terminfo for Eterm
if [ "$uname_rm" == "5.6 i86pc" ]; then
	ensure_link "/usr/share/lib/terminfo/E/Eterm" "/usr/share/lib/terminfo/x/xterm"
else
	ensure_link "/usr/share/lib/terminfo/E/Eterm" "${main_packages_prefix}/share/terminfo/x/xterm-256color"
fi

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

if false; then

## WindowMaker

# need xft
wtcmmi https://xlibs.freedesktop.org/release/render-0.8.tar.gz 73b88307fd318e0a1a7ed50c7cf7808d550cca99
wtcmmi https://xlibs.freedesktop.org/release/xrender-0.8.3.tar.gz a99c1c395b86b2fc4a92bd6de750e1438a5f3461
wtcmmi https://xlibs.freedesktop.org/release/xft-2.1.2.tar.gz 892d57cac909ef51c3c49b9a6aaf54e6b6ab6b92 --with-x-includes=/usr/openwin/include --with-x-libraries=/usr/openwin/lib

#wtcmmi https://www.x.org/releases/individual/lib/libXrender-0.9.0.2.tar.bz2 6466ec00dea637c39dd89bd82f9f3851476d81a7
#wtcmmi https://www.x.org/releases/individual/lib/libXft-2.1.8.2.tar.bz2 2f0141e25ac82ce672f2b10e4f60e5d1f9bb8622

patch_before_configure=1 \
wtcmmi https://www.windowmaker.org/pub/source/release/WindowMaker-0.95.8.tar.gz fd59e3cb07071bd70359eef427ff12eb9cfe4641 --disable-shape PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

fi

wtcmmi http://ftp.vim.org/ftp/ftp/pub/ibiblio/distributions/slack390/slack390-9.1/source/xap/windowmaker/WindowMaker-0.80.2.tar.bz2 efc8b3e29f738b44cca6257304ae0951cfd33b43

## OpenSSL 1.0.2o

# we already have 1.0.2o
if false; then

BUILT_SSL_DIR=/usr/local/ssl102o

configure_name=config \
wget_options=--no-check-certificate \
wtcmmi http://www.openssl.org/source/openssl-1.0.2o.tar.gz a47faaca57b47a0d9d5fb085545857cc92062691 --prefix=${BUILT_SSL_DIR}

# If existing wget wasn't using 1.0.x, it's not ready to populate yet
#populate_certificates "${BUILT_SSL_DIR}"


## Wget 1.19.5 -- second build, with OpenSSL 1.0.x we just built
# Requires: openssl

PKG_CONFIG_PATH=${BUILT_SSL_DIR}/lib/pkgconfig \
tag_must_contain=--with-openssl=${BUILT_SSL_DIR} \
wtcmmi https://ftp.gnu.org/gnu/wget/wget-1.19.5.tar.gz 43b3d09e786df9e8d7aa454095d4ea2d420ae41c --with-ssl=openssl --with-openssl=${BUILT_SSL_DIR} LDFLAGS="-ldl" --without-libintl-prefix

# see note about SSL paths
populate_certificates "${BUILT_SSL_DIR}/ssl"

fi

## hexdump and other random utils
#wtcmmi https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.32/util-linux-2.32.tar.xz 4a21387d51f73bab44230c3bf9fe5a291e761111


## GIMP 1.0

source ${script_path}/gimp_things.bash

## set root xpm

source ${script_path}/xv.bash

## Qt 4.8.5

if false; then

sudo pkg install gcc4g++ gcc4g++rt

LD_RUN_PATH=/opt/csw/gcc4/lib \
wtcmmi https://download.qt.io/archive/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz 76aef40335c0701e5be7bb3a9101df5d22fe3666 -opensource -confirm-license -platform "solaris-g++"

fi

if false; then

## Qt 4.6.4

#sudo pkg install gcc4g++ gcc4g++rt
# we have gcc-4.3 above

tgcpkg install gcc-c++

#GCC_LIB=/opt/csw/gcc4/lib
GCC_LIB=/usr/tgcware/lib

make_params=-j2 \
LD_RUN_PATH=$GCC_LIB \
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

fi


## VIM 7.4

use_dirname=vim74 \
wtcmmi ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2 601abf7cc2b5ab186f40d8790e542f86afca86b7 LDFLAGS="-R/usr/local/lib"

## pdf

source ${script_path}/gpdf.bash
source ${script_path}/xpdf.bash


exit 1


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
