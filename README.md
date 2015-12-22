# Build.vim

This plugin builds and runs projects or even single source files using the
right tool. It works by searching for known build files from the current
files path upwards, and will fall back to language specific build commands
otherwise.

## Usage

Just open a source file and run it using `:Build run`. Some files need to
be build in advance with the `:Build` command. Various build systems must
be initialized with `:BuildInit` before they can be used.

The variable `b:build_system_name` will be set if the current file belongs
to a supported build system.

Common build targets are _build_, _run_, _clean_ and _test_.

## Supported build systems and languages

The following build systems are supported:

  * [Autotools](http://www.gnu.org/software/autoconf/)
  * [Cargo](https://crates.io/)
  * [CMake](http://www.cmake.org/)
  * [Make](https://en.wikipedia.org/wiki/Make_(software))
  * [DUB](http://code.dlang.org/)

Please mind that build systems are often a mess and some projects use more
than one, so this plugin will simply use the first one it finds.

If no build system could be found, it provides fallback commands to build
and run these filetypes: C, C++, D, Java, OCaml, Racket, Rust and (La)Tex.

The _run_ target supports running the following languages like normal
scripts if they have a
[shebang](http://en.wikipedia.org/wiki/Shebang_(Unix)): sh, csh, tcsh, zsh,
sed, awk, lua, python, ruby, perl, perl6, tcl, scheme.

To extend and customize build systems, rules and language specific
commands, take a look at the documentation of this plugin.

## Commands

### Build

This command takes an arbitrary amount of arguments. If no argument was
given, it will try to build the _build_ target. Otherwise the first
argument must be a valid target name. If the current file doesn't belong to
any known build system, it will use language specific commands to build
only this file alone.

Besides the target name, it takes an arbitrary amount of additional
arguments, which will be passed directly to the build command. The caller
must take care of quoting and escaping those arguments.

### BuildInit

This command takes an arbitrary amount of arguments and will pass them
directly to the build systems init command. The caller must take care of
quoting and escaping those arguments. If the current build system has no
init command, it will stop with a message.

## Configuration

### g:build#autochdir

If this variable is set to 1 and this plugin finds a build file, it will
change the working directory of the current buffer to the build files
directory.

## License

Released under the zlib license.
