# status: working

need_util sed
function sed_patch() {
	[ $# -eq 4 ]
	filename="$1"
	always_pattern="$2"
	replace_pattern="$3"
	with_pattern="$4"	
	
	[ -f "$filename" ]
	grep "$always_pattern" "$filename" > /dev/null


	if grep "$replace_pattern" "$filename" > /dev/null; then
		sudo sed -i 's#'"$replace_pattern"'#'"$with_pattern"'#' "$filename"
	fi
}

function patch_pkgconfig_libs() {
	pkgconfig_file="$1"
	# modify pkgconfig_file to put -R option in libs for runtime library search path

	[ -f "$pkgconfig_file" ]
	grep '^Libs: ' "$pkgconfig_file" > /dev/null

	if grep 'Libs: -L${libdir}' "$pkgconfig_file" > /dev/null; then
		sudo sed -i 's/^Libs: -L${libdir}/Libs: -R${libdir} -L${libdir}/' "$pkgconfig_file"
	fi
}


wtcmmi https://ftp.gtk.org/pub/gtk/v1.2/glib-1.2.10.tar.gz e5a9361c594608d152d5d9650154c2e3260b87fa
patch_pkgconfig_libs /usr/local/lib/pkgconfig/glib.pc
patch_pkgconfig_libs /usr/local/lib/pkgconfig/gmodule.pc
patch_pkgconfig_libs /usr/local/lib/pkgconfig/gthread.pc
sed_patch /usr/local/bin/glib-config '' 'echo -L${exec_prefix}/lib ' 'echo -R${exec_prefix}/lib -L${exec_prefix}/lib'

wtcmmi https://ftp.gtk.org/pub/gtk/v1.2/gtk+-1.2.10.tar.gz a5adcb909257da01ae4d4761e1d41081d06e4d7c
patch_pkgconfig_libs /usr/local/lib/pkgconfig/gdk.pc
patch_pkgconfig_libs /usr/local/lib/pkgconfig/gtk+.pc
sed_patch /usr/local/bin/gtk-config '^glib_libs=' '^glib_libs=\"-L/usr/local/lib ' 'glib_libs=\"-R/usr/local/lib -L/usr/local/lib '
sed_patch /usr/local/bin/gtk-config '^glib_thread_libs=' '^glib_thread_libs=\"-L/usr/local/lib ' 'glib_thread_libs=\"-R/usr/local/lib -L/usr/local/lib '

#wtcmmi https://download.gimp.org/pub/gimp/v1.0/old/v1.0.0/gimp-1.0.0.tar.bz2 b602f0fa1fa916592cf3995fdaab71eafb412945 
# actually gimp-1.0.0 needs gtk 1.0 but we've already got gtk 1.2.x building; let's just use newer gimp
LD_RUN_PATH=/usr/local/lib:/usr/tgcware/lib \
wtcmmi https://download.gimp.org/pub/gimp/v1.2/v1.2.5/gimp-1.2.5.tar.bz2 1cb7fdbd4e6b191a62011c906e1b0aaef6e623ef LDFLAGS="-L/usr/local/lib -R/usr/local/lib -L/usr/tgcware/lib -R/usr/tgcware/lib" CPPFLAGS="-I/usr/local/include" --disable-print

