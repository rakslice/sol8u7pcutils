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

ensure_link /usr/tgcware/bin/msgmerge /usr/tgcware/bin/gmsgmerge
ensure_link /usr/tgcware/bin/msgfmt /usr/tgcware/bin/gmsgfmt

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-desktop/2.10/gnome-desktop-2.10.2.tar.bz2 de8ba10bf7321b70ba5b3bdd45b61411b5a9fbd401fbe639041a875be01bd8f4 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
if false; then
# running into problems where pygtk install completes but doesn't give a working pygtk import

wtcmmi http://ftp.gnome.org/pub/gnome/sources/intltool/0.40/intltool-0.40.6.tar.bz2 4d1e5f8561f09c958e303d4faa885079a5e173a61d28437d0013ff5efc9e3b64 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

#wtcmmi http://ftp.gnome.org/pub/gnome/sources/pygobject/2.10/pygobject-2.10.1.tar.bz2 dff4a3e4a53c8190b2249e2fc7dd71258b2d6b2f65762aa59f5d56a52d53b86d LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/pygobject/2.11/pygobject-2.11.4.tar.bz2 e4b57c1e3947b9efd7bb632580cff6045a299a8c9cca2ea9a1a7984ee4a54807 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/pygobject/3.0/pygobject-3.0.4.tar.xz f457b1d7f6b8bfa727593c3696d2b405da66b4a8d34cd7d3362ebda1221f0661  LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/gnome-menus/2.9/gnome-menus-2.9.92.tar.bz2 8a9ec0a9ac4ecc91fa9dc9e8341c8f8b5e8b4018bf6663dab5c6d60064f23b38 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/gnome-menus/2.11/gnome-menus-2.11.92.tar.bz2 b7603afc7384e30d9cc2aa1603a8679bf9a5e07ab8aab1d5bc7d564cd5d0ccc8 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/gnome-menus/2.15/gnome-menus-2.15.91.tar.bz2 d0b5d71334dbd9cf9bc5b789833f64beed45d7d6234fb4d8dfcdbef5ef5a602b LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/gnome-menus/2.27/gnome-menus-2.27.92.tar.bz2 16d6d8d0af669feb0f24968a96ca4b9711e611e667efc49fef2ad3e0de475ea5 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/gnome-menus/2.91/gnome-menus-2.91.91.tar.bz2 79bd6a2b5ec048d811a39567ea22d623a37daf06f05a9ed0ac340b673a639452 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/gnome-menus/3.0/gnome-menus-3.0.1.tar.bz2 579c119c26f37781f66708e867ea45b3c37589b3b69e5b32d33e9bdb944165f0 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

ensure_link /usr/tgcware/bin/msgmerge /usr/tgcware/bin/gmsgmerge
ensure_link /usr/tgcware/bin/msgfmt /usr/tgcware/bin/gmsgfmt

ensure_link /usr/tgcware/bin/python2.5 /usr/tgcware/bin/python2.7

#wtcmmi https://www.cairographics.org/releases/pycairo-1.0.2.tar.gz 5bb6a202ebc3990712bced1da6dfb7a8 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
#wtcmmi https://www.cairographics.org/releases/pycairo-1.2.0.tar.gz ab531e02fda56a9d6b2b65153fda65f6 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

#wtcmmi http://ftp.gnome.org/pub/gnome/sources/pygtk/2.8/pygtk-2.8.6.tar.bz2 c69c2e5e86a8f21a5773df20e265fc3a   LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include --prefix=/usr/tgcware
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/pygtk/2.9/pygtk-2.9.6.tar.bz2 b41b00c6f6b20d594a62133417ac592a42d2f54e789c5778804b18bed84dd84e LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include --prefix=/usr/tgcware

wtcmmi http://ftp.gnome.org/pub/gnome/sources/alacarte/0.10/alacarte-0.10.2.tar.bz2 40955f7a0bac25da5d576fea015dd9b35f62033004b01bdc000885b337bfef3d LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/alacarte/0.11/alacarte-0.11.10.tar.bz2 3b405d3a5f59ff5dc90ade0be4f034a0fd66937994d3d7031a8ae33cd836d559
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/alacarte/0.12/alacarte-0.12.4.tar.bz2 f5bccd47d96b22ee73cf537d86bb90cb7b7e0f70ac68253fe512540e5bf64823
#wtcmmi http://ftp.gnome.org/pub/gnome/sources/alacarte/0.13/alacarte-0.13.4.tar.xz a45953dfbd799d718ebafe850c0b20e581827023e8da4ee906edb1f60d6a4098 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

fi

#source ${script_path}/gnome_resolver.bash

#LD_ALTEXEC=/usr/tgcware/bin/gld
#LD=/usr/tgcware/bin/gld
#auto_gnome_install gnome-terminal 2.10.0

tgcpkg install ncurses-devel

wtcmmi https://ftp.gnome.org/pub/gnome/sources/vte/0.11/vte-0.11.10.tar.bz2 71facdedd477749908402a6931d36e64 'LDFLAGS=-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib' CPPFLAGS="-I/usr/tgcware/include/ncurses"

wtcmmi https://ftp.gnome.org/pub/gnome/sources/gnome-terminal/2.10/gnome-terminal-2.10.0.tar.bz2 3d31faeedb9bb5d304d7d4f44e0f188df094d5f5776f91aaa90741d0cc7a3a26 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
