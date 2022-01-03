# Connect The Dotfiles (CTD)

## Awesome Tool to organize your dotfiles!

<div align="center">
<img src="https://github.com/Smarcy/connect_the_dotfiles/blob/master/assets/introMenu.png">
</div>

## Disclaimer

This software is just a hobby project. I created it mainly for my own use because
I wanted to be able to organize my dotfiles comfortably exactly the way I wish to. Also I like Nim.
I did not reinvent the wheel in any way.
Use this piece of software **at your own risk**.

If you do not read carefully before you type, **you may mess up your system irreversibly**.

This software does create symlinks on your machine and even, if wanted, delete files.
Thus, **think** before you type. Even better: study the source code.

## Installation

Either

* Use the binary in `bin/`
  * You may just start the binary
  * Or pass parameters to it (--help for usage guide)


or

* Install Nim (I recommend [choosenim](https://github.com/dom96/choosenim))
* Clone this repository
* Run `nimble m` in the `connect_the_dotfiles/` directory

## Functionality

- Gather all your configuration files in a single directory
  - It is recommended to make that specific directory verison controlled (e.g. `Git`)
- Let `CTD` automatically create links at the needed location

## Info

Relevant files & directories:

* `~/.config/ctd/`
* `~/.config/ctd/data.txt`
* `~/.config/ctd/dotfiles/`
* `~/.config/ctd/backups/`


## OS Support

Right now I am concentrating on Linux only and I do not intend to
port to Windows anytime, yet.

## Future Ideas

This is the first version that is even running and working,
therefore it is not doing too much yet and I'm not even sure yet where this
funny journey will lead to.

## TODO

* [ ] Remove existing files
* [ ] Link only selected files
* [ ] Link only unlinked files
* [ ] Make `CTD` usable by passing parameters to the binary
* [ ] Revert all links and replace them with the actual files
* [ ] Option to backup added origin files
* [ ] Option to refresh backup files to current state

To be continued
