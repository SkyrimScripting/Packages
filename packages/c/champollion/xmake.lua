package("champollion")
    set_homepage("https://github.com/SkyrimScriptingBeta/Champollion")
    set_description("A PEX to Papyrus Decompiler for Skyrim, Fallout 4 and Starfield")
    add_urls("https://github.com/SkyrimScriptingBeta/Champollion.git")
    add_versions("mrowrpurr", "mrowrpurr")
    on_install(function(package)
        local configs = {"-DCHAMPOLLION_STATIC_LIBRARY=ON"}
        if package:debug() then
            table.insert(configs, "-DCMAKE_BUILD_TYPE=Debug")
        else
            table.insert(configs, "-DCMAKE_BUILD_TYPE=Release")
        end
        import("package.tools.cmake").install(package, configs)
    end)
