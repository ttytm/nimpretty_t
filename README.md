# nimpretty_t

[badge__build]: https://img.shields.io/github/actions/workflow/status/ttytm/nimpretty_t/ci.yml?branch=main&logo=github&logoColor=C0CAF5&labelColor=333
[badge__version]: https://img.shields.io/github/v/release/ttytm/nimpretty_t?logo=task&logoColor=C0CAF5&labelColor=333&color=ffc200

[![][badge__build]](https://github.com/ttytm/nimpretty_t/actions?query=branch%3Amain)
[![][badge__version]](https://github.com/ttytm/nimpretty_t/releases/latest)

Enables `nimpretty` formatting for projects that use tabs and allows viewing formatting diffs.

## Quick start

- [Installation](#installation)
- [Editor Setup](#editor-setup)
  - [Neovim](#neovim)
  - [VS Code / Codium](#vs-code--codium)

## Overview

### Usage

```
Usage: nimpretty_t [options] <path>...

Formatter and diff viewer utilizing nimpretty.
By default, formatted output is written to stdout.

Options:
  -w  --write           Modifies non-conforming files in-place.
  -l  --list            Prints paths of non-conforming files. Exits with an error if any are found.
  -d  --diff            Prints differences of non-conforming files. Exits with an error if any are found.
  -i  --indentation     Sets the indentation used [possible values: 'tabs', 'smart', '<num>'(spaces)].
                        - tabs: used by default.
                        - smart: based on the initial indentations in a file.
                        - <num>: number of spaces.
  -L  --line-length     Sets the max character line length. Default is 100.
  -h  --help            Prints this help information.
  -v  --version         Prints version information.

Environment Variables:
  NIM_DIFF_CMD          Sets a custom diff command that is used with the '-diff' option
                        E.g.: 'NIM_DIFFCMD="diff --color=always -U 2"'
```

## Getting Started

### Installation

- Via nimble

  ```sh
  nimble install nimpretty_t
  ```

- Pre-built binaries can be downloaded from the [release page](https://github.com/ttytm/nimpretty_t/releases).

  - [GNU/Linux](https://github.com/ttytm/nimpretty_t/releases/latest/download/nimpretty_t-linux-amd64)
  - [Windows](https://github.com/ttytm/nimpretty_t/releases/latest/download/nimpretty_t-windows-amd64.exe)
  - [macOS (arm64)](https://github.com/ttytm/nimpretty_t/releases/latest/download/nimpretty_t-macos-arm64)
  - [macOS (amd64)](https://github.com/ttytm/nimpretty_t/releases/latest/download/nimpretty_t-macos-amd64)

### Editor Setup

- #### Neovim

  Register `nimpretty_t` in `null-ls`/`none-ls`

  ```lua
  local null_ls = require("null-ls")
  -- ...
  null_ls.register({
  	name = "nimpretty_t",
  	method = null_ls.methods.FORMATTING,
  	filetypes = { "nim" },
  	generator = null_ls.formatter({
  		command = "nimpretty_t",
  		args = { "-w", "$FILENAME" },
  		to_temp_file = true,
  	}),
  })
  ```

  A complementary tool regarding indentation for neovim is [tabs-vs-spaces.nvim](https://github.com/tenxsoydev/tabs-vs-spaces.nvim)

- #### VS Code / Codium

  Since nimpretty_t is a niche project in the Nim community, it is not yet clear whether it will have a user base that can benefit from its own VS Code extension.
  To save efforts the extension has not yet been completed. Until then, please use the `Run on Save` extension from emeraldwalk.

  ```jsonc
  // settings.json
  // ...
  "emeraldwalk.runonsave": {
  	"commands": [
  		{
  			"match": "\\.nim$",
  			"isAsync": true,
  			"cmd": "nimpretty_t ${file}"
  			// "cmd": "nimpretty_t -w ${file}"
  		}
  	]
  }
  ```
