This plugin provides commands for using the build system to which the
current file belongs. It searches from each files directory upwards for
Makefiles and the like. These commands are provided:

* **:Build** - General purpose command for common tasks (build, run, clean...)
* **:BuildInit** - Initialize/configure a build
* **:BuildInfo** - Print build informations for the current file
* **:BuildRefresh** - Force a fresh discovery of build system

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
:Build " equivalent to :Build build, build the default target
:Build build all " build the all target
:Build test " run the tests
:Build clean " clean the directory
:Build run " run the current file or the whole project depending on the build system
```

### CMake with subdirectories

Your project may look like this:

```
├── CMakeLists.txt
├── src/
│   └── main.cpp
└── util/
    ├── CMakeLists.txt
    ├── util.cpp
    └── misc/
        ├── CMakeLists.txt
        └── misc.cpp
```

Set the current working directory to the directory containing the main `CMakeLists.txt` and proceed
as in the previous example:

```vim
:lchdir ~/path/to/project
:BuildInit -DCMAKE_BUILD_TYPE=Release
:Build
```

**Note**: You can use [this plugin](https://github.com/AlxHnr/project-chdir.vim) to set the working
directory automatically.

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
:Build clean
:Build build -j8 --keep-going --dry-run
```

## Plain C files

If the current file does not belong to a build system, it can be compiled
using the `:Build` command. This plugin defines three subcommands for C files:

```vim
:Build build
:Build run
:Build clean
```

Pass custom arguments to the compiler:

```vim
:Build build -Wall -Wextra -Werror -pedantic
```

**Note**: If `:Build` is called without arguments it will be equivalent to `:Build build`.

## Python, Bash and other scripting languages

For some files which don't belong to a build system, the `run` target will
be defined:
It relies on the capacity of the system to directly run those files directly, which imply that you should define a shebang at the begining of the
file.

For example for python
```python
#!/usr/bin/env python3
```

```vim
:Build run
```
