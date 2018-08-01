#!/usr/bin/env python

import os, sys
import shlex

"""
Convert CDE front panel actions with commands to xdg menu application entries
"""


DT_PREFIX="/usr/dt"


SPECIAL_ACTIONS = ["FPOnItemHelp"]

IGNORE_APPMANAGER_ACTIONS = ["MediaSlice"]


DEBUG_MERGES = False
DEBUG_RAW_PARSE = False
DEBUG_CMD_PARSE = True


def xdg_exec_quote(args_list):
	parts = []
	quotables = ('\\', '"', '$')
	for arg in args_list:
		needs_quote = any(x in arg for x in quotables)
		if needs_quote:
			for ch in quotables:
				arg = arg.replace(ch, "\\" + ch)
			arg = '"%s"' % arg
		parts.append(arg)
	return " ".join(parts)


def choose_action_obj(action_obj, allow_fail=False):
	if type(action_obj) == list:
		# There is more than one entry with the same action name.
		# Try to choose the most appropriate one to use for the
		# purposes of the script (standalone xdg menu entries).
		#
		# For now, let's just take the first one we encounter 
		# that doesn't take any parameters.
		print "action_obj:"
		for entry in action_obj:
			print "  %r" % entry
		for cur_action_obj in action_obj:
			if "ARG_COUNT" not in cur_action_obj:
				if "ARG_TYPE" in cur_action_obj:
					continue
				else:
					action_obj = cur_action_obj
					break
			if cur_action_obj["ARG_COUNT"] == "0":
				action_obj = cur_action_obj
				break
		else:
			if allow_fail:
				return None
			assert False, "No suitable action_obj found"
	assert type(action_obj) != list
	return action_obj


def main():
	# Load the objects from the dtwm front panel configuration (dtwm.fp)
	obj_list, obj_index = load_fp()

	# Load all the dt types in the central CDE configuration
	dt_obj_list, dt_obj_index = load_all_dt()

	# Go through all the appmanager items 
	for action_name, app_path in enumerate_appmanager_items():
		if action_name in IGNORE_APPMANAGER_ACTIONS:
			continue

		if action_name not in dt_obj_index["ACTION"]:
			# We just didn't encounter an action definition with a name that corresponds to this
			# appmanager directory entry
			print >> sys.stderr, "appmanager action %s/%s not found" % (app_path, action_name)
			assert False

		action_obj = choose_action_obj(dt_obj_index["ACTION"][action_name], allow_fail=True)

		if action_obj is None:
			# There were actions by this name, but choose_action_obj() ruled them all out.
			# This action has no version for a run without parameters.
			# Just skip it.
			print >> sys.stderr, "appmanager action %s/%s had no suitable action" % (app_path, action_name)
			continue

		assert "LABEL" in action_obj, "appmanager action %s/%s doesn't have LABEL: %r" % (app_path, action_name, action_obj)
		label = action_obj["LABEL"]
		if "ICON" not in action_obj:
			# Just skip actions that don't have an icon for consistency with what we do
			# for front panel objects.
			# The xdg entry consumer we are targeting, launchy, traditionally just ignores
			# entries without an icon.
			# TODO Create an xdg menu entry with the placeholder/default action icon that
			# CDE would use
			continue
		icon_name = action_obj["ICON"]

		create_desktop_entry_for_action(action_name, action_obj, label, icon_name, dt_obj_index)
		

	# Go through all the front panel objects and create xdg menu items as appropriate
	for obj_type, ident, obj in obj_list:
		if all(x in obj for x in ("PUSH_ACTION", "ICON", "LABEL")):
			action_name, icon_name, label = obj["PUSH_ACTION"], obj["ICON"], obj["LABEL"]

			# Certain entries have well-known names that won't have a definition in the CDE config
			if action_name in SPECIAL_ACTIONS:
				# Just skip them
				continue

			print "action_name %r, icon_name %r, label %r" % (action_name, icon_name, label)
			print "icon obj %r" % obj

			# Look up the action associated with this front panel object
			action_obj = choose_action_obj(dt_obj_index["ACTION"][action_name], allow_fail=True)
			if action_obj is None:
				# choose_action_obj() found no appropriate action
				continue
			print "action obj %r" % action_obj
			assert not type(action_obj) == list

			create_desktop_entry_for_action(action_name, action_obj, label, icon_name, dt_obj_index)


