# Skyrim Packages (`xmake` and `vcpkg`)

> _Note: most packages are only available thru xmake at this time_

## xmake

To use these xmake packages, add the following to your `xmake.lua` file:

```lua
add_repositories("SkyrimScripting https://github.com/SkyrimScripting/Packages.git")
```

## WIP

_Currently, all of the non-CommonLib packages container here are a work in progress!_

_Recommend against using them for now!_

## CommonLib

`xmake` packages available:

- `skyrim-commonlib` ( _Alias for `skyrim-commonlib-ng`_ )
- `skyrim-commonlib-vr` ( _Adds dependency on @alandtse's [CommonLibVR](https://github.com/alandtse/CommonLibVR)_ )
- `skyrim-commonlib-ng` ( _Adds dependency on @CharmedBaryon's [CommonLibSSE-NG](https://github.com/CharmedBaryon/CommonLibSSE-NG)_ )
- `skyrim-commonlib-ae` ( _Adds dependency on @powerof3's [CommonLibSSE](https://github.com/powerof3/CommonLibSSE)_ configured for Skyrim 1.6+ compatibility )
- `skyrim-commonlib-se` ( _Adds dependency on @powerof3's [CommonLibSSE](https://github.com/powerof3/CommonLibSSE)_ configured for Skyrim 1.5.97 compatibility )

### Basic Usage

To use one of these CommonLib packages:

```lua
add_requires("skyrim-commonlib")

target("My-SKSE-Plugin")
    add_files("plugin.cpp")
    add_packages("skyrim-commonlib")
```

### Xbyak Support

To enable [xbyak](https://github.com/herumi/xbyak) support, enable the `xybak` option (available for any version):

```lua
add_requires("skyrim-commonlib", { configs = { xbyak = true } })
```

This will provide the following function (_which is otherwise unavailable_):

```cpp
SKSE::Trampoline::allocate(Xbyak::CodeGenerator& codeGenerator)
```

### Mod Folder Deployment

Optionall, you can define one or more "mods" folders to deploy the plugin dll/pdb to:

```lua
add_requires("skyrim-commonlib")

target("My-SKSE-Plugin")
    add_files("plugin.cpp")
    add_packages("skyrim-commonlib")
    add_rules("@skyrim-commonlib/plugin", {
        -- This will output to the following generated folder location:
        --  C:/Path/to/my/mods/My-SKSE-Plugin/SKSE/Plugins/My-SKSE-Plugin.dll
        mods_folder = "C:/Path/to/my/mods"
    })
```

If you have multiple mods folders, you can specify them as a list:

```lua
add_requires("skyrim-commonlib")

target("My-SKSE-Plugin")
    add_files("plugin.cpp")
    add_packages("skyrim-commonlib")
    add_rules("@skyrim-commonlib/plugin", {
        mod_folders = { "C:\...", "C:\..." }
    })
```

Paths containing a `;` are split, allowing for use of an environment varialbe to specify multiple output paths:

```lua
add_requires("skyrim-commonlib")

target("My-SKSE-Plugin")
    add_files("plugin.cpp")
    add_packages("skyrim-commonlib")
    add_rules("@skyrim-commonlib/plugin", {
        mod_folders = os.getenv("SKYRIM_MOD_FOLDERS")
    })
```

> _xmake configuration based on official CommonLibSSE-NG xmake package configuration:_  
> _https://github.com/xmake-io/xmake-repo_  
> _License: Apache 2.0_  
> 
> _Configuration above was authored by by Qudix (https://github.com/Qudix)_  
>
> _Modifications were made to the original code_
