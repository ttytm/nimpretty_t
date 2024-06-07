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
	tabsFilter = &"#? replace(sub = \"\\t\", by = \"  \")\n"
	multiLineStringToken = "\"\"\""
	multiLineStringStartToken = [&"={multiLineStringToken}", &"discard{multiLineStringToken}"]
	debug = true # For now, just a manual debug switch.


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
	proc dbg(ident: string, value: string) =
		echo &"[DEBUG] {ident}: '{value}'"


proc isNimFile(path: string): bool =
	when debug: dbg("isNimFile", path)

	if not path.contains('.'):
		return false

	let ext = path.rsplit('.', maxsplit = 1)[1]
	return if ext.len < 3: false else: ext[0..2] == "nim"


proc parseArgs(): CLI =
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
				if lineLength == 0: (&"[Error] invalid line-length: '{rawLineLength}'").quit()
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
							(&"[Error] invalid indentation: '{rawIndentation}'").quit()
						let indentWidth = parseInt(rawIndentation)
						if indentWidth <= 0: (&"[Error] invalid indentation: '{rawIndentation}'").quit()
						result.indentation = spaces
						spaceNum = indentWidth
		inc(i)

	when debug: dbg("pathIdx", &"{pathIdx}")

	if pathIdx == 0 and argsN > 1:
		"[Error] no input file".quit(QuitFailure)

	# Handle paths.
	var hasInvalidPath = false
	for i in pathIdx..argsN:
		let arg = paramStr(i)
		if arg.startsWith("-"):
			(&"[Error] invalid option: {arg}").quit(QuitFailure)
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
	var spaceIndentedLines: seq[string]
	var isMultilineString = false
	for line in linesToFormat:
		# Handle multiline strings - preserve tabs.
		var l = line
		l.removeSuffix(' ')
		# Handle multiline strings - preserve spaces.
		if isMultilineString:
			spaceIndentedLines.add(l)
			if l.endswith(multiLineStringToken):
				isMultilineString = false
			continue
		else:
			let lNoSpaces = l.replace(" ", "")
			for t in multiLineStringStartToken:
				if lNoSpaces.contains(t): isMultilineString = true

		var indentLvl = 0
		while l[indentLvl..^1].startsWith("\t"):
			indentLvl += 1

		if indentLvl > 0:
			# Handle potential spaces after tabs.
			var formattedLine = spaceIndent & l[indentLvl..^1]
			formattedLine.removePrefix(' ')
			spaceIndentedLines.add(spaceIndent.repeat(indentLvl) & formattedLine)
		else:
			spaceIndentedLines.add(l)

	return spaceIndentedLines.join("\n") & "\n"


proc spacesToTabs(nimprettyFormattedPath: string): string =
	# Refines a nimpretty formatted file.
	let f = open(nimprettyFormattedPath)
	defer: f.close()

	var formattedLines: seq[string]
	var isMultilineString = false
	for l in f.lines:
		# Handle multiline strings - preserve spaces.
		if isMultilineString:
			formattedLines.add(l)
			if l.endswith(multiLineStringToken):
				isMultilineString = false
			continue
		else:
			let lNoSpaces = l.replace(" ", "")
			for t in multiLineStringStartToken:
				if lNoSpaces.contains(t): isMultilineString = true

		var indentLvl = 0
		while l[indentLvl * spaceNum..^1].startsWith(" "):
			indentLvl += 1

		if indentLvl > 0:
			formattedLines.add("\t".repeat(indentLvl) & l[indentLvl * spaceNum..^1])
		else:
			formattedLines.add(l)

	var res = formattedLines.join("\n")
	# In contrary to nimpretty classic, remove trailing linbreaks.
	# TEST: add test case to prevent regression.
	res.removeSuffix('\n')
	return res & "\n"


proc hasTabsIndent(inputLines: seq[string]): bool =
	for l in inputLines:
		if l != "":
			case l[0]
				of '\t': return true
				of ' ': return false
				else: continue


proc handleFile(app: var App, path: string) =
	when debug: dbg("handleFile", path)

	let input = readFile(path)
	let inputLines = input.split('\n')
	if inputLines.len <= 1:
		return

	let hasTabsFilter = inputLines[0].contains("#? replace(sub = \"\\t\", by = \" ")
	let inputToFormat = if hasTabsFilter: tabsToSpaces(inputLines[1..^1]) else: tabsToSpaces(inputLines)

	let tmpPath = tmpDir / extractFilename(path)
	writeFile(tmpPath, inputToFormat)
	defer: removeFile (tmpPath)

	let nimpretty_cmd = &"nimpretty --maxLineLen={app.cli.lineLength} --indent={spaceNum} {tmpPath}"
	when debug: dbg("nimpretty_cmd", nimpretty_cmd)
	if execCmd(nimpretty_cmd) != 0:
		echo &"[Error] failed to format file {tmpPath}"

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

	let res = if useTabs: tabsFilter & spacesToTabs(tmpPath) else: readFile(tmpPath)

	if not app.cli.write and not app.cli.diff and not app.cli.list:
		echo res

	if res == inputToFormat:
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
			echo &"[Error] failed to diff {path}"
		if app.cli.write:
			# Case: combining `diff` and `write`. E.g., `nimpretty_t -d -w <path>`
			moveFile(tmpPath, path)


proc handlePath(app: var App, path: string) =
	when debug: dbg("handlePath", path)
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
	when debug: dbg("main", $app)

	for p in app.cli.paths:
		app.handlePath(p)

	if app.hasDiff:
		quit()


main()
