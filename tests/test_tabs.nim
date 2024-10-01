#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, strutils, sequtils]
import utils


const tmpTestPath = utils.tmpTestPath / "tabs"


if not os.dirExists(tmpTestPath): os.createDir(tmpTestPath)
os.copyDir(testPath / "testdata", tmpTestPath)
utils.buildNimprettyT()


let paths = toSeq(walkPattern(tmpTestPath & "/*.nim"))
assert paths.len > 5

for _, p in paths:
	if p.endswith("_err.nim"):
		continue
	assert execCmd(&"{testExe} -w {p}") == 0
	let res = readFile(p)
	let expectPath = p & ".t.expect"
	let expected = readFile(expectPath)
	if res != expected:
		let (diff, _) = execCmdEx(&"diff -d -a -U 2 --color=always {p} {expectPath}")
		assert false, diff


os.removeDir(tmpTestPath)
