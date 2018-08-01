#!/usr/bin/env python

import sys
import os
import subprocess

def main():
	if len(sys.argv) < 2:
		print >> sys.stderr, "Usage:"
		print >> sys.stderr, "%s {image files}" % sys.argv[0]
		sys.exit(1)

	table_width = 8

	html_handle = open("index.html", "w")

	print >> html_handle, "<html><body><table><tr>"

	images_dir = "index_images"

	os.mkdir(images_dir)

	i = 0
	for filename in sys.argv[1:]:
		assert os.path.isfile(filename)
		filename_proper = os.path.basename(filename)
		filename_proper_without_ext = filename_proper.rsplit(".", 1)[0]
		filename_proper_png = filename_proper + ".png"

		output_filename = os.path.join(images_dir, filename_proper_png)

		try:
			subprocess.check_call(["convert", filename, output_filename])
		except:
			print "convert of %s failed" % filename_proper
			continue

		if i > 0 and i % table_width == 0:
			print >> html_handle, "</tr><tr>"
		print >> html_handle, "<td><img src=\"%s\"><br>%s</td>" % (output_filename, filename_proper)
		i += 1

	print >> html_handle, "</tr></table></html>"

	html_handle.close()
		

if __name__ == "__main__":
	main()
