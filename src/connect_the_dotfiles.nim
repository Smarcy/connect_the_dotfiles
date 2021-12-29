import std/os
import std/strutils

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
  echo "Type the name of the dotfile"
  let dotfileName = readLine(stdin)

  echo "Type the location where it shall be linked to"
  let dotfileLocation = readLine(stdin)

proc printSavedFiles() =
  ##[ Read the entire file at once and print its contents. ]##
  if fileExists(filePath):
    echo readFile(filePath)
  else:
    echo "No saved files yet!"

proc main() =
  ##[ Entry Point. ]##
  discard os.execShellCmd("clear")
  echo "Welcome to connect_the_dotfiles, your place to organize your dotties!"
  echo "Please choose an option:"
  echo "\n[1]: Add new dotfile"
  echo "[2]: Remove existing dotfile"
  echo "[3]: List saved dotfiles\n"

  stdout.write("> ") # Not echo cause of newline
  case parseInt(readLine(stdin)): # Error prone: If NaN -> Error
    of 1:
      addNewFile()
    of 2:
      echo "Zwei"
    of 3:
      printSavedFiles()
    else:
      main()


  # var f: File

  # if not fileExists(filePath):
  #   # If the dotfile/location-combination storage file does not exist yet,
  #   # create it. Otherwise append to file
  #   f = open(filePath, fmWrite)
  # else:
  #   f = open(filePath, fmAppend)

  # writeLine(f, "test")

main()
