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

task b, "Debug Build only":
  exec("nim c -o:bin/ctd src/connect_the_dotfiles.nim")

task m, "Release Build and Run..":
  exec("nim c -d:release --opt:size --passL:-s -r -o:bin/ctd src/connect_the_dotfiles.nim")

task r, "Release build":
  exec("nim c -d:release --opt:size --passL:-s -o:bin/ctd src/connect_the_dotfiles.nim")
