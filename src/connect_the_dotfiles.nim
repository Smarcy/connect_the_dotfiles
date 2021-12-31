from std/os import execShellCmd, fileExists, extractFilename, splitPath,
    createSymlink, getHomeDir, expandTilde, copyFileToDir, removeFile, existsOrCreateDir
from std/strutils import parseInt

const storageFile = getHomeDir() & ".ctd/data.txt"
const dotfilesLocation = getHomeDir() & ".ctd/dotfiles/"
# const backupLocation = getHomeDir() & ".ctd/backups/"

proc addNewFile() =
  ##[ Add a new dotfile/location-combination to the storage file. ]##
  var f: File

  if fileExists(storageFile):
    # If the storage file already exists,
    # appen to it. Otherwise use fmWrite to create it at first.
    f = open(storageFile, fmAppend)
  else:
    f = open(storageFile, fmWrite)
  defer: f.close()

  discard os.execShellCmd("clear")
  echo "Type the full path to the dotfile, including its name"
  let chosenDotfile = readLine(stdin)

  try:
    os.copyFileToDir(expandTilde(chosenDotfile), dotfilesLocation)
    writeLine(f, expandTilde(chosenDotfile))
  except OSError as e:
    echo "Could not copy given dotfile: ", e.msg
    discard readLine(stdin)

  # var backupOption = false
  # echo "Should a backup be created before linking the file? [Y/n]"
  # case readLine(stdin):
  #   of "y": backupOption = true
  #   of "n": backupOption = false
  #   of "": backupOption = true
  #   else: discard

proc printSavedFiles() =
  ##[ Read the entire storage file at once and print its contents. ]##
  if fileExists(storageFile):
    echo readFile(storageFile)
    discard readLine(stdin)
  else:
    echo "No saved files yet!"
    discard readLine(stdin)

proc linkAllSavedFiles() =
  var f: File

  if not fileExists(storageFile):
    echo "No saved files yet!"
    discard readLine(stdin)
  else:
    f = open(storageFile, fmRead)
    defer: f.close()

    for line in lines(f):
      let fileName = extractFilename(line)
      # let filePath = line[0 .. ^(len(fileName)+1)]

      echo "Trying to create Symlink: " & dotfilesLocation & fileName &
          " to: " & line

      try:
        createSymlink(dotfilesLocation & fileName, line)
        echo "Created Symlink: ~/git/connect_the_dotfiles/dotfiles/" &
            fileName & " to: " & line
      except OSError as e:
        echo "Error: ", e.msg
        echo "Shall the existing file be overwritten? [y/N]"

        case readLine(stdin):
          of "y":
            removeFile(line)
            createSymlink(dotfilesLocation & fileName, line)
            echo "Created Symlink: ~/git/connect_the_dotfiles/dotfiles/" &
                fileName & " to: " & line
          else:
            discard


    discard readLine(stdin)

  # for file in fileNames:
  #   if not fileExists("./dotfiles/" & file):
  #     echo file & " is in your storage file but not in your dotfiles directory!"
  #     discard readLine(stdin)
  #   else:
  #     discard os.execShellCmd("ln -s ./dotfiles/" & file

proc main() =
  ##[ Entry Point and main loop. ]##

  # Create mandatory dirs on first start
  discard existsOrCreateDir(getHomeDir() & ".ctd/")
  discard existsOrCreateDir(getHomeDir() & ".ctd/dotfiles")
  discard existsOrCreateDir(getHomeDir() & ".ctd/backups")

  while true:
    discard os.execShellCmd("clear")
    echo "Welcome to connect_the_dotfiles, your place to organize your dotties!"
    echo "Please choose an option:"
    echo "\n[1]: Add new dotfile"
    echo "[2]: Remove existing dotfile"
    echo "[3]: List saved dotfiles"
    echo "[4]: Link all saved dotfiles"
    echo "[5]: Quit\n"

    stdout.write("> ") # Not echo cause of newline
    case parseInt(readLine(stdin)): # Error prone: If NaN -> Error
      of 1:
        addNewFile()
      of 2:
        echo "TODO"
        discard readLine(stdin)
      of 3:
        printSavedFiles()
      of 4:
        linkAllSavedFiles()
      of 5:
        break
      else:
        continue

main()
