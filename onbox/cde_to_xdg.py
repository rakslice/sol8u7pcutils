#!/usr/bin/env python

import os, sys

"""
Convert CDE front panel actions with commands to xdg menu application entries
"""


DT_PREFIX="/usr/dt"


SPECIAL_ACTIONS = ["FPOnItemHelp"]

def main():

	
	obj_list, obj_index = load_fp()

	dt_obj_list, dt_obj_index = load_all_dt()

	for obj_type, ident, obj in obj_list:
		if all(x in obj for x in ("PUSH_ACTION", "ICON", "LABEL")):
			action_name, icon_name, label = obj["PUSH_ACTION"], obj["ICON"], obj["LABEL"]
			if action_name in SPECIAL_ACTIONS:
				continue
			icon_filename = find_icon(icon_name)
			print "action_name %r, icon_filename %r, label %r" % (action_name, icon_filename, label)
			print "icon obj %r" % obj

			action_obj = dt_obj_index["ACTION"][action_name]
			print "action obj %r" % action_obj

			while action_obj["TYPE"] == "MAP":
				mapped_action_name = action_obj["MAP_ACTION"]
				action_obj = dt_obj_index["ACTION"][mapped_action_name]
				print action_obj

			desc, wintype = action_obj.get("DESCRIPTION"), action_obj.get("WINDOW_TYPE")

			print "description %r" % desc

			if action_obj["TYPE"] == "COMMAND":
				cmd = action_obj["EXEC_STRING"]
				argc = action_obj.get("ARG_COUNT", "0")
				if argc == "0":
					print "RUN %r %s" % (wintype, cmd)
					create_desktop_entry_content(label, icon_filename, cmd)
					print ""
					continue

			if action_obj["TYPE"] == "TT_MSG":
				dtaction_cmd = os.path.join(DT_PREFIX, "bin", "dtaction")
				cmd = "%s %s" % (dtaction_cmd, action_name)
				print "RUNACTION %s" % cmd
				create_desktop_entry_content(label, icon_filename, cmd)
				print ""

			print "skipped action %s %s %r" % (obj_type, ident, obj)
					

			print ""


			
def find_icon(name):
	locale="C"
	icon_dir = os.path.join(DT_PREFIX, "appconfig", "icons", locale)

	cur_filename = os.path.join(icon_dir, "%s.pm" % name)
	if os.path.isfile(cur_filename):
		return cur_filename
	else:
		for size in "lmst":
			cur_filename = os.path.join(icon_dir, "%s.%s.pm" % (name, size))
			if os.path.isfile(cur_filename):
				return cur_filename
		assert False, name


def merge_obj_index(a, b):
	for obj_type, subdict in b.iteritems():
		obj_type_entries = a.setdefault(obj_type, {})
		for key, val in subdict.iteritems():
			if key in obj_type_entries:
				#print >> sys.stderr, "key collision during merge %r %r %r" % (obj_type, obj_type_entries.keys(), subdict.keys())
				print >> sys.stderr, "key collision during merge %r" % obj_type
			else:
				obj_type_entries[key] = val
			
	
def load_all_dt():
	locale="C"
	dt_dir = os.path.join(DT_PREFIX, "appconfig", "types", locale)

	obj_list = []
	obj_index = {}

	for filename_proper in os.listdir(dt_dir):
		if filename_proper.endswith(".dt"):
			filename = os.path.join(dt_dir, filename_proper)
			cur_list, cur_index = load_dtfile(filename)
			obj_list += cur_list

			merge_obj_index(obj_index, cur_index)

	return obj_list, obj_index


def load_fp():
	locale="C"
	fp_filename = os.path.join(DT_PREFIX, "appconfig", "types", locale, "dtwm.fp")
	return load_dtfile(fp_filename)


def breakout_char(tokens, char):
	out = []
	for token in tokens:
		s = token.split(char)
		if len(s) > 1:
			for i, sub_s in enumerate(s):
				if i > 0:
					out.append(char)
				if sub_s != "":
					out.append(sub_s)
		else:
			out.append(token)
	return out


assert breakout_char("now {{{is the { ti{me{{".split(), "{") == \
	["now", "{", "{", "{", "is", "the", "{", "ti", "{", "me", "{", "{"]


def breakout_chars(tokens, chars):
	for char in chars:
		tokens = breakout_char(tokens, char)
	return tokens
	

DUPE_FIELDS = ["ANIMATION", "CONTENT", "PATH_PATTERN"]	


def load_dtfile(filename):
	file_globals = {}

	objects_by_type_identifier = {}

	objects_list = []

	line_num = 0

	try:
	    with open(filename, "r") as handle:	
		while True:
			line = handle.readline()
			line_num += 1
			if line == "":
				break
			if "#" in line:
				pos = line.find("#")
				line = line[:pos]
			line = line.strip()
			if line == "":
				continue

			#print line
			try:
				first, rest = line.split(None, 1)
			except ValueError:
				first = ""
			if first == "set":
				name, val = rest.split("=", 1)
				file_globals[name.strip()] = val.strip()
				continue

			
			obj_type, identifier = line.split()

			obj_type_entries = objects_by_type_identifier.setdefault(obj_type, {})

			new_obj = {}

			if identifier not in obj_type_entries:
				obj_type_entries[identifier] = new_obj
			else:
				print >> sys.stderr, "%s:%d: Warning: duplicate %s identifier %s" % (filename, line_num, obj_type, identifier)

			objects_list.append((obj_type, identifier, new_obj))

			assert handle.readline().strip() == "{"
			line_num += 1

			while True:
				line = handle.readline().strip()
				line_num += 1
				if "#" in line:
					pos = line.find("#")
					line = line[:pos]
				if line == "":
					continue
				if line == "}":
					break

				while line.endswith("\\"):
					line = line[:-1] + handle.readline().strip()
					line_num += 1

				#print line
				key, value = line.split(None, 1)

				if key in DUPE_FIELDS:
					l = new_obj.setdefault(key, [])
					l.append(value)
				else:
					if key != "ACTIONS":
						assert key not in new_obj, "object field collision on %s: %r" % (key, line)
					new_obj[key] = value

	except:
	    print >> sys.stderr, "%s:%d:" % (filename, line_num)
	    raise
			
	return objects_list, objects_by_type_identifier


def create_desktop_entry_content(label, icon, cmd):
	output_filename = os.path.join(os.environ["HOME"], ".local", "share", "applications", label + ".desktop")
	with open(output_filename, "w") as handle:
		handle.write("""[Desktop Entry]
Categories=CDE
Exec=%s
GenericName=
Hidden=
Icon=%s
Name=%s
NoDisplay=
Type=Application
""" % (cmd, icon, label))


if __name__ == "__main__":
	main()
