# nimpretty_t

<a href="https://github.com/tobealive/nimpretty_t/actions/workflows/build.yml?query=branch%3Amain" target="_blank">
    <img alt="crates.io" src="https://img.shields.io/github/actions/workflow/status/tobealive/nimpretty_t/build.yml?branch=main&style=flat-square" />
</a>
<br><br>

A simple `nimpretty` wrapper that extends formatting for files with tab indentation.

## Intro

To allow tab characters for indentation, we can put a source filter at the beginning of a nim file.

```
#? replace(sub = "\t", by = "  ")
```

The downside is that adding source filters blocks the use of `nimpretty`.<br>
`nimpretty_t` allows to use the tab filter while preserving the ability to format files.

For files without source filters, `nimpretty_t` will directly forward the prettifying request to `nimpretty`.

_Note: Since source code filters usually block formatting for good reasons, other filters than the tab filter will still block nimpretty_t._

## Getting Started

**Requirements**<br>
`nimpretty` - comes with nim-lang. After all, it's still what's utilized under the hood for code formatting.

### Installation

- Use nims default package manager nimble

  ```sh
  nimble install nimpretty_t
  ```

- Or grab a binary from the releases page<br>
  [nimpretty_t/releases](https://github.com/tobealive/nimpretty_t/releases)

- Or build from source (Linux example)

  ```sh
  git clone git@github.com:tobealive/nimpretty_t.git
  cd nimpretty_t
  nim c -d:release src/nimpretty_t.nim
  ln -s src/nimpretty_t ~/.local/bin/
  ```

### Format on Save

- **Neovim**

  Register `nimpretty_t` as `null-ls.nvim` source.

  ```lua
  local null_ls = require("null-ls")

  -- ...

  null_ls.register({
  	name = "nimpretty_t",
  	method = null_ls.methods.FORMATTING,
  	filetypes = { "nim" },
  	generator = null_ls.formatter({
  		command = "nimpretty_t",
  		args = { "$FILENAME" },
  		-- args = { "$FILENAME", "--maxLineLen=100" },  -- E.g., add options
  		to_temp_file = true,
  	}),
  })
  ```

- **VSCode / VSCodium**

  Requires the `Run on Save` Extension by emraldwalk.

  ```jsonc
  // settings.json
  // ...
  "emeraldwalk.runonsave": {
  	"commands": [
  		{
  			"match": "\\.nim$",
  			"isAsync": true,
  			"cmd": "nimpretty_t ${file}"
  			// "cmd": "nimpretty_t ${file} --maxLineLen=100" // E.g., add options
  		}
  	]
  }
  ```

## Disclaimer

It's early software. Things like mixing indentation styles might result in unexpected behavior during formatting. Feel free to reach out if you experience any issues and share a ★ if you don't consider it robbery.

## Credits

https://github.com/nim-lang/Nim
