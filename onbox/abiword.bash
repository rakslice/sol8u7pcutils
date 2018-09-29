source ./build_thing.bash

source ${script_path}/gnome_resolver.bash

#auto_gnome_install fribidi 0.10.4

wtcmmi https://ftp.osuosl.org/pub/blfs/conglomeration/fribidi/fribidi-1.0.5.tar.bz2 39d2bcb3ef93365222e7cdaf648cd167785ec3bf LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

auto_gnome_install libgsf 1.13.99

function configure_wv() {
	pushd ../wv
	CC=gcc ./configure
	popd
}

patch_before_configure=1 \
configure_subdir=abi \
before_configure=configure_wv \
wtcmmi http://ftp.gnome.org/pub/gnome/sources/abiword/2.3/abiword-2.3.4.tar.bz2 38aba7226c2df3453cb9532c07e8d15614925c6f846f6d951108c601bbf8790e LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib /usr/tgcware/lib/libstdc++.so.6 -lpangoxft-1.0" CPPFLAGS=-I/usr/local/include CXXFLAGS=-Wno-long-long

