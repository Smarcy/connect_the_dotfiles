# Package

version       = "0.2.0"
author        = "Marc Asendorf"
description   = "Organize and Sync dotfiles"
license       = "MIT"
srcDir        = "src"
bin           = @["connect_the_dotfiles"]
skipDirs      = @["tests"]


# Dependencies

requires "nim >= 1.6.0"

# Tasks

task m, "Build and Run..":
  exec("nim c -r -o:bin/ctd src/connect_the_dotfiles.nim")

task b, "Build only":
  exec("nim c -o:bin/ctd src/connect_the_dotfiles.nim")
