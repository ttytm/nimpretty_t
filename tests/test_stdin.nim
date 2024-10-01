#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat]
import utils


const tmpTestPath = utils.tmpTestPath / "stdin"


if not os.dirExists(tmpTestPath): os.createDir(tmpTestPath)
utils.buildNimprettyT()


let inputFile = testPath / "testdata" / "basic.nim"
let expectedFile = inputFile & ".t.expect"

let stdout = execCmdEx(&"{testExe} {inputFile}")
let expected = execCmdEx(&"cat {expectedFile}")
assert stdout[0] == expected[0]


os.removeDir(tmpTestPath)
