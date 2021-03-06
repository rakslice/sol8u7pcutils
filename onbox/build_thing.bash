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

	if [ -f "$symlink" ] && [ "$(readlink "$symlink")" != "$target" ]; then
        	sudo rm "$symlink"
	fi      
                                      
	if [ ! -f "$symlink" ]; then
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
		;;
	64)
		sha_args="-a 256"
		;;
	128)
		sha_args="-a 512"
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

function populate_certificates() {

	# Populate the given OpenSSL-compatibile install with known-good root certs
        # from haxx.se's CA cert set derived from Mozilla's set

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

	# 1) wget

	if [ ! -f "$archive" ]; then
		wget "$url" $wget_options
	fi
	verify_sha "$archive" "$sha_expected"

	# 2) tar

	gtar xf "$archive"

	src_dir="$(pwd)"

	pushd "$dirname"

	# 3) configure

	# apply a patch if there is one to apply and patch_before_configure is specified
	if [ "$patch_before_configure" != "" ] && [ -f "${patches_dir}/${dirname}.patch" ]; then
		# for easy patch creation make a .orig copy of the directory if we don't already have one
		if [ ! -d "${src_dir}/${dirname}.orig" ]; then
			cp -R "${src_dir}/${dirname}" "${src_dir}/${dirname}.orig"
		fi
		gpatch -p1 -i "${patches_dir}/${dirname}.patch" 2>&1 | tee ~/src/logs/${dirname}.patch.out
	fi

	# do the rest of the build process including configure in a subdir
	if [ "$use_subdir" != "" ]; then
		cd "$use_subdir"
	fi

	if [ "$pre_configure_command" != "" ]; then
		$pre_configure_command 2>&1 | tee ~/src/logs/${dirname}.preconfigure.out
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
		if [ ! -d "${src_dir}/${dirname}.orig" ]; then
			cp -R "${src_dir}/${dirname}" "${src_dir}/${dirname}.orig"
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

	# 6) verify binaries
	prefix=/usr/local
	if [ "$verify_binaries" != "" ]; then
		for f in $verify_binaries; do
			[ -f $prefix/bin/$f ]
			if ldd $prefix/bin/$f | grep '(file not found)'; then
				false
			fi
		done
	fi

	# write an installation tag, indicating that it was successfully installed with the given settings.
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
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/opt/csw/lib/pkgconfig:/opt/csw/X11/lib/pkgconfig \
wtcmmi "http://avahi.org/download/avahi-0.7.tar.gz" 8a062878968c0f8e083046429647ad33b122542f --with-distro=none --disable-qt3 --disable-qt4  --disable-gtk --disable-gtk3 --disable-dbus --with-xml=expat LDFLAGS="-L/opt/csw/lib -R/opt/csw/lib" CFLAGS="-I/opt/csw/include/" --disable-pygobject --disable-autoipd

sudo /usr/sbin/useradd avahi
sudo /usr/sbin/groupadd avahi

fi

pkg install gcc4core
pkg install gcc4g++
pkg install gcc4g++rt
pkg install gmake
pkg install pkgconfig

## wget 1.19.5 -- first build, with opencsw openssl

wtcmmi ftp://ftp.gnu.org/gnu/wget/wget-1.19.5.tar.gz 43b3d09e786df9e8d7aa454095d4ea2d420ae41c --with-ssl=openssl --with-openssl=/opt/csw/ssl LDFLAGS=-R/opt/csw/lib

if false; then

if ! installed mDNSResponder-878.30.4; then

for d in /etc/rc{4,5}.d; do
if [ ! -d $d ]; then
	sudo mkdir $d
	sudo chown root:sys $d
	sudo chmod 755 $d
fi
done

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

## OpenSSL 1.0.2o

configure_name=config \
wtcmmi https://www.openssl.org/source/openssl-1.0.2o.tar.gz a47faaca57b47a0d9d5fb085545857cc92062691 shared -R/opt/csw/gcc4/lib -R/usr/local/ssl/lib

## Wget 1.19.5 -- second build, with OpenSSL 1.0.x we just built
# Requires: openssl

# disable existing ssl so we get a good build

if compgen -G '/opt/csw/lib/libssl*'; then
	if [ ! -d /opt/csw/lib/disabled ]; then
		sudo mkdir /opt/csw/lib/disabled
	fi
	sudo mv /opt/csw/lib/libssl* /opt/csw/lib/disabled/
	sudo mv /opt/csw/lib/libcrypto* /opt/csw/lib/disabled/
fi

PKG_CONFIG_PATH=/usr/local/ssl/lib/pkgconfig \
tag_must_contain=--with-openssl=/usr/local/ssl \
wtcmmi ftp://ftp.gnu.org/gnu/wget/wget-1.19.5.tar.gz 43b3d09e786df9e8d7aa454095d4ea2d420ae41c --with-ssl=openssl --with-openssl=/usr/local/ssl LDFLAGS="-ldl -R/usr/local/ssl/lib -R/opt/csw/gcc4/lib"

# to get the newly-built wget to be used, explicitly rehash
hash -r

populate_certificates "/usr/local/ssl"

# mej-libast for eterm

pkg install gsed

pkg install libtool
pkg install autoconf
pkg install automake


patch_before_configure="1" \
configure_name=autogen.sh \
archive_filename=mej-libast-9f1e275.tar.gz \
wtcmmi https://api.github.com/repos/mej/libast/tarball/9f1e275 590664bf913095e658ff5d01b8d3a4e68ccdc708
#wtcmmi http://www.eterm.org/download/libast-0.7.tar.gz 8449049642c5a945336a326b8d512e4d261232d0

libast_lib=$(libast-config --prefix)/lib
#libast_lib=/usr/local/lib

## Eterm-0.9.6

# requires: libast, imlib2
# wants: gdb, ncurses

if true; then

pkg install imlib2

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

pkg install libxdmcp

ensure_link /usr/local/bin/tr /usr/bin/tr
wtcmmi http://eterm.org/download/Eterm-0.9.6.tar.gz b4cb00f898ffd2de9bf7ae0ecde1cc3a5fee9f02 --with-imlib=/opt/csw LDFLAGS="-L$libast_lib /opt/csw/X11/lib/libXdmcp.so -R/opt/csw/X11/lib -R/opt/csw/lib" CPPFLAGS=-DMEMSET=memset --disable-xim
sudo rm /usr/local/bin/tr

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

## Qt 4.8.5

if false; then

LD_RUN_PATH=/opt/csw/gcc4/lib \
make_params=-j2 \
wtcmmi https://download.qt.io/archive/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz 76aef40335c0701e5be7bb3a9101df5d22fe3666 -opensource -platform "solaris-g++" -confirm-license 

fi


## Qt 4.6.4

pkg install gcc4g++
pkg install gcc4g++rt

pkg install gcc3corert
pkg install gcc3g++
pkg install gcc3g++rt

pkg install glib2
pkg install freetype2
pkg install ggettext
pkg install fontconfig
pkg install libiconv
pkg install zlib
pkg install expat

pkg install glib2_devel
pkg install gtk2_devel
pkg install gtkmm_devel
pkg install libcairo_devel
pkg install libx11_devel
pkg install libxml2_devel
pkg install libxrender_devel
pkg install libpango_devel

make_params=-j5 \
LD_RUN_PATH=/opt/csw/gcc4/lib \
configure_name="/bin/bash ./configure" \
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

if false; then
make_params=-j5 \
configure_name="${QT464}/bin/qmake -r -unix Launchy.pro" \
wtcmmi https://www.launchy.net/downloads/src/launchy-2.5.tar.gz 7a6317168fe7aa219c138fbbc0f84539be9bce9e "INCLUDEPATH+=$boost_dir" "LIBS+=-L/usr/openwin/lib -R/usr/openwin/lib -lX11" 
fi

make_params=-j2 \
configure_name="${QT464}/bin/qmake -r -unix Launchy.pro" \
archive_filename="rakslice-launchy-afe0444.tar.gz" \
wtcmmi https://api.github.com/repos/rakslice/launchy/tarball/afe0444 f236db1cd06be72db9167d6dd91ca39f17282552 "INCLUDEPATH+=$boost_dir" "LIBS+=-L/usr/openwin/lib -R/usr/openwin/lib" 

## VIM 7.4

use_dirname=vim74 \
wtcmmi ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2 601abf7cc2b5ab186f40d8790e542f86afca86b7

ensure_link "/usr/local/bin/vi" "/usr/local/bin/vim"


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

if [ -f ~/hash.db.add ]; then
	rm ~/hash.db.add
fi

if [ ! -f ~/src/installed-mozilla-certs ]; then

for f in /usr/local/ssl/certs/cert*.pem; do
	dest_file="/opt/csw/share/ca-certificates/mozilla/$(basename "$f")"
	if [ ! -f "$dest_file" ]; then
		sudo cp "$f" "$dest_file"
		cert_hash=$(openssl x509 -noout -hash -in "$dest_file")
		echo "$(basename "$f")=${cert_hash}.0" >> ~/hash.db.add
	fi
done

if [ -f ~/hash.db.add ]; then
	sudo bash -c 'cat ~/hash.db.add >> /opt/csw/share/ca-certificates/hash.db'
fi

touch ~/src/installed-mozilla-certs

fi 

## coreutils

pkg install xz

wtcmmi https://ftp.gnu.org/gnu/coreutils/coreutils-8.11.tar.xz 9c03e0de95ac6ec65129eaf0b3605982a77d8fedaeca5b665ad44fe901695b3b

## distcc

# # new m4 automake autoconf

wtcmmi https://ftp.gnu.org/gnu/automake/automake-1.16.1.tar.xz 1012bc79956013d53da0890f8493388a6cb20831 
wtcmmi https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz 228604686ca23f42e48b98930babeb5d217f1899
wtcmmi https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz e891c3193029775e83e0534ac0ee0c4c711f6d23
configure_name="/usr/bin/env bash ./configure" \
wtcmmi https://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.xz 3e7504b832eb2dd23170c91b6af72e15b56eb94e

# python 3.7.0

#wtcmmi https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tar.xz eb8c2a6b1447d50813c02714af4681f3
wtcmmi https://www.python.org/ftp/python/3.1.5/Python-3.1.5.tar.xz 20dd2b7f801dc97db948dd168df4dd52 \
SHELL="$(which bash)" CONFIG_SHELL="$(which bash)" \
make_params="SHELL=$(which bash)" \
LDFLAGS="-L/usr/local/lib -R/usr/local/lib -L/opt/csw/lib -R/opt/csw/lib -R/opt/csw/gcc4/lib -R/usr/local/ssl/lib"

#mkdir -p distcc/_include_server

use_dirname=distcc \
pre_configure_command=./autogen.sh \
wtcmmi https://github.com/distcc/distcc/releases/download/v3.3.2/distcc-3.3.2.tar.gz 4f2200e74e22b2cdf316c1126eb180e568756d39 --without-libiberty

if false; then
## firefox 3.0.14

pkg install firefox

use_subdir=nspr \
wtcmmi https://archive.mozilla.org/pub/nspr/releases/v4.19/src/nspr-4.19.tar.gz e1d27282ad6286b69d6b9fd07201d3dd CC=gcc

if false && [ ! -f installed-nss-3.38 ]; then
	download_and_sha https://archive.mozilla.org/pub/nspr/releases/v4.19/src/nspr-4.19.tar.gz e1d27282ad6286b69d6b9fd07201d3dd
	mkdir -p nss-3.38/nspr_temp
	pushd nss-3.38/nspr_temp
	gtar xf ../../nspr-4.19.tar.gz
	popd
	pushd nss-3.38
	cp -R nspr_temp/nspr-4.19/nspr .
	rm -rf nspr_temp
	popd
fi

# clear out files that the patch creates
for f in nss-3.38/nss/config/{Makefile,nss-config.in,nss.pc.in}; do
	if [ -f "$f" ]; then
		rm $f
	fi
done

patch_before_configure=1 \
use_subdir=nss \
noconfig=1 \
LD=/opt/csw/bin/gld \
make_params="NS_USE_GCC=1 CC=gcc BUILD_OPT=1 NSPR_INCLUDE_DIR=/usr/local/include/nspr NSPR_LIB_DIR=/usr/local/lib USE_SYSTEM_ZLIB=1 ZLIB_LIBS=-lz NSS_ENABLE_WERROR=0 OS_CFLAGS=-msse2" \
wtcmmi https://archive.mozilla.org/pub/security/nss/releases/NSS_3_38_RTM/src/nss-3.38.tar.gz ac9065460a7634ba8eb0f942f404e773 

fi

## inkscape 0.48

if false; then
# currently hitting problems with this glibmm version afaict

pkg install libgc
pkg install glibmm_devel
pkg install libsigc++_devel
pkg install libatk_devel
pkg install libxslt_devel
pkg install gsl

# lcms 1.x
archive_filename=lcms-1.19.tar.gz \
wtcmmi https://sourceforge.net/projects/lcms/files/lcms/1.19/lcms-1.19.tar.gz/download d5b075ccffc0068015f74f78e4bc39138bcfe2d4

LD_RUN_PATH=/opt/csw/lib:/opt/csw/gcc4/lib \
PKG_CONFIG_PATH=/opt/csw/lib/pkgconfig:/opt/csw/X11/lib/pkgconfig:/usr/local/lib/pkgconfig \
wtcmmi https://inkscape.org/en/gallery/item/7731/inkscape-0.48.0.tar.bz2 a2ab9b34937cc4f2b482c9b3720d8fd4dc7b12e8 LDFLAGS=-L/opt/csw/lib CPPFLAGS="-I/opt/csw/include -DSOLARIS_2_8"

fi

exit 0

## gcc-4.x

MPFR=mpfr-2.4.2
GMP=gmp-4.3.2
MPC=mpc-0.8.1

download_and_sha https://ftp.gnu.org/gnu/gmp/gmp-4.3.2.tar.bz2 2e0b0fd23e6f10742a5517981e5171c6e88b0a93c83da701b296f5c0861d72c19782daab589a7eac3f9032152a0fc7eff7f5362db8fccc4859564a9aa82329cf
download_and_sha https://ftp.gnu.org/gnu/mpfr/mpfr-2.4.2.tar.xz 1407793ff7b258f7fc893d80eccee5107a03ac72
download_and_sha https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz 14cb9ae3d33caed24d5ae648eed28b2e00ad047a8baeff25981129af88245b4def2948573d7a00d65c5bd34e53524aa6a7351b76703c9f888b41830c1a1daae2

# download_and_sha https://ftp.gnu.org/gnu/mpfr/mpfr-2.4.2.tar.xz 1407793ff7b258f7fc893d80eccee5107a03ac72 
# download_and_sha https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz b019d9e1d27ec5fb99497159d43a3164995de2d0


# wtcmmi https://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz b8be66396c726fdc36ebb0f692ed8a8cca3bcc66 --prefix=/usr/local/gcc48 --with-gmp=/opt/csw
# wtcmmi https://ftp.gnu.org/gnu/mpc/mpc-1.0.1.tar.gz 8c7e19ad0dd9b3b5cc652273403423d6cf0c5edf --prefix=/usr/local/gcc48 --with-gmp=/opt/csw

if false; then

GCC_DIR=gcc-4.6.4

mkdir -p $GCC_DIR
pushd $GCC_DIR

gtar xf ../gmp-4.3.2.tar.bz2
ln -sf gmp-4.3.2 gmp
gtar xf ../mpfr-2.4.2.tar.xz
ln -sf mpfr-2.4.2 mpfr
gtar xf ../mpc-0.8.1.tar.gz
ln -sf mpc-0.8.1 mpc

popd

wtcmmi https://ftp.gnu.org/gnu/gcc/gcc-4.6.4/gcc-4.6.4.tar.bz2 63933a8a5cf725626585dbba993c8b0f6db1335d --prefix=/usr/local/gcc46

fi

GCC_DIR=gcc-4.7.4

if [ ! -f installed-$GCC_DIR ]; then

mkdir -p $GCC_DIR
pushd $GCC_DIR

gtar xf ../gmp-4.3.2.tar.bz2
ln -sf gmp-4.3.2 gmp
gtar xf ../mpfr-2.4.2.tar.xz
ln -sf mpfr-2.4.2 mpfr
gtar xf ../mpc-0.8.1.tar.gz
ln -sf mpc-0.8.1 mpc

popd

fi

#wtcmmi https://ftp.gnu.org/gnu/gcc/gcc-4.8.5/gcc-4.8.5.tar.bz2 de144b551f10e23d82f30ecd2d6d0e18c26f8850 --prefix=/usr/local/gcc48
wtcmmi https://ftp.gnu.org/gnu/gcc/gcc-4.7.4/gcc-4.7.4.tar.bz2 f3359a157b3536f289c155363f1736a2c9b414db --prefix=/usr/local/gcc47 --enable-obsolete --enable-languages=c,c++

## inkscape

verify_binaries="gettext msgattrib msgcmp msgconv msgfmt msginit msgunfmt msgcat msgcomm msgen msgfilter msggrep msgmerge msguniq" \
wtcmmi https://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.8.1.tar.xz e0fe90ede22f7f16bbde7bdea791a835f2773fc9 LDFLAGS="-R/opt/csw/lib -R/opt/csw/gcc4/lib"

ensure_link /usr/local/bin/gmsgfmt /usr/local/bin/msgfmt

archive_filename=lcms2-2.9.tar.gz \
patch_before_configure="1" \
wtcmmi https://sourceforge.net/projects/lcms/files/lcms/2.9/lcms2-2.9.tar.gz/download 60bea9875e017dd1c466e988c2ad98f8766e4e55

wtcmmi https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz 228604686ca23f42e48b98930babeb5d217f1899
wtcmmi https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz e891c3193029775e83e0534ac0ee0c4c711f6d23


exit 0

#pkg install gnome
pkg install libxau_devel
pkg install libxcb_devel
pkg install libxdmcp_devel
pkg install x11_renderproto

# dead end; there is no g++ with C++11 that supports this system

# LD_RUN_PATH=/opt/csw/gcc4/lib \
LD_RUN_PATH=/usr/local/gcc47/lib \
PKG_CONFIG_PATH=/opt/csw/X11/lib/pkgconfig:/usr/local/lib/pkgconfig \
PATH=/usr/local/gcc47/bin:$PATH \
use_dirname=libsigc++-2.10.0 \
wtcmmi https://github.com/libsigcplusplus/libsigcplusplus/releases/download/2.10.0/libsigcplusplus-2.10.0.tar.xz 7807a12a1e90a98bd8c9440e5b312d3cb1121bf7 MAKE=gmake CXX=/usr/local/gcc47/bin/g++ CC=/usr/local/gcc47/bin/gcc

PKG_CONFIG_PATH=/opt/csw/X11/lib/pkgconfig:/usr/local/lib/pkgconfig \
wtcmmi https://www.cairographics.org/releases/cairomm-1.15.5.tar.gz 1234

PKG_CONFIG_PATH=/opt/csw/X11/lib/pkgconfig:/usr/local/lib/pkgconfig \
wtcmmi http://ftp.gnome.org/pub/GNOME/sources/glibmm/2.56/glibmm-2.56.0.tar.xz 6e74fcba0d245451c58fc8a196e9d103789bc510e1eee1a9b1e816c5209e79a9

LD_RUN_PATH=/opt/csw/lib \
PKG_CONFIG_PATH=/opt/csw/X11/lib/pkgconfig:/usr/local/lib/pkgconfig \
pre_configure_command=./autogen.sh \
wtcmmi https://inkscape.org/en/gallery/item/12187/inkscape-0.92.3.tar.bz2 063296c05a65d7a92a0f627485b66221487acfc64a24f712eb5237c4bd7816b2


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

