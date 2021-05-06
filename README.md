This plugin provides commands for using the build system to which the
current file belongs. It searches from each files directory upwards for
Makefiles and the like.

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
CMake. Optional arguments can be provided and will be passed directly to
cmake:

```vim
:Build init -DCMAKE_BUILD_TYPE=Release
```

Here are some examples for invoking cmake. Additional arguments will be
passed directly to cmake:

```vim
:Build build
:Build build --target some_cmake_target
:Build test
:Build clean
```

**Note**: Running `:Build` without any arguments is equivalent to `:Build build`.

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
:Build init -DCMAKE_BUILD_TYPE=Release
:Build
:Build --target my_target
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
:Build init --enable-gtk --without-foo --prefix="$HOME/.local"
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

```vim
:Build run
```
