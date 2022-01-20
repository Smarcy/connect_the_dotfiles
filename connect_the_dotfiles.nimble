# Package

version       = "0.3.0"
author        = "Marc Asendorf"
description   = "Organize and Sync dotfiles"
license       = "MIT"
srcDir        = "src"
bin           = @["connect_the_dotfiles"]
skipDirs      = @["tests"]


# Dependencies

requires "nim >= 1.6.0"

# Tasks

task d, "Debug Build":
  exec("nim c -o:bin/ctd src/connect_the_dotfiles.nim")

task dr, "Debug Build":
  exec("nim c -r -o:bin/ctd src/connect_the_dotfiles.nim")

task r, "Release Build":
  exec("nim c -d:release --opt:size --passL:-s -o:bin/ctd src/connect_the_dotfiles.nim")

task rr, "Release Build and Run..":
  exec("nim c -d:release --opt:size --passL:-s -r -o:bin/ctd src/connect_the_dotfiles.nim")

task fullDoc, "Create NimDoc with private Procss etc.":
  exec("nim doc --docInternal src/connect_the_dotfiles.nim")
