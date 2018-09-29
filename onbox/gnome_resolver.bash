#!/usr/bin/env bash 
set -e -x
set -o pipefail

GNOME_MIRROR=https://ftp.gnome.org/pub/gnome/sources
GNOME_MIRROR_UNSECURE=http://ftp.gnome.org/pub/gnome/sources

function first_char() {
	echo "$1" | cut -c1
}

function pkg_name_map() {
	case "$1" in
		libgnome-menu )
			echo "gnome-menus"
			;;
		*)
			echo "$1"
			;;
	esac
}

function get_first_param() {
	while read line; do
	if [ "$(first_char "$line")" == "\"" ]; then
		echo "$line" | sed 's/"\(.*\)".*/\1/'
	else
		echo "$line" | awk '{print $1}'
	fi
	done
}

function get_gnome_deps() {
	deps_filename="${script_path}/$(basename "$1").deps"
	if [ -f "$deps_filename" ]; then
		echo $(cat "$deps_filename")
	else
	
	dirname="$1"
	[ -d "$1" ]
	configure_filename="$1/configure"
	[ -f "$configure_filename" ]
	grep 'PKG_CONFIG --exists'  "$configure_filename" | gsed 's/.*PKG_CONFIG --exists \(.*\)/\1/' | get_first_param

	fi
}

function pop_resolver_stack() {
                ghead -n -1 ${script_path}/gnome_resolver_stack > ${script_path}/gnome_resolver_stack.new
                rm ${script_path}/gnome_resolver_stack
                mv ${script_path}/gnome_resolver_stack.new ${script_path}/gnome_resolver_stack
}

function auto_gnome_install() {
	[ $# -eq 2 ]

	pkg_name_proper="$1"
	min_version_requirement="$2"

	if [ -f ~/src/installed-${pkg_name_proper}-${min_version_requirement} ]; then
		return
	fi


	pkg_name=${pkg_name_proper}-${min_version_requirement}
	echo $pkg_name

	major_minor=$(echo "$min_version_requirement" | python -c 'import sys; print ".".join(sys.stdin.readline().split(".")[:2])')

	major_minor_url="$GNOME_MIRROR/$pkg_name_proper/$major_minor"

	wget $major_minor_url -O /tmp/sources-dir-listing

	found_filename=""	
	for candidate in "$pkg_name.tar.bz2" "$pkg_name.tar.xz" "$pkg_name.tar.gz"; do
		if grep "$candidate" /tmp/sources-dir-listing > /dev/null; then
			found_filename="$candidate"
			break
		fi
	done

	[ "$found_filename" != "" ]

	candidate_url="$major_minor_url/$found_filename"

	hashfile=""
	for hashfile_candidate in $pkg_name.sha256sum $found_filename.md5; do
		if grep "$hashfile_candidate" /tmp/sources-dir-listing > /dev/null; then       
			hashfile="$hashfile_candidate"
                        break                                                  
                fi                                 
        done      

	wget $major_minor_url/$hashfile_candidate -O /tmp/sources-hashfile
	grep "$found_filename" /tmp/sources-hashfile

	hash=$(grep "$found_filename" /tmp/sources-hashfile | gawk '{print $1}')

	echo ~/"src/$pkg_name" >> ${script_path}/gnome_resolver_stack

	wtcmmi "$candidate_url" "$hash" LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include
	echo wtcmmi "$candidate_url" "$hash" LDFLAGS="-R/usr/local/lib -R/usr/tgcware/lib -L/usr/local/lib" CPPFLAGS=-I/usr/local/include >> ${script_path}/gnome_resolver_installs

	pop_resolver_stack

}

function extract_fill_line_requirement() {
	pkg_spec="$1"
	line="$2"

	if echo "$line" | grep "$pkg_spec >= \([^ ]*\)" > /dev/null; then
		min_version_requirement="$(echo "$line" | gsed 's/.*'"$pkg_spec"' >= \([^ ]*\).*/\1/')"
	elif echo "$line" | grep "$pkg_spec > \([^ ]*\)" > /dev/null; then
		min_version_requirement="$(echo "$line" | gsed 's/.*'"$pkg_spec"' > \([^ ]*\).*/\1/')"
	else
		echo "Can't recover version from $line"
		exit 1
	fi

	if [ "$min_version_requirement" != "" ]; then

		if echo "$pkg_spec" | egrep '^.*-[0-9.]+$' > /dev/null; then
			pkg_name_proper="$(echo "$pkg_spec" | python -c 'import sys; print sys.stdin.readline().rsplit("-", 1)[0]')"
		else
			pkg_name_proper="$pkg_spec"
		fi
		pkg_name_proper=$(pkg_name_map "$pkg_name_proper")

		auto_gnome_install $pkg_name_proper $min_version_requirement

		exit 1
	fi
}

function fill_requirements() {
	line="$1"
	# remove vars
	line="$(echo "$line" | sed 's/$[^ ]*//g')"
	echo "CHECKING"
	pkg-config --exists $line --print-errors 2> /tmp/pkg-config-errors || (
		if grep 'Package .* was not found in the pkg-config search path' /tmp/pkg-config-errors; then
			pkg_spec="$(grep Package /tmp/pkg-config-errors | sed 's/.*Package \(.*\) was not found in the pkg-config search path.*/\1/')"
			echo "failing constraint was on $pkg_spec"
			extract_fill_line_requirement "$pkg_spec" "$line"
		else
			echo "Unknown error kind:"
			cat /tmp/pkg-config-errors
			exit 1
		fi
		exit 1
	)
	echo "line passed: $line"
}


function check_gnome_deps() {

	get_gnome_deps "$1" | (while read line; do
		fill_requirements "$line"
	done)

	echo "got all the deps for $1"

	pop_resolver_stack
}



function do_gnome_resolve() {

	if [ $# -gt 0 ]; then
		echo "$1" >> ${script_path}/gnome_resolver_stack
	fi

	last_item="$(gtail -n 1 ${script_path}/gnome_resolver_stack)"
	echo $last_item
	check_gnome_deps "$last_item"

}

