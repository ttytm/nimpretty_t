#? replace(sub = "\t", by = "  ")
# nimpretty_t - formatter and diff viewer utilizing nimpretty.
# Source: https://github.com/ttytm/nimpretty_t
# License: MIT

import std/[os, osproc, parsecfg, streams, strformat, strutils, parseutils]


const
# Relvant for usage.
	version = staticRead("../nimpretty_t.nimble").newStringStream.loadConfig.getSectionValue("", "version")
	envDiffCmd = "NIM_DIFF_CMD"
	helpMsg = """Usage: nimpretty_t [options] <path>...

Formatter and diff viewer utilizing nimpretty.
By default, formatted output is written to stdout.

Options:
  -w  --write           Modifies non-conforming files in-place.
  -l  --list            Prints paths of non-conforming files. Exits with an error if any are found.
  -d  --diff            Prints differences of non-conforming files. Exits with an error if any are found.
  -i  --indentation     Sets the indentation used [possible values: 'tabs', 'smart', '<num>'(spaces)].
                        - tabs: used by default.
                        - smart: based on the initial indentations in a file.
                        - <num>: number of spaces.
  -L  --line-length     Sets the max character line length. Default is 100.
  -h  --help            Prints this help information.
  -v  --version         Prints version information.

Environment Variables:
  NIM_DIFF_CMD          Sets a custom diff command that is used with the '-diff' option
                        E.g.: 'NIM_DIFFCMD="diff --color=always -U 2"'"""


# Relevant for internals.
	tabsFilter = &"#? replace(sub = \"\\t\", by = \"  \")"
	tabsFilterIndicator = tabsFilter.replace(" ", "") # Remove spaces for comparisons.
	multiLineStringTok = "\"\"\""
	multiLineStringStartIndicator = [&"={multiLineStringTok}", &"discard{multiLineStringTok}"]
	multiLineCommentStartTok = "#["
	multiLineCommentEndTok = "]#"
	debug = false # For now, just a manual debug switch.


let
	tmpDir = os.getTempDir() / "nimpretty_t"


var
	# Default indentation based on nim codebase.
	spaceNum = 2
	spaceIndent = " ".repeat(spaceNum)


type
	CLI = object
		write: bool
		list: bool
		diff: bool
		indentation: Indentation
		lineLength: uint16 = 100
		paths: seq[string]

	App = object
		cli: CLI
		hasDiff: bool
		diffCmd: string

	Indentation = enum tabs, smart, spaces


when debug:
	proc dbg(ident: string, value: string = "") =
		if value != "":
			echo &"[DEBUG] {ident}: '{value}'"
		else:
			echo &"[DEBUG] {ident} ---"


proc isNimFile(path: string): bool =
	let file = splitFile(path)
	when debug: dbg(">>> isNimFile: file", &"{file}")
	return if file.ext.len < 4: false else: file.ext[1..3] == "nim"


proc parseArgs(): CLI =
	when debug: dbg(">> parseArgs")

	# Using `result` directly will not use default values?
	result = CLI()

	let argsN = paramCount()

	if argsN == 0:
		helpMsg.quit(QuitSuccess)

	# Handle options.
	var pathIdx = 0
	var i = 1
	while i <= argsN:
		let arg = paramStr(i)
		if not arg.startsWith("-"):
			pathIdx = i
			break
		case arg
			of "-h", "--help":
				helpMsg.quit(QuitSuccess)
			of "-v", "--version":
				(&"nimpretty - Nim Pretty Printer Version {version}").quit(QuitSuccess)
			of "-w", "--write":
				result.write = true
			of "-d", "--diff":
				result.diff = true
			of "-l", "--list":
				result.list = true
			of "-L", "--line-length":
				inc(i)
				let rawLineLength = paramStr(i)
				var res: uint
				let lineLength = parseUInt(rawLineLength, res, 0)
				if lineLength == 0: quit(&"[Error] invalid line-length: '{rawLineLength}'")
				result.lineLength = uint16(lineLength)
			of "-i", "--indentation":
				inc(i)
				let rawIndentation = paramStr(i)
				case rawIndentation:
					of "tabs":
						result.indentation = tabs
					of "smart":
						result.indentation = smart
					else:
						var res: uint
						if parseUInt(rawIndentation, res, 0) == 0:
							quit(&"[Error] invalid indentation: '{rawIndentation}'")
						let indentWidth = parseInt(rawIndentation)
						if indentWidth <= 0: quit(&"[Error] invalid indentation: '{rawIndentation}'")
						result.indentation = spaces
						spaceNum = indentWidth
						spaceIndent = " ".repeat(spaceNum)
		inc(i)

	when debug: dbg(">> parseArgs: pathIdx", &"{pathIdx}")

	if pathIdx == 0 and argsN > 1:
		quit("[Error] no input file")

	# Handle paths.
	var hasInvalidPath = false
	for i in pathIdx..argsN:
		let arg = paramStr(i)
		if arg.startsWith("-"):
			quit(&"[Error] invalid option: '{arg}'")
		elif (not dirExists(arg) and not fileExists(arg)) or (fileExists(arg) and
				not isNimFile(arg)):
			echo &"[Error] invalid path: '{arg}'"
			hasInvalidPath = true
		else:
			result.paths.add(arg)

	if hasInvalidPath:
		quit()


