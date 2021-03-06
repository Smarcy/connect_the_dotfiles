from std/os import execShellCmd, fileExists, extractFilename, createSymlink,
    expandTilde, copyFileToDir, removeFile, paramCount, moveFile,
    expandSymlink, symlinkExists, getFileSize, walkDir, pcFile,
    pcLinkToFile, pcDir, pcLinkToDir
from std/terminal import styledWriteLine, ForegroundColor
from std/parseopt import getOpt, cmdLongOption, cmdShortOption
from std/hashes import hash, Hash
from std/strutils import contains
from std/sequtils import toSeq
from misc import getUsageMsg, getMenuText, getProgramDir, getStorageFileLoc,
    getDotfilesLoc, getBackupsLoc, initDirectoryStructureAndStorageFile,
    clearScreen

const ProgramDir = misc.getProgramDir()
const StorageFile = misc.getStorageFileLoc()
const DotfilesLoc = misc.getDotfilesLoc()
const BackupsLoc = misc.getBackupsLoc()

const usageMsg = misc.getUsageMsg()
const menuText = misc.getMenuText()

proc printUsage() =
  ##[ Obvious. ]##
  echo usageMsg

proc addNewFile(chosenDotfile: string) =
  ##[ Add a new entry to the Storagefile. ]##
  var
    chosenDotfile = chosenDotfile
    waitForUserInput: bool
    f: File

  # chosenDotfile is empty if addNewFile is called from within the binary, without cmdline params
  if chosenDotfile == "":

    if not fileExists(Storagefile):
      open(ProgramDir & "data.txt", fmWrite).close()


    misc.clearScreen()
    echo "Type the full path to the dotfile, including its name"

    waitForUserInput = true
    chosenDotfile = expandTilde(readLine(stdin))

    f = open(StorageFile, fmRead)

    var writeEntry = true

    for line in f.lines:
      var line = os.expandTilde(line)
      if chosenDotfile == line:
        terminal.styledWriteLine(stdout, fgRed, "You already added that file.")
        discard readLine(stdin)
        return

    # Special case, if there is an entry in Storagefile but not the actual file
    # Then copy it over nonetheless
    if (readFile(StorageFile).contains(chosenDotfile)) or symlinkExists(chosenDotfile):
      copyFileToDir(chosenDotfile, DotfilesLoc)
      writeEntry = true

    f = open(StorageFile, fmAppend)
    defer: f.close()

    if os.fileExists(chosenDotfile) and writeEntry:
      try:
        os.copyFileToDir(chosenDotfile, DotfilesLoc)
        io.writeLine(f, chosenDotfile)

        terminal.styledWriteLine(stdout, fgYellow,
            "Do you want to create a backup of the origin file? [Y/n]")

        case readLine(stdin)
        of "N", "n":
          discard
        else:
          os.copyFileToDir(chosenDotfile, BackupsLoc)
          terminal.styledWrite(stdout, fgGreen,
              "Backup successfully created at " & BackupsLoc)

      except OSError as e:
        terminal.styledWriteLine(stdout, fgRed,
            "Could not copy given dotfile: ", e.msg)

  if waitForUserInput: discard readLine(stdin)

proc isLinked(s: string): bool =
  ##[ Return true if a file in Storagefile has an active symlink. ]##
  if symlinkExists(s):
    let
      filesLinkedToHash = hash(os.expandSymlink(s))
      dotfileHash = hash(DotfilesLoc & os.extractFilename(s))
    return filesLinkedToHash == dotfileHash

proc isBackedUp(line: string): bool =
  ##[ Return true if a file in Storagefile has a backup in Backupdir. ]##
  ## TODO: IDEA: Check for hashes as well? Maybe backup could be an old file?
  result = fileExists(BackupsLoc & extractFilename(line))

