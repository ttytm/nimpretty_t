
# Keep firstline space since formatting of first-ine comments is...

#[ when isMainModule:
	block:
			tempFile = getTempDir() & "unformatted_temp_file.nim"

removeFile(tempFile) ]#

# When the file has no tab source code filter, nimpretty classic
# won't preserve tabs in some multiline comments (example above)
# NOTE: prefer to file a bug report over fixing this internally.
