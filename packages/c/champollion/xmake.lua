package("champollion")
    set_homepage("https://github.com/mrowrpurr/Champollion")
    set_description("A PEX to Papyrus Decompiler for Skyrim, Fallout 4 and Starfield")
    add_urls("https://github.com/mrowrpurr/Champollion.git")
    add_versions("mrowrpurr", "mrowrpurr")
    on_install(function(package)
        local configs = {
            "-DCHAMPOLLION_STATIC_LIBRARY=ON",
            "-DCMAKE_TOOLCHAIN_FILE=",
            "-DVCPKG_MANIFEST_MODE=OFF",
        }
        if package:debug() then
            table.insert(configs, "-DCMAKE_BUILD_TYPE=Debug")
        else
            table.insert(configs, "-DCMAKE_BUILD_TYPE=Release")
        end
        import("package.tools.cmake").install(package, configs, {envs = {VCPKG_ROOT = ""}})
    end)
