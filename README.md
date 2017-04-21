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
