#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, strutils, sequtils]
import utils


const tmpTestPath = utils.tmpTestPath / "spaces"


if not os.dirExists(tmpTestPath): os.createDir(tmpTestPath)
os.copyDir(testPath / "testdata", tmpTestPath)
utils.buildNimprettyT()


let paths = toSeq(walkPattern(tmpTestPath & "/*.nim"))
assert paths.len > 5
for p in walkPattern(tmpTestPath & "/*.nim"):
	if p.endswith("_err.nim"):
		continue
	assert execCmd(&"{testExe} -w -i 4 {p}") == 0
	let res = readFile(p)
	let expectPath = p & ".s.expect"
	let expected = readFile(expectPath)
	if res != expected:
		let (diff, _) = execCmdEx(&"diff -d -a -U 2 --color=always {p} {expectPath}")
		assert false, diff


os.removeDir(tmpTestPath)
