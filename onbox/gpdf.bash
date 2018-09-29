# status: working

tgcpkg install gettext-devel

wtcmmi https://sourceforge.net/projects/libpng/files/libpng12/1.2.59/libpng-1.2.59.tar.xz 4376e9ae6cf23efe63975067c4f135ff1777671a --disable-static LDFLAGS="-R/usr/tgcware/lib"

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/audiofile/0.2/audiofile-0.2.6.tar.bz2 c2a8965a6ea4a8db4c92cd7d3214c741de8d7c4a4a7ac98c76d48dde61e200b4 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/esound/0.2/esound-0.2.41.tar.bz2 5eb5dd29a64b3462a29a5b20652aba7aa926742cef43577bf0796b787ca34911 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

#wtcmmi https://ftp.gnome.org/pub/GNOME/sources/glib/2.6/glib-2.6.6.tar.bz2 de4f25424840b8e3b1fb03e6bac0c095affc3ca9c228f8b780817489914bdebf 

tgcpkg install libiconv-devel

ensure_link /usr/tgcware/bin/iconv /usr/tgcware/bin/giconv

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/glib/2.10/glib-2.10.3.tar.bz2 1d3700e35ca7240a9ce28cf222429648ea50271d62524e008191ccd04a3f8f6f LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include --with-libiconv=gnu

#wtcmmi https://ftp.gnome.org/pub/gnome/sources/atk/1.1/atk-1.1.5.tar.bz2 961c757e1b819566af0e87ea772849182d4c41f8c01457e4ae42e0ca03f2fa99 LDFLAGS="-R/usr/tgcware/lib -R/usr/local/lib"
wtcmmi https://ftp.gnome.org/pub/GNOME/sources/atk/1.9/atk-1.9.1.tar.bz2 65732d71c6c02e957673f49f8c5818f2cad3f451116b58ab1636c73dc8ab0dc6 LDFLAGS="-R/usr/tgcware/lib -R/usr/local/lib"

wtcmmi https://xlibs.freedesktop.org/release/render-0.8.tar.gz 73b88307fd318e0a1a7ed50c7cf7808d550cca99
wtcmmi https://xlibs.freedesktop.org/release/xrender-0.8.3.tar.gz a99c1c395b86b2fc4a92bd6de750e1438a5f3461

##wtcmmi https://xlibs.freedesktop.org/release/xft-2.1.2.tar.gz 892d57cac909ef51c3c49b9a6aaf54e6b6ab6b92 --with-x-includes=/usr/openwin/include --with-x-libraries=/usr/openwin/lib

#wtcmmi https://xlibs.freedesktop.org/release/libXft-2.1.7.tar.bz2 bba656ae9bada7176517275f17738dc9932edf78 --with-x-includes=/usr/openwin/include --with-x-libraries=/usr/openwin/lib

wtcmmi https://www.x.org/releases/individual/lib/libXft-2.1.8.2.tar.bz2 2f0141e25ac82ce672f2b10e4f60e5d1f9bb8622

wtcmmi https://xlibs.freedesktop.org/release/xproto-6.6.2.tar.bz2 f8f82255af3b15bdc5e9766eeebf8d696b8d8215

wtcmmi https://www.cairographics.org/releases/cairo-1.0.4.tar.gz 89e72202e5b51a8914fce60f52f7c51ecdea982a  LDFLAGS="-R/usr/tgcware/lib -R/usr/local/lib" CPPFLAGS="-I/usr/local/include"

#wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/pango/1.8/pango-1.8.2.tar.bz2 4cf04489ff291f3f1835783b8cfa8347d99f6a05d7d9da21c8d737f441bea3ac LDFLAGS="-R/usr/tgcware/lib -R/usr/local/lib"
#wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/pango/1.9/pango-1.9.1.tar.bz2 97cc77b93ce65e4f138e284f799c9ae7153b6f81720553c3c120b7317692b537 LDFLAGS="-R/usr/tgcware/lib -R/usr/local/lib"

wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/pango/1.10/pango-1.10.4.tar.bz2 c2e92e373e374c730a11dbe9a3d2ada01a20e6973863debfaf6f7295002e6b25 LDFLAGS="-R/usr/tgcware/lib -R/usr/local/lib" CPPFLAGS="-I/usr/local/include"