proc printSavedFiles(waitForUserInput: bool) =
  ##[ Read the entire storage file at once and print its contents. ]##
  var res: string
  if not os.fileExists(StorageFile) or os.getFileSize(StorageFile) == 0:
    echo "No saved files yet!"
  else:
    let f = open(StorageFile, fmRead)
    defer: f.close()


    for line in f.lines:
      res = line
      if os.symlinkExists(line):
        if line.isLinked():
          res = line & " [linked]"
      if line.isBackedUp():
        res = res & " [backup]"
      echo res

  if waitForUserInput:
    discard readLine(stdin)

proc removeFileFromList(chosenDotfile: string) =
  ##[ Remove file from StorageFile. ]##
  let tmpFile = open("temp.txt", fmWrite)
  var f: File

  if not os.fileExists(StorageFile) or os.getFileSize(StorageFile) == 0:
    echo "No saved files yet!"
    discard readLine(stdin)
    return
  else:
    if chosenDotfile == "":
      printSavedFiles(false)
    f = open(StorageFile, fmRead)
  defer: f.close()
  defer: tmpFile.close()

  var fileToRemove: string

  # chosenDotfile is empty if this proc is called from inside the binary
  # chosenDotfile is not empty if this proc is called from the cli
  if chosenDotfile == "":
    echo "Please type the filename you wish to remove (only the filename including dot!)"
    fileToRemove = readLine(stdin)
  else:
    fileToRemove = chosenDotfile

  # Look in StorageFile for the given name
  # If found, skip that line in the temp file and move file back to its origin dir
  for line in f.lines:
    let fileName = os.extractFilename(line)
    if fileToRemove == fileName:
      os.moveFile(DotfilesLoc & fileName, line)

      terminal.styledWriteLine(stdout, fgYellow, "Do you want to remove the backup, too? [y/N]")
      case readLine(stdin):
        of "y", "Y":
          if fileExists(BackupsLoc & fileName):
            removeFile(BackupsLoc & fileName)
        else:
          discard
      continue
    else:
      io.writeLine(tmpFile, line)

  # Replace StorageFile without the single deleted line
  os.moveFile("temp.txt", StorageFile)

proc linkSingleFile(line: string) =
  ##[ This proc is called whenever a file shall be linked.
    Links a single file and reduces code replication. ]##
  misc.clearScreen()
  let fileName = os.extractFilename(line)

  echo "Trying to create Symlink: " & DotfilesLoc & fileName &
      " to: " & line

  try:
    os.createSymlink(DotfilesLoc & fileName, line)
    terminal.styledWriteLine(stdout, fgGreen, "Created Symlink: " &
        DotfilesLoc & fileName & " to: " & line)
  except OSError as e:
    terminal.styledWriteLine(stdout, fgRed, "Error: ", e.msg)
    terminal.styledWriteLine(stdout, fgYellow, "Shall the existing file be overwritten? [y/N]")

    case readLine(stdin):
      of "y":
        os.removeFile(line)
        os.createSymlink(DotfilesLoc & fileName, line)
        terminal.styledWriteLine(stdout, fgGreen, "Created Symlink: " &
            DotfilesLoc & fileName & " to: " & line)
        discard readLine(stdin)
      else:
        discard

proc linkAllSavedFiles() =
  ##[ Create Symlinks for all files that have been added before. ]##
  var f: File

  if not os.fileExists(StorageFile) or os.getFileSize(StorageFile) == 0:
    echo "No saved files yet!"
    discard readLine(stdin)
  else:
    f = open(StorageFile, fmRead)
    defer: f.close()

    for line in f.lines:
      linkSingleFile(line)

  # for file in fileNames:
  #   if not fileExists("./dotfiles/" & file):
  #     echo file & " is in your storage file but not in your dotfiles directory!"
  #     discard readLine(stdin)
  #   else:
  #     discard os.execShellCmd("ln -s ./dotfiles/" & file

proc linkAllUnlinkedFiles() =
  ##[ Ask the user to link every unlinked file. ]##
  let f = open(StorageFile, fmRead)
  defer: f.close()

  for line in f.lines:
    if not line.isLinked():
      linkSingleFile(line)