proc tabsToSpaces(linesToFormat: seq[string]): string =
	# Converts tabs to spaces so that nimpretty won't refuse to do its magic.
	when debug: dbg(">>>> tabsToSpaces")

	# NOTE: `nimpretty` classic won't format first line comments, a space above
	# will make it behave. Ref.: `tests/testdata/first_line_comment.nim`
	var spaceIndentedLines = @[""]
	var isMultilineString = false
	var multilineCommentLvl = 0

	for l in linesToFormat:
		if l == "":
			spaceIndentedLines.add(l)
			continue

		# Keep track of current multiline comment state since it can be nested
		let isMultilineComment = multiLineCommentLvl > 0

		if not isMultilineComment:
			# Preserve indentation in multiline strings.
			if isMultilineString:
				spaceIndentedLines.add(l)
				if l.endswith(multiLineStringTok):
					isMultilineString = false
				continue

			let lNoSpaces = l.replace(" ", "")
			for t in multiLineStringStartIndicator:
				if lNoSpaces.contains(t): isMultilineString = true

		if not isMultilineString:
			# Preserve indentation in multiline comments.
			when debug:
				let mlcStarts = l.count(multilinecommentStartTok)
				let mlcEnds = l.count(multiLineCommentEndTok)
				dbg(">>>> tabsToSpaces: MLCOMMENT", &"LVL: {multiLineCommentLvl}, INC: {mlcStarts}, DEC: {mlcEnds}")
			if isMultilineComment:
				# Add line and continue loop if it already was a multiline comment.
				spaceIndentedLines.add(l)
				multilineCommentLvl += l.count(multilinecommentStartTok) - l.count(multiLineCommentEndTok)
				continue

			let lNoSpaces = l.replace(" ", "")
			if lNoSpaces.len > 1 and ((lNoSpaces[0] == '#' and lNospaces[1] == '[') or lNoSpaces[0] != '#'):
				let mlcStartToks = l.split(multilinecommentStartTok)
				if mlcStartToks.len > 1 and mlcStartToks[0].count("\"") mod 2 == 0:
					# Ensure the token is not part of a string.
					multilineCommentLvl += mlcStartToks.len - 1 - l.count(multiLineCommentEndTok)

		var indentLvl = 0
		while l[indentLvl..^1].startsWith("\t"):
			indentLvl += 1

		if indentLvl > 0:
			spaceIndentedLines.add(spaceIndent.repeat(indentLvl) & l.strip(trailing = false))
		else:
			spaceIndentedLines.add(l)

	# In contrary to nimpretty classic, remove trailing linebreaks.
	var res = spaceIndentedLines.join("\n")
	res.removeSuffix('\n')
	# Make sure the last line ends with `\n` - prevent "\ No newline at end of file" diffs.
	return res & "\n"


