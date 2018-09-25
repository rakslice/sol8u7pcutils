#!/usr/bin/env bash
set -e
set -x

function uninstall_things() {
	[ $# -eq 1 ]
	for f in ~/src/installed-"$1"-*; do
		filename_proper="$(basename "$f")"
		pkg="${filename_proper#installed-}"
		uninstall_thing "$pkg"
	done
}

uninstall_things libart_lgpl
uninstall_things libgnome
uninstall_things gnome-vfs
uninstall_things gnome-mime-data
uninstall_things GConf
uninstall_things libbonobo
uninstall_things gtk+
uninstall_things pango
uninstall_things atk
uninstall_things glib
uninstall_things esound
uninstall_things audiofile
