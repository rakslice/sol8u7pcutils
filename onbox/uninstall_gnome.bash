#!/usr/bin/env bash
set -e
set -x

if false; then
	true
uninstall_thing libart_lgpl-2.3.21
uninstall_thing libgnome-2.10.1
uninstall_thing gnome-vfs-2.10.1
uninstall_thing gnome-mime-data-2.18.0
uninstall_thing GConf-2.10.1 
uninstall_thing libbonobo-2.8.1
uninstall_thing gtk+-2.6.10
fi
uninstall_thing pango-1.8.2
uninstall_thing atk-1.9.1
uninstall_thing glib-2.6.6
if false; then
uninstall_thing esound-0.2.41
uninstall_thing audiofile-0.2.6
fi
