from std/os import execShellCmd, fileExists, extractFilename, createSymlink,
    getHomeDir, expandTilde, copyFileToDir, removeFile, existsOrCreateDir, paramCount
from std/strutils import parseInt
from std/terminal import styledWriteLine, ForegroundColor
from std/parseopt import getOpt, cmdLongOption, cmdShortOption, cmdArgument

const programDir = getHomeDir() & ".config/ctd/"
const storageFile = getHomeDir() & ".config/ctd/data.txt"
const dotfilesLocation = getHomeDir() & ".config/ctd/dotfiles/"
const backupLocation = getHomeDir() & ".config/ctd/backups/"

proc printUsage() =
  ##[ Obvious. ]##
  echo """

  Available parameters:

  --add=<path>, -a=<path>      Add given file to file list
  --list, -l                   List all saved files
  --help, -h                   Print usage guide (this)
  """

proc addNewFile(chosenDotfile: string) =
  ##[ Add a new dotfile/location-combination to the storage file. ]##
  var chosenDotfile = chosenDotfile
  var waitForUserInput: bool
  var f: File

  if fileExists(storageFile):
    # If the storage file already exists, append to it.
    # Otherwise use fmWrite to create it at first.
    f = open(storageFile, fmAppend)
  else:
    f = open(storageFile, fmWrite)
  defer: f.close()

  # chosenDotfile is empty if addNewFile is called from within the binary, without cmdline params
  if chosenDotfile == "":
    discard os.execShellCmd("clear")
    echo "Type the full path to the dotfile, including its name"

    waitForUserInput = true
    chosenDotfile = readLine(stdin)

  try:
    os.copyFileToDir(expandTilde(chosenDotfile), dotfilesLocation)
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
  if fileExists(storageFile):
    echo readFile(storageFile)
    if waitForUserInput: discard readLine(stdin)
  else:
    echo "No saved files yet!"
    if waitForUserInput: discard readLine(stdin)

proc linkAllSavedFiles() =
  ##[ Create Symlinks for all files that have been added before. ]##
  var f: File

  if not fileExists(storageFile):
    echo "No saved files yet!"
    discard readLine(stdin)
  else:
    f = open(storageFile, fmRead)
    defer: f.close()

    for line in lines(f):
      discard os.execShellCmd("clear")
      let fileName = extractFilename(line)
      # let filePath = line[0 .. ^(len(fileName)+1)]

      echo "Trying to create Symlink: " & dotfilesLocation & fileName &
          " to: " & line

      try:
        createSymlink(dotfilesLocation & fileName, line)
        terminal.styledWriteLine(stdout, fgGreen, "Created Symlink: " &
            dotfilesLocation & fileName & " to: " & line)
      except OSError as e:
        terminal.styledWriteLine(stdout, fgRed, "Error: ", e.msg)
        terminal.styledWriteLine(stdout, fgYellow, "Shall the existing file be overwritten? [y/N]")

        case readLine(stdin):
          of "y":
            removeFile(line)
            createSymlink(dotfilesLocation & fileName, line)
            terminal.styledWriteLine(stdout, fgGreen, "Created Symlink: " &
                dotfilesLocation & fileName & " to: " & line)
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
  discard existsOrCreateDir(programDir)
  discard existsOrCreateDir(dotfilesLocation)
  discard existsOrCreateDir(backupLocation)

  while true:
    discard os.execShellCmd("clear")
    echo """
Welcome to connect_the_dotfiles, your place to organize your dotties!
Please choose an option:

[1]: Add new dotfile
[2]: Remove existing dotfile
[3]: List saved dotfiles
[4]: Link all saved dotfiles
[5]: Quit

    """

    stdout.write("> ") # Not echo cause of newline
    case parseInt(readLine(stdin)): # Error prone: If NaN -> Error //FIXME
      of 1:
        addNewFile("")
      of 2:
        echo "TODO"
        discard readLine(stdin)
      of 3:
        printSavedFiles(true)
      of 4:
        linkAllSavedFiles()
      of 5:
        break
      else:
        continue

if paramCount() > 0:
  for kind, key, val in getOpt():
    case kind:
      of cmdLongOption, cmdShortOption:
        case key:
          of "add", "a":
            addNewFile(val)
            quit()
          of "list", "l":
            printSavedFiles(false)
            quit()
          else: printUsage()
      else: quit()
else:
  main()

