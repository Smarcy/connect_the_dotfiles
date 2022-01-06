import unittest
import strutils
import sequtils

include "../src/connect_the_dotfiles.nim"

suite "test adding a file to storage":

  test "add a file and find it in StorageFile":
    let f = open(getHomeDir() & ".ctd_testFile", fmWrite)
    f.close()
    let storage = open(StorageFile, fmRead)
    defer: storage.close()

    addNewFile(getHomeDir() & ".ctd_testFile")

    var isInStorageFile = false

    for line in lines(storage):
      if line == getHomeDir() & ".ctd_testFile":
        isInStorageFile = true
    check(isInStorageFile)

    # Clean Up: Delete Testfile, remove testLine in StorageFile
    removeFile(getHomeDir() & ".ctd_testFile")
    var lines = readFile(StorageFile).splitLines(keepEol = true)
    lines.delete(lines.len-2 .. lines.len-1)
    StorageFile.writeFile(lines.join())