def create_desktop_entry_for_action(action_name, action_obj, label, icon_name, dt_obj_index):
			# Choose a specific icon file for the given icon name
			icon_filename = find_icon(icon_name)

			# Traverse through 0 or more layers of map objects to get to the actual action
			while action_obj["TYPE"] == "MAP":
				mapped_action_name = action_obj["MAP_ACTION"]
				action_obj = choose_action_obj(dt_obj_index["ACTION"][mapped_action_name])
				print action_obj

			desc, wintype = action_obj.get("DESCRIPTION"), action_obj.get("WINDOW_TYPE")

			print "description %r" % desc

			action_type = action_obj["TYPE"]

			if action_type == "COMMAND":
				# The action is a command line.
				# Create an xdg menu item that just runs the command line
				cmd = action_obj["EXEC_STRING"]

				argc = action_obj.get("ARG_COUNT", "0")
				if argc == "0":
					# Preprocess the command line
					# 1. Replace any unnecessary parameter placeholders
					for i in xrange(8):
						param = "%Arg_" + str(i) + "%"
						cmd = cmd.replace(param, "")
					# 2. do normal command line splitting
					try:
						cmd_args_list = shlex.split(cmd)
					except ValueError:
						# There are stock Solaris CDE entries that are missing
						# a trailing close single quote, so try that.
						cmd_args_list = shlex.split(cmd + "'")
					if DEBUG_CMD_PARSE:
						print repr(cmd_args_list)
					# 3. do escaping of the split command line per XDG requirements
					cmd = xdg_exec_quote(cmd_args_list)
					# TODO implement support for running with different window type settings
					print "RUN COMMAND: %s" % cmd
					create_desktop_entry_content(label, icon_filename, cmd)
					print ""
					return

			if action_type == "TT_MSG":
				# The action is to send a ToolTalk message within CDE.
				# We can use the dtaction command to launch the action.
				# Create an xdg menu item that does this
				dtaction_cmd = os.path.join(DT_PREFIX, "bin", "dtaction")
				cmd = "%s %s" % (dtaction_cmd, action_name)
				print "RUN TT_MSG: %s" % cmd
				create_desktop_entry_content(label, icon_filename, cmd)
				print ""

			print "skipped action %s %s" % (action_name, action_type)
					

			print ""


def enumerate_appmanager_items():
	locale="C"

	appmanager_dir = os.path.join(DT_PREFIX, "appconfig", "appmanager", locale)

	assert not appmanager_dir.endswith(os.sep)
	appmanager_dir_prefix = appmanager_dir + os.sep

	for dirpath, dirnames, filenames in os.walk(appmanager_dir):
		if dirpath == appmanager_dir:
			path_within_appmanager = "/"
		else:
			assert dirpath.startswith(appmanager_dir_prefix), \
				"got appmanager folder dirpath %r not within %r" % (dirpath, appmanager_dir)
			path_within_appmanager = dirpath[len(appmanager_dir_prefix):]

		app_group_path = path_within_appmanager
		for filename in filenames:
			action_name = filename
			yield action_name, app_group_path
			

def find_icon(name):
	locale="C"

	# We will look in CDE's central icons directory
	icon_dir = os.path.join(DT_PREFIX, "appconfig", "icons", locale)

	cur_filename = os.path.join(icon_dir, "%s.pm" % name)
	if os.path.isfile(cur_filename):
		# There is a pm file with the exact name of the icon; just use it
		return cur_filename
	else:
		# No exact match; look for an icon with a size suffix.
		# Go through the icon sizes in the order we prefer them
		for size in "lmst":
			cur_filename = os.path.join(icon_dir, "%s.%s.pm" % (name, size))
			if os.path.isfile(cur_filename):
				return cur_filename
		assert False, "Icon %r not found" % name


def merge_obj_index(a, b):
	for obj_type, subdict in b.iteritems():
		obj_type_entries = a.setdefault(obj_type, {})
		for key, val in subdict.iteritems():
			if key in obj_type_entries:
				#print >> sys.stderr, "key collision during merge %r %r %r" % (obj_type, obj_type_entries.keys(), subdict.keys())
				print "key collision during merge %r" % obj_type
				if DEBUG_MERGES:
					print "BEFORE"
					print repr(obj_type_entries[key])
					print "CUR"
					print repr(val)
				assert obj_type == "ACTION"
				if type(obj_type_entries[key]) != list:
					obj_type_entries[key] = [obj_type_entries[key]]
				if type(val) != list:
					val = [val]
				obj_type_entries[key] += val
				if DEBUG_MERGES:
					print "AFTER"
					print repr(obj_type_entries[key])
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

			if DEBUG_RAW_PARSE:
				print "line %d: %s" % (line_num, line)
			try:
				first, rest = line.split(None, 1)
			except ValueError:
				first = ""
			if first == "set":
				name, val = rest.split("=", 1)
				file_globals[name.strip()] = val.strip()
				continue

			
			obj_type, identifier = line.split()
			if DEBUG_MERGES:
				print "** %s %s %s" % (filename, obj_type, identifier)

			obj_type_entries = objects_by_type_identifier.setdefault(obj_type, {})

			new_obj = {}

			if identifier not in obj_type_entries:
				obj_type_entries[identifier] = new_obj
			else:
				print >> sys.stderr, "%s:%d: Warning: duplicate %s identifier %s" % (filename, line_num, obj_type, identifier)
				if not isinstance(obj_type_entries[identifier], list):
					obj_type_entries[identifier] = [obj_type_entries[identifier]]
				obj_type_entries[identifier].append(new_obj)

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

				if DEBUG_RAW_PARSE:
					print "line %d: %s" % (line_num, line)
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