#wtcmmi https://ftp.gnome.org/pub/gnome/sources/gtk+/2.5/gtk+-2.5.6.tar.bz2 b139f0b8747af150203fcede5528eb8033259db0395deb2114d5cd943f91f2ff LDFLAGS="-R/usr/tgcware/lib -R/usr/local/lib -L/usr/local/lib" CPPFLAGS="-I/usr/local/include"
#wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gtk+/2.6/gtk+-2.6.10.tar.bz2 d408b606c8dd414dfbf220ccc168a0bc85a419945439796792a5357a96ff02af LDFLAGS="-R/usr/tgcware/lib -R/usr/local/lib -L/usr/local/lib" CPPFLAGS="-I/usr/local/include"
CONFIG_SHELL=/usr/tgcware/bin/bash wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gtk+/2.8/gtk+-2.8.20.tar.bz2 69a9b6c1e78da7e71416f20fab0c4972503139406e89ce7fbdbac0e213b16b79 LDFLAGS="-R/usr/tgcware/lib -R/usr/local/lib -L/usr/local/lib" CPPFLAGS="-I/usr/local/include"

#wtcmmi https://sourceforge.net/projects/expat/files/expat/2.0.1/expat-2.0.1.tar.gz 663548c37b996082db1f2f2c32af060d7aa15c2d LDFLAGS="-R/usr/tgcware/lib"
tgcpkg install expat-devel

tgcpkg install perl
sudo cpan App::cpanminus
sudo cpanm install XML::Parser

wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/libIDL/0.8/libIDL-0.8.14.tar.bz2 c5d24d8c096546353fbc7cedf208392d5a02afe9d56ebcc1cccb258d7c4d2220 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib"

need_util xgettext

#wtcmmi http://rpm5.org/files/popt/popt-1.10.4.tar.gz 10e6649c4c37ecfb6fb4296aeca609b5fdd5e34d LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib" --disable-nls
#wtcmmi http://rpm5.org/files/popt/popt-1.16.tar.gz 3743beefa3dd6247a73f8f7a32c14c33 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib"
wtcmmi http://ftp.sunet.se/mirror/archive/ftp.sunet.se/pub/vendor/sun/freeware/SOURCES/popt-1.14.tar.gz af0a7e2b187d600d624515a53d88374c15104e15 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib"

wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/ORBit2/2.12/ORBit2-2.12.5.tar.bz2 dc6d9c22875b178ed26103b445e6c937a7120225de581ca56d3865c069722591 LDFLAGS="-R/usr/local/lib -L/usr/local/lib -R/usr/tgcware/lib" CPPFLAGS="-I/usr/local/include"

#wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/libbonobo/2.10/libbonobo-2.10.1.tar.bz2 7799f889eeea4cd0758be9dd37a85e135f1b0c8e1b6042ddea75a79ba6caebb0 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib"
wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/libbonobo/2.8/libbonobo-2.8.1.tar.bz2 a7a6f0f5d31b8c28c2a34e870643e5eb483dce1bfbd1e796acf6410f940774df  LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/GConf/2.10/GConf-2.10.1.tar.bz2 319cf475ebe96d974beda572f53528b2bbd4bb9a085aca9f843458689ecdc9c1 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

tgcpkg install bzip2-devel

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-mime-data/2.18/gnome-mime-data-2.18.0.tar.bz2 37196b5b37085bbcd45c338c36e26898fe35dd5975295f69f48028b1e8436fd7 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib"

wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/gnome-vfs/2.10/gnome-vfs-2.10.1.tar.bz2 1243af76431c2850386204eb9f4947bca3708744cccf05602aaf476d956eec7d LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/libgnome/2.10/libgnome-2.10.1.tar.bz2 9cf2d20f528470b2fc7995aea314c5898fad654fde265880002de0669b869c27 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/libart_lgpl/2.3/libart_lgpl-2.3.21.tar.bz2 fdc11e74c10fc9ffe4188537e2b370c0abacca7d89021d4d303afdf7fd7476fa LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

