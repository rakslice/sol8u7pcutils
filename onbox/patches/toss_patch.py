#!/opt/csw/bin/python


# A utility to process a .patch file and take out sections that don't have any relevant changes

# For now, this is hardcoded with stuff for Qt


import errno
import optparse
import os
import sys


def die(msg):
	print >> sys.stderr, msg
	sys.exit(1)


def parse_args():
	parser = optparse.OptionParser()
	return parser.parse_args()	


def change_lines(section_lines):
	return [l for l in section_lines if (l.startswith("+") or l.startswith("-")) \
		and not (l.startswith("+++") or l.startswith("---"))]


IGNORE_MESSAGES=["Generated by qmake", "QMAKE_PRL_BUILD_DIR"]


def toss_patch(patch_filename):

	output_filename = patch_filename + ".temp"	

	with open(output_filename, "w") as output_handle:
		for filename, section_lines in sections(patch_filename):
			skip = False
			if filename.endswith("/Makefile"):
				continue
			if any(all(ignore_message in l for l in change_lines(section_lines)) for ignore_message in IGNORE_MESSAGES):
				continue
			output_handle.write("".join(section_lines))
	
	os.remove(patch_filename)
	os.rename(output_filename, patch_filename)


def sections(patch_filename):
	source_file_prefix = "--- "

	section_lines = []
	filename = None

	with open(patch_filename, "r") as handle:
		for line in handle:
			if line.startswith(source_file_prefix):
				prev_section_lines = section_lines[:-1]
				section_lines = section_lines[-1:]
				if filename is not None:
					yield filename, prev_section_lines
				filename = line[len(source_file_prefix):].split("\t", 1)[0]
			section_lines.append(line)
		yield filename, section_lines


def main():
	options, args = parse_args()
	if len(args) != 1:
		die("Usage: %s {patch_filename}" % sys.argv[0])
	patch_filename = args[0]
	
	try:
		toss_patch(patch_filename)
	except IOError, e:
		if e.errno == errno.ENOENT:
			die("File %s not found" % patch_filename)
		else:
			raise
		

if __name__ == "__main__":
	main()
