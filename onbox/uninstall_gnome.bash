#!/usr/bin/env bash
set -e
set -x

function uninstall_things() {
	[ $# -eq 1 ]
	if ls ~/src/installed-"$1"-* > /dev/null; then
	for f in ~/src/installed-"$1"-*; do
		filename_proper="$(basename "$f")"
		pkg="${filename_proper#installed-}"

		if [ "$pkg" == "gtk+-1.2.10" ] || [ "$pkg" == "glib-1.2.10" ]; then
			continue
		fi
		uninstall_thing "$pkg"
	done
	fi
}

uninstall_things gnome-keyring
uninstall_things libgcrypt
uninstall_things libgnomecanvas
uninstall_things libglade
uninstall_things libart_lgpl
uninstall_things libgnome
uninstall_things gnome-vfs
uninstall_things gnome-mime-data
uninstall_things GConf
uninstall_things libbonobo
uninstall_things gtk+
uninstall_things pango
uninstall_things cairo
uninstall_things atk
uninstall_things glib
uninstall_things esound
uninstall_things audiofile
if false; then
true
fi