proc spacesToTabs(nimprettyFormattedPath: string): string =
	when debug: dbg(">>>> spacesToTabs")

	# Refines a nimpretty formatted file.
	let f = open(nimprettyFormattedPath)
	defer: f.close()

	var formattedLines: seq[string]
	var isMultilineString = false
	var multilineCommentLvl = 0

	for l in f.lines:
		if l == "":
			formattedLines.add(l)
			continue

		# Keep track of current multiline comment state since it can be nested
		let isMultilineComment = multiLineCommentLvl > 0

		if not isMultilineComment:
			# Preserve indentation in multiline strings.
			if isMultilineString:
				formattedLines.add(l)
				if l.endswith(multiLineStringTok):
					isMultilineString = false
				continue
			else:
				let lNoSpaces = l.replace(" ", "")
				for t in multiLineStringStartIndicator:
					if lNoSpaces.contains(t): isMultilineString = true

		if not isMultilineString:
			# Preserve indentation in multiline comments.
			if isMultilineComment:
				# Add line and continue loop if it already was a multiline comment.
				formattedLines.add(l)
				multilineCommentLvl += l.count(multilinecommentStartTok) - l.count(multiLineCommentEndTok)
				continue

			let lNoSpaces = l.replace(" ", "")
			if lNoSpaces.len > 1 and ((lNoSpaces[0] == '#' and lNospaces[1] == '[') or lNoSpaces[0] != '#'):
				let mlcStartToks = l.split(multilinecommentStartTok)
				if mlcStartToks.len > 1 and mlcStartToks[0].count("\"") mod 2 == 0:
					# Ensure the token is not part of a string.
					multilineCommentLvl += mlcStartToks.len - 1 - l.count(multiLineCommentEndTok)

		var indentLvl = 0
		while l[indentLvl * spaceNum..^1].startsWith(" "):
			indentLvl += 1

		if indentLvl > 0:
			formattedLines.add("\t".repeat(indentLvl) & l[indentLvl * spaceNum..^1])
		else:
			formattedLines.add(l)

	return formattedLines.join("\n") & "\n"


proc hasTabsIndent(inputLines: seq[string]): bool =
	for l in inputLines:
		if l != "":
			case l[0]
				of '\t': return true
				of ' ': return false
				else: continue


proc handleFile(app: var App, path: string) =
	when debug: dbg(">>> handeFile: path", path)

	let input = readFile(path)
	let inputLines = input.splitLines()
	if inputLines.len <= 1:
		return

	let hasTabsFilter = inputLines[0].replace(" ", "").contains(tabsFilterIndicator)
	let inputToFormat = if hasTabsFilter: inputLines[1..^1] else: inputLines

	let tmpPath = tmpDir / extractFilename(path)
	writeFile(tmpPath, tabsToSpaces(inputToFormat))
	defer: removeFile (tmpPath)

	let nimprettyCmd = &"nimpretty --maxLineLen={app.cli.lineLength} --indent={spaceNum} {tmpPath}"
	when debug: dbg(">>> handleFile: nimprettyCmd", nimprettyCmd)
	if execCmd(nimprettyCmd) != 0:
		quit(&"[Error] failed to format file '{path}'")

	let useTabs = case app.cli.indentation
		of tabs:
			true
		of smart:
			if hasTabsFilter or hasTabsIndent(inputLines[1..^1]):
				true
			else:
				false
		of spaces:
			false

	# Remove initial line break that was in `tabsToSpaces` to make nimpretty behave.
	let resNoFilter = (if useTabs: spacesToTabs(tmpPath) else: readFile(tmpPath)).substr(1)
	let res = if useTabs: tabsFilter & "\n" & resNoFilter else: resNoFilter

	if not app.cli.write and not app.cli.diff and not app.cli.list:
		echo res

	if resNoFilter == inputToFormat.join("\n"):
		return

	app.hasDiff = true

	if app.cli.list:
		echo path
	if app.cli.write and not app.cli.diff:
		writeFile(path, res)
	elif app.cli.diff:
		# PERF: Potential performance optimization for space usage related to writing a temporary result file.
		# While it is important that spaces work without problems, they are not a priority for optimizations.
		writeFile(tmpPath, res)
		let diffRes = execCmd(&"{app.diffCmd} {path} {tmpPath}")
		if diffRes != 0 and diffRes != 1:
			echo &"[Error] failed to diff '{path}'"
		if app.cli.write:
			# Case: `diff` and `write` were passed together.
			moveFile(tmpPath, path)


proc handlePath(app: var App, path: string) =
	when debug: dbg(">> handlePath: path", path)

	if dirExists(path):
		for v in walkDir(path):
			app.handlePath(v.path.replace("\\", "/"))
	elif isNimFile(path):
		app.handleFile(path)


proc init(): App =
	if not os.dirExists(tmpDir):
		os.createDir(tmpDir)

	result = App(cli: parseArgs())

	if result.cli.diff:
		let cmd = os.getEnv(envDiffCmd)
		if cmd != "":
			result.diffCmd = cmd
		else:
			var diffBin = "diff"
			when defined windows:
				diffBin &= ".exe"

			result.diffCmd = diffBin & " -d -a -U 2 --color=always"


proc main() =
	var app = init()
	when debug: dbg("> main: app", $app)

	for p in app.cli.paths:
		app.handlePath(p)

	if app.hasDiff and (app.cli.list or app.cli.diff):
		quit(QuitFailure)


main()
