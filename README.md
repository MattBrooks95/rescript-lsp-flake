## Goal
- get Rescript's LSP working in a project flake as a `buildInput`, kind of like this:
    ```
    in {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs_20
        rescript-language-server
      ];
    };
    ```
- at first I just wanted to hack it together so I could use the LSP as I try to learn Rescript, but that didn't go well and I figured it would probably be better to try and package it so that other Nix users could use it as well.

## Why
- I don't want to globally install packages to use a language server, I want the language server to only exist in the project directory where I need it
- I want the development environment of the project to be reproducible

## Troubles
- simply installing the rescript language server into the project's package.json doesn't work because Neovim's LSP uses the command "rescript-language-server --stdio". This won't work so I tried to (in my init.lua neovim configuartion file) tell it to instead use the command "npx @rescript/language-server stdio", which works in the terminal. It fails because it says the command could not be found or is not executable.
- I thought it would be simple to import Rescript's language server repo into my project flake as source and then build & use it there, but that also does not work because nix flakes forbid downloading when building a derivation, so the rescript laguage server project's build script fail.
- I think if the project was a single NPM package, packaging it with the Nix utility `buildNpmPackage` may not be difficult, but there are at least three packages in the repo.
    - /server <- is the server that lets the rescript language server client (vscode, neovim...) talk to the compiler toolchain (a reason/ocaml project)
    - /client <- is the vscode extension that allows vscode to talk to the rescript language server
    - the top level package.json installs some packages (chokidar, vscode libraries for making extensions/doing LSP)
- The 'postinstall' step for building the top-level NPM package is hairy and doesn't work well with Nix:``
    ```
	"scripts": {
		...
		"postinstall": "cd server && npm i && cd ../client && npm i && cd ../tools && npm i && cd ../tools/tests && npm i && cd ../../analysis/tests && npm i && cd ../reanalyze/examples/deadcode && npm i && cd ../termination && npm i",
		...
	},
    ```
- I tried running buildNpmPackage for each of the packages separately (root level, /server and /client) but the Nix evaluation fails beacuse it tries to run the hairy 'postinstall' script, even though I think I told it not to do that by setting the `dontNpmBuild` and `dontNpmInstall` flags to `buildNpmPackage`, because I want to write the build phase myself.

## Links
[rescript](https://rescript-lang.org/)
[target NPM package](https://www.npmjs.com/package/@rescript/language-server)
[advice for packaging Javascript](https://nixos.org/manual/nixpkgs/stable/#javascript)
