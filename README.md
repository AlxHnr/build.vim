This plugin provides commands wrapping the build system to which the
current file belongs. It searches from each files directory upwards for
Makefiles and the like. Two commands are provided:

* **:Build** - To build/run a target
* **:BuildInit** - To initialize/configure builds

**Note**: If the current file doesn't belong to any known build system, it
will be build using associated compilers. E.g. C files will be build using
gcc.

# Usage Examples

## CMake

Your project looks like this:

```
├── CMakeLists.txt
└── src/
    └── main.cpp
```

Open any file in the project and use the following command to initialize
CMake. Optional arguments can be provided:

```vim
:BuildInit -DCMAKE_BUILD_TYPE=Release
```

Build, run and test the project by passing build targets to cmake:

```vim
:Build build
:Build run
:Build test
:Build clean
```

**Note**: If `:Build` is run without any arguments it is equivalent to
`:Build build`, which corresponds to the `all` target.

## Autotools

Your project looks like this:

```
├── configure
├── Makefile.in
├── LICENSE
├── README
└── src/
    └── main.c
    └── foo.h
    └── foo.c
```

Open any file in the project and initialize the build using the following
command. Optional configure flags can be provided:

```vim
:BuildInit --enable-gtk --without-foo --prefix="$HOME/.local"
```

Then run `make`:

```vim
:Build
:Build test
:Build clean
:Build build -j8 --keep-going --dry-run
```

## Plain C files

Build and run a standalone C file if no build system could be detected:

```vim
:Build
:Build run
:Build clean
```

Rebuild the current file with other CFLAGS:

```vim
:Build build -Wall -Wextra -Werror -pedantic
```

## Python, Bash and other scripting languages

Run the current file if no build system could be detected:

```vim
:Build run
```
