#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, strutils]
import utils


const tmpTestPath = utils.tmpTestPath / "errors"


if not os.dirExists(tmpTestPath): os.createDir(tmpTestPath)
utils.buildNimprettyT()


let testFile = tmpTestPath / "file.nim"
os.copyFile(testPath / "testdata" / "indentation_err.nim", testFile)
let (output, exitCode) = execCmdEx(&"{testExe} -w {testFile}")
assert exitCode == 1
assert output.contains("invalid indentation"), output
assert output.contains(&"failed to format file '{testFile}'"), output

let res = readFile(testFile)
let expectPath = testPath / "testdata" / "indentation_err.nim"
let expected = readFile(expectPath)
assert res == expected


os.removeDir(tmpTestPath)
