ensure_link /usr/tgcware/bin/ln /usr/tgcware/bin/gln

noconfig=1 \
wtcmmi ftp://ftp.gnome.org/pub/GNOME/sources/gnome-audio/2.22/gnome-audio-2.22.2.tar.bz2 2f870f822360d22d857548e549b600ca74511e060754e1dca8e3f8ec40210c8c LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

sudo rm /usr/tgcware/bin/ln

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/librsvg/2.11/librsvg-2.11.1.tar.bz2 55b6ce75d0526ddf53006ab6838ccc5eb4a04736b7f52d2df081296f4a6e3ac7 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

configure_subdir=build_unix \
configure_name=../dist/configure \
wtcmmi https://src.fedoraproject.org/lookaside/pkgs/db4/db-4.7.25.tar.gz/ec2b87e833779681a0c3a814aa71359e/db-4.7.25.tar.gz ec2b87e833779681a0c3a814aa71359e CC=gcc

#wtcmmi https://ftp.gnu.org/gnu/guile/guile-2.2.4.tar.xz d2ee223fdb7570b68469e339a7074d1d LDFLAGS="-R/usr/local/lib"
wtcmmi https://ftp.gnu.org/gnu/guile/guile-1.6.8.tar.gz 5c244f730d7aaee32db4b0cc77b688f74a5caa71 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

#wtcmmi http://ftp.gnome.org/pub/gnome/sources/gnome-libs/1.4/gnome-libs-1.4.2.tar.bz2 6111e91b143a90afb30f7a8c1e6cbbd6 
#LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

#wtcmmi http://ftp.gnome.org/pub/gnome/sources/gnome-guile/0.20/gnome-guile-0.20.tar.gz eb595645a1fb5ad52fd467e8fe5217d839f59767936406c679ea7a35a0ce2ae2 
#LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

# NB: To avoid c++ linker errors ultimately I just put the full path to libstdc++.so.6 up front in the LDFLAGS

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-games/2.10/gnome-games-2.10.2.tar.bz2 81d8eef77582f923c63e1cdef5ee0c25fb92837f61ec47562c0e8825b5aa28e0 LDFLAGS="/usr/tgcware/lib/libstdc++.so.6 -R/usr/tgcware/lib -L/usr/tgcware/lib -R/usr/local/lib -R/usr/ucblib" 
#CPPFLAGS="-D_POSIX_SOURCE=1"
#wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-games/2.10/gnome-games-2.10.2.tar.bz2 81d8eef77582f923c63e1cdef5ee0c25fb92837f61ec47562c0e8825b5aa28e0 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib -L/usr/tgcware/lib" CPPFLAGS=-I/usr/local/include 

# too new, missing some deps
#wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-calculator/3.7/gnome-calculator-3.7.92.tar.xz c2c05d77a90f3f563a3042d955ac039dab8d98d7987c08379d37d7c156cbe72b LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-desktop/2.10/gnome-desktop-2.10.2.tar.bz2 de8ba10bf7321b70ba5b3bdd45b61411b5a9fbd401fbe639041a875be01bd8f4 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
