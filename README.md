# Connect The Dotfiles (CTD)

<div align="center">
<img src="https://github.com/Smarcy/connect_the_dotfiles/blob/master/assets/introMenu.png">
</div>

- [Connect The Dotfiles (CTD)](#connect-the-dotfiles--ctd-)
  * [Disclaimer](#disclaimer)
  * [Installation](#installation)
  * [Functionality](#functionality)
  * [Info](#info)
  * [OS Support](#os-support)
  * [Future Ideas](#future-ideas)
  * [TODO](#todo)

## Disclaimer

This software is just a hobby project. I created it mainly for my own use because
I wanted to be able to organize my dotfiles comfortably exactly the way I wish to. Also I like Nim.
I did not reinvent the wheel in any way.
Use this piece of software **at your own risk**.

If you do not read carefully before you type, **you may mess up your system irreversibly**.

This software does create symlinks on your machine and even, if wanted, delete files.
Thus, **think** before you type. Even better: study the source code.

## Installation

* Install Nim (I recommend [choosenim](https://github.com/dom96/choosenim))
* Clone this repository
* Run `nimble m` in the `connect_the_dotfiles/` directory
* This will create and run a binary in the `bin/` directory
  * You can also run `nimble b` to create the binary without immediately running it
* Start the binary or pass parameters to it (`--help` for usage guide)

## Functionality

- Gather all your configuration files in a single directory
  - It is recommended to make that specific directory version controlled (e.g. `Git`)
- Let `CTD` automatically create links at the needed location

## Info

Relevant files & directories:

* `~/.config/ctd/`
* `~/.config/ctd/data.txt`
* `~/.config/ctd/dotfiles/` (You want this to be a Git Repo)
* `~/.config/ctd/backups/`


## OS Support

Right now I am concentrating on Linux only and I do not intend to
port to Windows anytime, yet.

## Future Ideas

This is the first version that is even running and working,
therefore it is not doing too much yet and I'm not even sure yet where this
funny journey will lead to.

## TODO

* [X] Remove existing files
* [X] Link only selected files
* [ ] Link only unlinked files
* [X] Make `CTD` usable by passing parameters to the binary (linking missing)
* [X] Revert all links and replace them with the actual files
* [ ] Option to backup added origin files
* [ ] Option to refresh backup files to current state
* [X] When listing all saved files, indicate already linked ones
* [ ] Testing, Testing, Testing!


To be continued
