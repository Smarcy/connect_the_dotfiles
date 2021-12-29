from std/os import execShellCmd, fileExists
from std/strutils import parseInt

include config

proc addNewFile() =
  ##[ Add a new dotfile/location-combination to the storage file. ]##
  var f: File

  if fileExists(filePath):
    # If the dotfile/location-combination storage file already exists,
    # appen to it. Otherwise use fmWrite to create it at first.
    f = open(filePath, fmAppend)
  else:
    f = open(filePath, fmWrite)
  defer: f.close()

  discard os.execShellCmd("clear")
  echo "Type the full path to the dotfile, including its name"
  let dotfileLocation = readLine(stdin)
  let copyCmd = "cp " & dotfileLocation & " ./dotfiles/"

  # If the copying is error free, add the path to the storage file
  if os.execShellCmd(copyCmd) == 0:
    writeLine(f, dotfileLocation)
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
  if fileExists(filePath):
    echo readFile(filePath)
    discard readLine(stdin)
  else:
    echo "No saved files yet!"
    discard readLine(stdin)

proc linkAllSavedFiles() =
  discard

proc main() =
  ##[ Entry Point and main loop. ]##
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
      of 3:
        printSavedFiles()
      of 4:
        linkAllSavedFiles()
      of 5:
        break
      else:
        continue

main()
