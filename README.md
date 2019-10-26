This plugin provides commands for using the build system to which the
current file belongs. It searches from each files directory upwards for
Makefiles and the like. These commands are provided:

* **:Build** - Build/run a target
* **:BuildInit** - Initialize/configure a build
* **:BuildInfo** - Print build informations for the current file

**Note**: If the current file does not belong to any known build systems,
it will be build using associated compilers. E.g. C files will be build
using gcc.

# Usage Examples

## CMake

Your project may look like this:

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

The `:Build` command runs `make` inside the build directory. It takes
optional arguments which will be passed directly to `make`:

```vim
:Build
:Build all
:Build test
:Build clean
```

## Autotools

Your project may look like this:

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

Open any file in the project and configure the build using the following
command. Optional configure flags can be provided:

```vim
:BuildInit --enable-gtk --without-foo --prefix="$HOME/.local"
```

Then run `make` using the `:Build` command:

```vim
:Build
:Build test
:Build clean
:Build -j8 --keep-going --dry-run
```

## Plain C files

If the current file does not belong to a build system, it can be compiled
using the `:Build` command. This plugin defines three build targets for C
files:

```vim
:Build build
:Build run
:Build clean
```

Pass custom arguments to the compiler:

```vim
:Build build -Wall -Wextra -Werror -pedantic
```

## Python, Bash and other scripting languages

For some files which don't belong to a build system, the `run` target will
be defined:

```vim
:Build run
```