proc revertAllLinks() =
  ##[ Replace all symlinks with their origin file. ]##
  var f: File

  if fileExists(StorageFile):
    f = open(StorageFile, fmRead)
  else:
    echo "There is no storage file."
  defer: f.close()

  for line in f.lines:
    let storedDotfile = DotfilesLoc & extractFilename(line)
    let pathWithoutFilename = line[0 .. ^(len(extractFilename(line))+1)]

    if fileExists(storedDotfile) and symlinkExists(line):
      removeFile(line)
      copyFileToDir(storedDotfile, pathWithoutFilename)
      terminal.styledWrite(stdout, fgGreen, "Successfully reverted " & line & "\n")
    else:
      terminal.styledWrite(stdout, fgRed, "Could not revert " & line & "\n")
  discard readLine(stdin)

proc cleanupDotfilesDir() =
  ##[ Compare Storagefile entrys with DotfileDir content and delete diff from DotfileDir. ]##
  let f = open(StorageFile, fmRead)
  let allFilesInDotfileLoc = toSeq(os.walkDir(DotfilesLoc))

  var foundFiles: seq[string]
  var wrongFilesCounter = 0

  # file[0] contains file kind, file[1] contains file path
  for line in f.lines:
    for file in allFilesInDotfileLoc:
      if extractFilename(line) == extractFilename(file[1]):
        foundFiles.add(extractFilename(line))
        break

  for file in allFilesInDotfileLoc:
    case file[0]
    # Only look at real files, ignore dirs and links for now.
    of pcDir, pcLinkToDir, pcLinkToFile:
      continue
    of pcFile:
      if extractFilename(file[1]) notin foundFiles:
        inc(wrongFilesCounter)
        misc.clearScreen()
        terminal.styledWriteLine(stdout, fgYellow, extractFilename(file[1]) &
          " is in your dotfile directory but not in your storagefile. Do you want to delete it? (Y/n)")
        terminal.styledWriteLine(stdout, fgRed, "Remember to put the given file back in its correct place as" &
                                                " it may be only a link there and the file will be lost. Since" &
                                                " there is no entry in your storage file CTD can not reconstruct the correct path!")

        case readLine(stdin):
          of "n":
            continue
          of "", "y", "Y":
            echo "Deleting " & DotfilesLoc & extractFilename(file[1])
            removeFile(DotfilesLoc & extractFilename(file[1]))
            styledWriteLine(stdout, fgGreen, "Successfully deleted " &
                DotfilesLoc & extractFilename(file[1]))
            discard readLine(stdin)
          else:
            continue

  if wrongFilesCounter == 0:
    terminal.styledWriteLine(stdout, fgYellow, "There were no superflous files found in your dotfiles directory")
    discard readLine(stdin)

proc main() =
  ##[ Entry Point and main loop. ]##

  misc.initDirectoryStructureAndStorageFile()

  while true:
    misc.clearScreen()

    echo menuText

    stdout.write("> ") # Not echo cause of newline
    case readLine(stdin):
      of "1":
        addNewFile("")
      of "2":
        removeFileFromList("")
        discard readLine(stdin)
      of "3":
        printSavedFiles(true)
      of "4":
        linkAllSavedFiles()
      of "5":
        linkAllUnlinkedFiles()
      of "6":
        revertAllLinks()
      of "c":
        cleanupDotfilesDir()
      of "q":
        break
      else:
        continue

when isMainModule:
  misc.initDirectoryStructureAndStorageFile()

  # If there are any CLI params passed, evaluate those
  # Otherwise run the bin's usual main() proc
  if os.paramCount() > 0:
    for kind, key, val in getOpt():
      case kind:
        of cmdLongOption, cmdShortOption:
          case key:
            of "add", "a":
              addNewFile(val)
            of "list", "l":
              printSavedFiles(waitForUserInput = false)
            of "remove", "r":
              removeFileFromList(val)
            else: printUsage()
        else: discard
  else:
    main()
