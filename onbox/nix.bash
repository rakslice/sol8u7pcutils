source build_thing.bash

tgcpkg install bison

ensure_link "/usr/tgcware/bin/ln" "/usr/tgcware/bin/gln"
wtcmmi https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz fafece095a0d9890ebd618adb1f242d8908076e1 LDFLAGS="-R/usr/tgcware/lib"
sudo rm "/usr/tgcware/bin/ln"

tgcpkg install sqlite-devel
tgcpkg install curl-devel
tgcpkg install xzutils-devel

#before_configure="./autogen.sh" \
#use_dirname="libbrotli-libbrotli-1.0" \
#wtcmmi https://github.com/bagder/libbrotli/archive/libbrotli-1.0.tar.gz e55b63c89115646222a0387dc3c7e64d275b0c53 LDFLAGS="-R/usr/tgcware/lib"

#wtcmmi https://ftp.gnu.org/gnu/bc/bc-1.07.1.tar.gz b4475c6d66590a5911d30f9747361db47231640a  LDFLAGS="-R/usr/tgcware/lib"
wtcmmi https://ftp.gnu.org/gnu/bc/bc-1.06.tar.gz c8f258a7355b40a485007c40865480349c157292 LDFLAGS="-R/usr/tgcware/lib"

before_configure="./bootstrap" \
archive_filename="brotli-1.0.6.tar.gz" \
CONFIG_SHELL=/usr/tgcware/bin/bash \
wtcmmi https://github.com/google/brotli/archive/v1.0.6.tar.gz aa08a912bb560aa6def7b29d91ac6198a6b077f3 LDFLAGS="-R/usr/tgcware/lib"
#make_params="SHELL=/usr/tgcware/bin/bash" \

before_configure="/usr/local/bin/bash -e bootstrap.sh" \
archive_filename="nix-2.1.3.tar.gz" \
CONFIG_SHELL=/usr/tgcware/bin/bash \
wtcmmi https://github.com/NixOS/nix/archive/2.1.3.tar.gz 28d2ff8c42b6948f179300ebde3374d134abe143 --build=i386-pc-solaris2.6 --disable-doc-gen