#wtcmmi https://ftp.gnome.org/pub/GNOME/sources/libglade/2.5/libglade-2.5.1.tar.bz2 15e4c95402caa3c97394189a6b1b693eced23d80e292fcca12585317434adc2e 
#wtcmmi https://ftp.gnome.org/pub/GNOME/sources/libglade/2.6/libglade-2.6.4.tar.bz2 64361e7647839d36ed8336d992fd210d3e8139882269bed47dc4674980165dec 
#wtcmmi https://ftp.gnome.org/pub/GNOME/sources/libglade/2.6/libglade-2.6.3.tar.bz2 ee9ffee149523aac49ddff37c0fbaa968b6ff9787fa841d65a7084201e46ab90 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/libglade/2.6/libglade-2.6.4.tar.bz2 64361e7647839d36ed8336d992fd210d3e8139882269bed47dc4674980165dec LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/libgnomecanvas/2.10/libgnomecanvas-2.10.2.tar.bz2 82e7700a83aa203afc0c8903642546945b66472c66950cfc443f807b629ecc5a LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

tgcpkg install libgpg-error-1.6
tgcpkg install libgpg-error-devel

tgcpkg install binutils

LD_ALTEXEC=/usr/tgcware/bin/gld wtcmmi https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.2.4.tar.bz2 c72406c69d6ad9fb3fa1e9824b04566cf204093b LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include LD=/usr/tgcware/bin/gld

#wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-keyring/2.19/gnome-keyring-2.19.91.tar.bz2 fd63bd8075b9842794beee18c08aed748efeed586629212ace99de4ad88bc422 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include 
#wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-keyring/2.20/gnome-keyring-2.20.3.tar.gz b7c3143f7041d2a1fef95ebb0fff3520cb31f87b200137d886a127970838e8bb LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

# Overriding shell because we're hitting ksh segfaults in some libtool runs
make_params="SHELL=/usr/tgcware/bin/bash" \
wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-keyring/0.7/gnome-keyring-0.7.92.tar.bz2 4c34f76b11b1b12781dbd924863ddbc09cef853f465225b38638246a180c044f LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/libbonoboui/2.10/libbonoboui-2.10.1.tar.bz2 7b1eb566f2485a97d3c3f2ab507b1b3112fce93ea588a8675e62da3ef6e17b40 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.acc.umu.se/pub/gnome/sources/libgnomeui/2.10/libgnomeui-2.10.1.tar.bz2 956a28baf43ed80b4e6eab7d2975e3c83aec018d32c894cbb165835858300353 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/libgnomeprint/2.10/libgnomeprint-2.10.3.tar.bz2 69a1f7e2b17ac2e27cdcf123189f59f7d5726864ec0c2d1309b57a28fe4df56a LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include


wtcmmi https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.17.tar.xz 192d95efc13adf1fd35442d086733df25826cf2c

ensure_link /usr/tgcware/bin/ln /usr/tgcware/bin/gln

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/gnome-icon-theme/2.10/gnome-icon-theme-2.10.1.tar.bz2 ae4b394a3f9a7438d2a274d4b2da5bb0f0848a4dc8aebc548fe16b0133a3cf91 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

sudo rm /usr/tgcware/bin/ln

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/libgnomeprintui/2.10/libgnomeprintui-2.10.2.tar.bz2 27cccff2586d8fdff466edda32ce750630516eb93406e2c845db8bb3fb680fb3 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/libxslt/1.1/libxslt-1.1.22.tar.bz2 a0bf35d48d1a744482309b0d5190f15967684b935195fe3f06f29878be838c91 LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

wtcmmi https://ftp.gnome.org/pub/GNOME/sources/scrollkeeper/0.3/scrollkeeper-0.3.14.tar.gz 4a0bd3c3a2c5eca6caf2133a504036665485d3d729a16fc60e013e1b58e7ddad LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib -L/usr/tgcware/lib" CPPFLAGS=-I/usr/local/include

noconfig=1 \
wtcmmi http://scrollkeeper.sourceforge.net/data/docbookx412.tgz 8f1039973ae4eb43312c11d50d140c3d0388a45a

noconfig=1 \
wtcmmi http://scrollkeeper.sourceforge.net/data/docbook-xsl-1.48.tgz 19143793f80f67979a8c0435ed8506b036ef454b

function gpdf_remove_omf_timestamps() {
	sudo rm help/*/omf_timestamp
}

before_configure=gpdf_remove_omf_timestamps \
wtcmmi http://ftp.acc.umu.se/pub/GNOME/sources/gpdf/2.10/gpdf-2.10.0.tar.gz 7dd023f970d88d0a8e86dea1b31939f9d8be9c82319b5be31fb1c14fdb8108ef LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include

