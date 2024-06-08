#? replace(sub = "\t", by = "  ")
discard """
  discard that works as a multiline comment.
	Or for unparsable, broken code

     Same as with classic `nimpretty`, indentation inside should not change.
		   ...
"""

#[
  This is a multiline comment.
  In Nim, multiline comments can be nested, beginning with #[
  ... and ending with ]#
]#

#[
	This is a multiline comment.
    In Nim, multiline comments can be nested, beginning with #[
		... and ending with ]#
]#

proc main() =
  let hello ="hello"
  echo hello


# nimpretty classic won't often won't preserve tabs in multiline comments (example below).
# NOTE: prefer to file a bug report over fixing this internally.

#[ when isMainModule:
	block:
			tempFile = getTempDir() & "unformatted_temp_file.nim"

removeFile(tempFile) ]#
