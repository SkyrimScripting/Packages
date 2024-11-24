# Skyrim Packages (`xmake` and `vcpkg`)

> _Note: packages are only available thru xmake at this time_

## xmake

To use these xmake packages, add the following to your `xmake.lua` file:

```lua
add_repositories("SkyrimScripting https://github.com/SkyrimScripting/Packages.git")
```

## Packages

- `skyrim-commonlib`
- `skyrim-commonlib-vr`
- `skyrim-commonlib-ng`
- `skyrim-commonlib-ae`
- `skyrim-commonlib-se`
- _Other packages in this repo are a work in progress and I wouldn't use them yet!_

## CommonLib

`xmake` packages available:

- `skyrim-commonlib` ( _Alias for `skyrim-commonlib-ng`_ )
- `skyrim-commonlib-vr` ( _Adds dependency on @alandtse's [CommonLibVR](https://github.com/alandtse/CommonLibVR)_ )
- `skyrim-commonlib-ng` ( _Adds dependency on @CharmedBaryon's [CommonLibSSE-NG](https://github.com/CharmedBaryon/CommonLibSSE-NG)_ )
- `skyrim-commonlib-ae` ( _Adds dependency on @powerof3's [CommonLibSSE](https://github.com/powerof3/CommonLibSSE)_ configured for Skyrim 1.6+ compatibility )
- `skyrim-commonlib-se` ( _Adds dependency on @powerof3's [CommonLibSSE](https://github.com/powerof3/CommonLibSSE)_ configured for Skyrim 1.5.97 compatibility )

### Basic Usage

#### `skyrim-commonlib`

To use one of these CommonLib packages:

```lua
add_requires("skyrim-commonlib")

target("My-SKSE-Plugin")
    add_files("plugin.cpp")
    add_packages("skyrim-commonlib")
    add_rules("@skyrim-commonlib/plugin", {
        name = "My-SKSE-Plugin", -- This defaults to the target name
        version = "420.1.69", -- This defaults to the target version or "0.0.0"
        author = "Mrowr Purr",
        email = "mrowr.purr@gmail.com",
        mods_folder = os.getenv("MO2_or_VORTEX_mods_folder_path"),
        mod_files = {"Scripts", "", "AnythingToDeployToTheModFolder"}
    })
```

#### `skyrim-commonlib-vr` (_or any other package_)

Or any of the other packages listed above:

```lua
add_requires("skyrim-commonlib-vr")

target("My-SKSE-Plugin")
    add_files("plugin.cpp")
    add_packages("skyrim-commonlib-vr")
```

##### `add_rules`

> The body of `add_rules` is optional, it is valid to simply:
>
> ```lua
> target("My-SKSE-Plugin")
>     add_files("plugin.cpp")
>     add_packages("skyrim-commonlib")
>     add_rules("@skyrim-commonlib/plugin")

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

#### `mods_folder`

Optionally, you can define one or more "mods" folders to deploy the plugin dll/pdb to:

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

    -- Note: use the rule with a name matching the package that you are using:
    -- add_rules("@skyrim-commonlib/plugin", {...
    -- add_rules("@skyrim-commonlib-vr/plugin", {...
    -- add_rules("@skyrim-commonlib-ae/plugin", {...
    -- add_rules("@skyrim-commonlib-se/plugin", {...
    -- add_rules("@skyrim-commonlib-vr/plugin", {...
```

If you have multiple mods folders, you can specify them as a list:

```lua
add_requires("skyrim-commonlib")

target("My-SKSE-Plugin")
    add_files("plugin.cpp")
    add_packages("skyrim-commonlib")
    add_rules("@skyrim-commonlib/plugin", {
        mod_folders = { "C:/...", "C:/..." }
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

#### `mod_files`

You can also specify additional files to deploy to the mod folder:

```lua
add_requires("skyrim-commonlib")

target("My-SKSE-Plugin")
    add_files("plugin.cpp")
    add_packages("skyrim-commonlib")
    add_rules("@skyrim-commonlib/plugin", {
        mod_files = { "Scripts", "", "AnythingToDeployToTheModFolder" }
    })
```

> _xmake configuration based on official CommonLibSSE-NG xmake package configuration:_
> _https://github.com/xmake-io/xmake-repo_
> _License: Apache 2.0_
>
> _Configuration above was authored by by Qudix (https://github.com/Qudix)_
>
> _Modifications were made to the original code_
