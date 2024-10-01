#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat]
import utils


const tmpTestPath = utils.tmpTestPath / "exit_codes"


if not os.dirExists(tmpTestPath): os.createDir(tmpTestPath)
utils.buildNimprettyT()


# Prepare a temporary test file.
let testFile = tmpTestPath / "file.nim"
os.copyFile(testPath / "testdata" / "fizz_buzz.nim", testFile)

assert execCmd(&"{testExe} -l {testFile}") == 1
assert execCmd(&"{testExe} -d {testFile}") == 1
assert execCmd(&"{testExe} -w {testFile}") == 0
assert execCmd(&"{testExe} -l {testFile}") == 0
assert execCmd(&"{testExe} -d {testFile}") == 0


os.removeDir(tmpTestPath)
