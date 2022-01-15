from os import getHomeDir, existsOrCreateDir

proc getUsageMsg*(): string =
  ##[ Returns the usage message. ]##
  """

    Available parameters:

    --add=<path>, -a=<path>      Add given file to storage
    --remove=<.file> -r=<.file>  Remove a file from storage (insert only dot+filename!)
    --list, -l                   List all saved files
    --help, -h                   Print usage guide (this)
  """

proc getMenuText*(): string =
  ##[ Returns the menu text. ]##
  """
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

proc getProgramDir*(): string =
  ##[ Return the path to the Program directory. ]##
  os.getHomeDir() & ".config/ctd/"

proc getStorageFileLoc*(): string =
  ##[ Return the path to the Program directory. ]##
  os.getHomeDir() & ".config/ctd/data.txt"

proc getDotfilesLoc*(): string =
  ##[ Return the path to the Program directory. ]##
  os.getHomeDir() & ".config/ctd/dotfiles/"

proc getBackupsLoc*(): string =
  ##[ Return the path to the Program directory. ]##
  os.getHomeDir() & ".config/ctd/backups/"

proc initDirectoryStructureAndStorageFile*() =
  ##[ Create mandatory dirs.
    This proc is called when starting the bin or evaluating a param. ]##
  discard os.existsOrCreateDir(getProgramDir())
  discard os.existsOrCreateDir(getDotfilesLoc())
  discard os.existsOrCreateDir(getBackupsLoc())
  open(getStorageFileLoc(), fmAppend).close()

