from std/os import execShellCmd, fileExists, extractFilename, createSymlink,
    getHomeDir, expandTilde, copyFileToDir, removeFile, existsOrCreateDir,
    paramCount, moveFile
from std/strutils import parseInt, split, find
from std/terminal import styledWriteLine, ForegroundColor
from std/parseopt import getOpt, cmdLongOption, cmdShortOption, cmdArgument

const ProgramDir = getHomeDir() & ".config/ctd/"
const StorageFile = getHomeDir() & ".config/ctd/data.txt"
const DotfilesLocation = getHomeDir() & ".config/ctd/dotfiles/"
const BackupLocation = getHomeDir() & ".config/ctd/backups/"

const usageMsg = """

  Available parameters:

  --add=<path>, -a=<path>      Add given file to file list
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

  if fileExists(StorageFile):
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
    os.copyFileToDir(expandTilde(chosenDotfile), DotfilesLocation)
    writeLine(f, expandTilde(chosenDotfile))
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

proc printSavedFiles(waitForUserInput: bool) =
  ##[ Read the entire storage file at once and print its contents. ]##
  if fileExists(StorageFile):
    echo readFile(StorageFile)
    if waitForUserInput: discard readLine(stdin)
  else:
    echo "No saved files yet!"
    if waitForUserInput: discard readLine(stdin)

proc removeFileFromList() =
  ##[ Remove file from StorageFile ]##

  var f: File
  var tmpF = open("temp.txt", fmWrite)

  if not fileExists(StorageFile):
    echo "No saved files yet!"
    discard readLine(stdin)
  else:
    printSavedFiles(false)
    f = open(StorageFile, fmRead)
  defer: f.close()
  defer: tmpF.close()

  echo "Please type the filename you wish to remove (only the filename including dot!)"
  let fileToRemove = readLine(stdin)


  # Look in StorageFile for the given name
  # If found, skip that line in the temp file
  for line in lines(f):
    let fileName = extractFilename(line)
    if fileToRemove == fileName:
      moveFile(DotfilesLocation & fileName, line)
      continue
    else:
      writeLine(tmpF, line)

  # Replace StorageFile without the single deleted line
  moveFile("temp.txt", StorageFile)

proc linkAllSavedFiles() =
  ##[ Create Symlinks for all files that have been added before. ]##
  var f: File

  if not fileExists(StorageFile):
    echo "No saved files yet!"
    discard readLine(stdin)
  else:
    f = open(StorageFile, fmRead)
    defer: f.close()

    for line in lines(f):
      discard os.execShellCmd("clear")
      let fileName = extractFilename(line)
      # let filePath = line[0 .. ^(len(fileName)+1)]

      echo "Trying to create Symlink: " & DotfilesLocation & fileName &
          " to: " & line

      try:
        createSymlink(DotfilesLocation & fileName, line)
        terminal.styledWriteLine(stdout, fgGreen, "Created Symlink: " &
            DotfilesLocation & fileName & " to: " & line)
      except OSError as e:
        terminal.styledWriteLine(stdout, fgRed, "Error: ", e.msg)
        terminal.styledWriteLine(stdout, fgYellow, "Shall the existing file be overwritten? [y/N]")

        case readLine(stdin):
          of "y":
            removeFile(line)
            createSymlink(DotfilesLocation & fileName, line)
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
  discard existsOrCreateDir(ProgramDir)
  discard existsOrCreateDir(DotfilesLocation)
  discard existsOrCreateDir(BackupLocation)

  while true:
    discard os.execShellCmd("clear")

    echo menuText

    stdout.write("> ") # Not echo cause of newline
    case parseInt(readLine(stdin)): # Error prone: If NaN -> Error //FIXME
      of 1:
        addNewFile("")
      of 2:
        removeFileFromList()
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
  if paramCount() > 0:
    for kind, key, val in getOpt():
      case kind:
        of cmdLongOption, cmdShortOption:
          case key:
            of "add", "a":
              addNewFile(val)
            of "list", "l":
              printSavedFiles(false)
            else: printUsage()
        else: discard
  else:
    main()
