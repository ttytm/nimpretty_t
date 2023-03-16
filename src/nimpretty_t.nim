#? replace(sub = "\t", by = "  ")

# Source: https://github.com/tobealive/nimpretty_t
# License: MIT

# Features
# Run nimpretty when using the source code filter for tab indentation
# NOTE: Since source code filters usually block formatting for good reasons,
# other filters than the tab filter will still block nimpretty_t.

# Related Issue
# https://github.com/nim-lang/Nim/issues/9384

import os, osproc, re, strformat, strutils

const
	usage = "Usage: nimpretty_t [FILEPATH] [OPTIONS] [see nimpretty -h for valid options]"
	tempFilePath = getTempDir() & "nimpretty_t_temp.nim"

type
	Args = tuple[filePath: string, options: string]

proc handleArgs(): Args =
	# Require a filename as argument
	if paramCount() == 0:
		quit &"Error: no input file\n{usage}"

	let filePath = paramStr(1)

	let (_, _, ext) = splitFile(filePath)
	if ext != ".nim":
		quit "Error: input is not a Nim file"

	var options: string
	for i in 2..paramCount():
		options = &"{options} " & paramStr(i)

	result = (filePath: filePath, options: options)


proc hasTabFilter(filePath: string): bool =
	result = readLines(filePath, 1)[0].match(re("#\\?\\s*replace\\(sub *= *\"\\\\t\", *by *= *\" +\"\\)*$"))


proc tabsToSpaces(filePath: string): seq[string] =
	## Replace tabs with spaces. For temporary use to apply nimpretty.
	let f = open(filePath)
	defer: f.close()
	for line in f.lines:
		if line.match(re"^\t+"):
			let indentLvl = line.findBounds(re"^\t+")
			let formattedLine = "  ".repeat(indentLvl.last+1) & line[
					indentLvl.last+1..line.len - 1]
			result.add(formattedLine)
		else:
			result.add(line)


proc spacesToTabs(filePath: string): seq[string] =
	## Convert spaces back to tabs. For use after formatting.
	let f = open(filePath)
	defer: f.close()
	for line in f.lines:
		if line.match(re"^(  )+"):
			let indentLvl = line.findBounds(re"^(  )+")
			let formattedLine = "\t".repeat(((indentLvl.last+1)/2).int) & line[
					indentLvl.last+1..line.len-1]
			result.add(formattedLine)
		else:
			result.add(line)


proc writeLines(filePath: string, lines: seq[string]) =
	let f = open(filePath, fmWrite)
	defer: f.close()
	for line in lines:
		f.writeLine(line)


proc format(args: Args): seq[string] =
	let spaceIndentLines = tabsToSpaces(args.filePath)
	# Write temp file without first line (tab filter)
	writeLines(tempFilePath, spaceIndentLines[1..spaceIndentLines.len-1])

	# Run nimpretty
	if execCmd(&"nimpretty {args.options} {tempFilePath}") != 0:
		quit "Error: failed to format file"

	# Re-add previous tab filter to formetted lines
	result = spaceIndentLines[0] & spacesToTabs(tempFilePath)


proc main() =
	let args = handleArgs()

	# When no tab filter is used run nimpretty and exit
	if not hasTabFilter(args.filePath):
		if execCmd(&"nimpretty {args.options} {args.filePath}") != 0:
			quit "Error: failed to format file"
		quit(0)

	let formattedLines = format(args)
	writeLines(args.filePath, formattedLines)

	removeFile(tempFilePath)


main()


when isMainModule:
	block:
		const
			unformattedMock = @[
				"#? replace(sub = \"\\t\", by = \"  \")",
				"const",
				"\thello = \"Hello\"",
				"",
				"#                        ↓     ↓ ↓",
				"proc someProc(testInput:  string )=",
				"\tlet helloWorld = testInput & \" World\"",
				"\t#      ↓",
				"\tif true :",
				"\t\tif true:",
				"\t\t\techo helloWorld",
				"",
				"someProc(hello)",
			]
			formattedMock = @[
				"#? replace(sub = \"\\t\", by = \"  \")",
				"const",
				"\thello = \"Hello\"",
				"",
				"#                        ↓     ↓ ↓",
				"proc someProc(testInput: string) =",
				"\tlet helloWorld = testInput & \" World\"",
				"\t#      ↓",
				"\tif true:",
				"\t\tif true:",
				"\t\t\techo helloWorld",
				"",
				"someProc(hello)",
			]
			tempFile = getTempDir() & "unformatted_temp_file.nim"

		writeLines(tempFile, unformattedMock)

		let formattedResult = format((filePath: tempFile, options: ""))

		doAssert formattedResult != unformattedMock
		doAssert formattedResult == formattedMock

		removeFile(tempFile)


	block:
		const
			spaceIndentWithTabFilterMock = @[
				"#? replace(sub = \"\\t\", by = \"  \")",
				"const",
				"  hello = \"Hello\"",
				"",
				"proc someProc(testInput: string) =",
				"  let helloWorld = testInput & \" World\"",
				"  if true:",
				"    if true:",
				"      echo helloWorld",
				"",
				"someProc(hello)",
			]
			formattedMock = @[
				"#? replace(sub = \"\\t\", by = \"  \")",
				"const",
				"\thello = \"Hello\"",
				"",
				"proc someProc(testInput: string) =",
				"\tlet helloWorld = testInput & \" World\"",
				"\tif true:",
				"\t\tif true:",
				"\t\t\techo helloWorld",
				"",
				"someProc(hello)",
			]
			tempFile = getTempDir() & "space_indent_tab_filter_temp_file.nim"

		writeLines(tempFile, spaceIndentWithTabFilterMock)

		let formattedResult = format((filePath: tempFile, options: ""))

		doAssert formattedResult != spaceIndentWithTabFilterMock
		doAssert formattedResult == formattedMock

		removeFile(tempFile)
