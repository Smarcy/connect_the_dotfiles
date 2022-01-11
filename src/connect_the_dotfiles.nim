from std/os import execShellCmd, fileExists, extractFilename, createSymlink,
    getHomeDir, expandTilde, copyFileToDir, removeFile, existsOrCreateDir,
    paramCount, moveFile, expandSymlink, symlinkExists
from std/terminal import styledWriteLine, ForegroundColor
from std/parseopt import getOpt, cmdLongOption, cmdShortOption
from std/hashes import hash, Hash
from std/strutils import contains

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
[5]: Link all unlinked dotfiles
[6]: Replace all links with the origin files
[q]: Quit

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

  # chosenDotfile is empty if addNewFile is called from within the binary, without cmdline params
  if chosenDotfile == "":

    if not fileExists(Storagefile):
      open(ProgramDir & "data.txt", fmWrite).close()


    discard os.execShellCmd("clear")
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

    # Special case, is there is an entry in Storagefile but not the actual file
    # So then copy it over nontheless
    if (readFile(StorageFile).contains(chosenDotfile)) or symlinkExists(chosenDotfile):
      copyFileToDir("/home/marc/git/dotfiles/.vimrc", DotfilesLocation)
      writeEntry = true

    f = open(StorageFile, fmAppend)
    defer: f.close()

    if os.fileExists(chosenDotfile) and writeEntry:
      try:
        os.copyFileToDir(chosenDotfile, DotfilesLocation)
        io.writeLine(f, chosenDotfile)

        terminal.styledWriteLine(stdout, fgYellow,
            "Do you want to create a backup of the origin file? [Y/n]")

        case readLine(stdin)
        of "N", "n":
          discard
        else:
          os.copyFileToDir(chosenDotfile, BackupLocation)
          terminal.styledWrite(stdout, fgGreen, "Backup successfully created.")

      except OSError as e:
        terminal.styledWriteLine(stdout, fgRed,
            "Could not copy given dotfile: ", e.msg)

  if waitForUserInput: discard readLine(stdin)

proc isLinked(s: string): bool =

  let f = open(StorageFile, fmRead)
  defer: f.close()

  for line in f.lines:
    if symlinkExists(line):
      let
        fileLinkedToHash = hash(line)
        dotfileHash = hash(DotfilesLocation & os.extractFilename(line))
      return fileLinkedToHash == dotfileHash

proc isBackedUp(line: string): bool =
  return fileExists(BackupLocation & extractFilename(line))

proc printSavedFiles(waitForUserInput: bool) =
  ##[ Read the entire storage file at once and print its contents. ]##
  var res: string
  if os.fileExists(StorageFile):

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
  else:
    echo "No saved files yet!"

  if waitForUserInput:
    discard readLine(stdin)

proc removeFileFromList(chosenDotfile: string) =
  ##[ Remove file from StorageFile ]##
  var
    f: File
    tmpFile = open("temp.txt", fmWrite)

  if not os.fileExists(StorageFile):
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
      os.moveFile(DotfilesLocation & fileName, line)

      terminal.styledWriteLine(stdout, fgYellow, "Do you want to remove the backup, too? [y/N]")
      case readLine(stdin):
        of "y", "Y":
          if fileExists(BackupLocation & fileName):
            removeFile(BackupLocation & fileName)
        else:
          discard
      continue
    else:
      io.writeLine(tmpFile, line)

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

    for line in f.lines:
      discard os.execShellCmd("clear")
      let fileName = os.extractFilename(line)

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

proc linkAllUnlinkedFiles() =
  return

proc revertAllLinks() =
  var f: File

  if fileExists(StorageFile):
    f = open(StorageFile, fmRead)
  else:
    echo "There is no storage file."
  defer: f.close()

  for line in f.lines:
    let storedDotfile = DotfilesLocation & extractFilename(line)
    let pathWithoutFilename = line[0 .. ^(len(extractFilename(line))+1)]

    if fileExists(storedDotfile) and symlinkExists(line):
      removeFile(line)
      copyFileToDir(storedDotfile, pathWithoutFilename)

proc main() =
  ##[ Entry Point and main loop. ]##

  # Create mandatory dirs on first start
  discard os.existsOrCreateDir(ProgramDir)
  discard os.existsOrCreateDir(DotfilesLocation)
  discard os.existsOrCreateDir(BackupLocation)
  open(StorageFile, fmAppend).close()

  while true:
    discard os.execShellCmd("clear")

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
      of "q":
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
