from std/os import execShellCmd, fileExists, extractFilename, createSymlink,
    getHomeDir, expandTilde, copyFileToDir, removeFile, existsOrCreateDir,
    paramCount, moveFile, expandSymlink, symlinkExists
from std/strutils import parseInt, split, find
from std/terminal import styledWriteLine, ForegroundColor
from std/parseopt import getOpt, cmdLongOption, cmdShortOption, cmdArgument
from std/hashes import hash

const ProgramDir = os.getHomeDir() & ".config/ctd/"
const StorageFile = os.getHomeDir() & ".config/ctd/data.txt"
const DotfilesLocation = os.getHomeDir() & ".config/ctd/dotfiles/"
const BackupLocation = os.getHomeDir() & ".config/ctd/backups/"

const usageMsg = """

  Available parameters:

  --add=<path>, -a=<path>      Add given file to storage
  --remove=<.file> -r=<.file>  Remove a file from storage (insert only dot+filename!)
  --list, -l                   List all saved files
  --help, -h                   Print usage guide (this)
"""

const menuText = """
Welcome to connect_the_dotfiles, your place to organize your dotties!
Please choose an option:

[1]: Add new dotfile
[2]: Remove existing dotfile
[3]: List saved dotfiles
[4]: Link all saved dotfiles
[5]: Quit

"""

proc printUsage() =
  ##[ Obvious. ]##
  echo usageMsg

proc addNewFile(chosenDotfile: string) =
  ##[ Add a new dotfile/location-combination to the storage file. ]##
  var
    chosenDotfile = chosenDotfile
    waitForUserInput: bool
    f: File

  if os.fileExists(StorageFile):
    # If the storage file already exists, append to it.
    # Otherwise use fmWrite to create it at first.
    f = open(StorageFile, fmAppend)
  else:
    f = open(StorageFile, fmWrite)
  defer: f.close()

  # chosenDotfile is empty if addNewFile is called from within the binary, without cmdline params
  if chosenDotfile == "":
    discard os.execShellCmd("clear")
    echo "Type the full path to the dotfile, including its name"

    waitForUserInput = true
    chosenDotfile = readLine(stdin)

  try:
    os.copyFileToDir(os.expandTilde(chosenDotfile), DotfilesLocation)
    writeLine(f, os.expandTilde(chosenDotfile))
  except OSError as e:
    terminal.styledWriteLine(stdout, fgRed, "Could not copy given dotfile: ", e.msg)

    if waitForUserInput: discard readLine(stdin)

  # var backupOption = false
  # echo "Should a backup be created before linking the file? [Y/n]"
  # case readLine(stdin):
  #   of "y": backupOption = true
  #   of "n": backupOption = false
  #   of "": backupOption = true
  #   else: discard

proc isLinked(s: string): bool =

  let f = StorageFile
  for line in f.lines:

    let
      filesLinkedToHash = hash(os.expandSymlink(line))
      dotfileHash = hash(DotfilesLocation & os.extractFilename(line))

    if filesLinkedToHash == dotfileHash: return true

  return false

proc printSavedFiles(waitForUserInput: bool) =
  ##[ Read the entire storage file at once and print its contents. ]##
  if os.fileExists(StorageFile):

    let f = StorageFile

    for line in f.lines:
      if os.symlinkExists(line):
        if line.isLinked():
          echo line & " [linked]"
        else:
          echo line
      else:
        echo line

    if waitForUserInput:
      discard readLine(stdin)
  else:
    echo "No saved files yet!"

proc removeFileFromList(chosenDotfile: string) =
  ##[ Remove file from StorageFile ]##
  var
    f: File
    tmpFile = open("temp.txt", fmWrite)

  if not os.fileExists(StorageFile):
    echo "No saved files yet!"
    discard readLine(stdin)
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
  for line in lines(f):
    let fileName = os.extractFilename(line)
    if fileToRemove == fileName:
      os.moveFile(DotfilesLocation & fileName, line)
      continue
    else:
      writeLine(tmpFile, line)

  # Replace StorageFile without the single deleted line
  os.moveFile("temp.txt", StorageFile)

proc linkAllSavedFiles() =
  ##[ Create Symlinks for all files that have been added before. ]##
  var f: File

  if not os.fileExists(StorageFile):
    echo "No saved files yet!"
    discard readLine(stdin)
  else:
    f = open(StorageFile, fmRead)
    defer: f.close()

    for line in lines(f):
      discard os.execShellCmd("clear")
      let fileName = os.extractFilename(line)
      # let filePath = line[0 .. ^(len(fileName)+1)]

      echo "Trying to create Symlink: " & DotfilesLocation & fileName &
          " to: " & line

      try:
        os.createSymlink(DotfilesLocation & fileName, line)
        terminal.styledWriteLine(stdout, fgGreen, "Created Symlink: " &
            DotfilesLocation & fileName & " to: " & line)
      except OSError as e:
        terminal.styledWriteLine(stdout, fgRed, "Error: ", e.msg)
        terminal.styledWriteLine(stdout, fgYellow, "Shall the existing file be overwritten? [y/N]")

        case readLine(stdin):
          of "y":
            os.removeFile(line)
            os.createSymlink(DotfilesLocation & fileName, line)
            terminal.styledWriteLine(stdout, fgGreen, "Created Symlink: " &
                DotfilesLocation & fileName & " to: " & line)
            discard readLine(stdin)
          else:
            discard

  # for file in fileNames:
  #   if not fileExists("./dotfiles/" & file):
  #     echo file & " is in your storage file but not in your dotfiles directory!"
  #     discard readLine(stdin)
  #   else:
  #     discard os.execShellCmd("ln -s ./dotfiles/" & file

proc main() =
  ##[ Entry Point and main loop. ]##

  # Create mandatory dirs on first start
  discard os.existsOrCreateDir(ProgramDir)
  discard os.existsOrCreateDir(DotfilesLocation)
  discard os.existsOrCreateDir(BackupLocation)

  while true:
    discard os.execShellCmd("clear")

    echo menuText

    stdout.write("> ") # Not echo cause of newline
    case parseInt(readLine(stdin)): # Error prone: If NaN -> Error //FIXME
      of 1:
        addNewFile("")
      of 2:
        removeFileFromList("")
        discard readLine(stdin)
      of 3:
        printSavedFiles(true)
      of 4:
        linkAllSavedFiles()
      of 5:
        break
      else:
        continue

when isMainModule:
  if os.paramCount() > 0:
    for kind, key, val in getOpt():
      case kind:
        of cmdLongOption, cmdShortOption:
          case key:
            of "add", "a":
              addNewFile(val)
            of "list", "l":
              printSavedFiles(false)
            of "remove", "r":
              removeFileFromList(val)
            else: printUsage()
        else: discard
  else:
    main()
