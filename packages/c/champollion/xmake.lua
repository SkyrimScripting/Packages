package("champollion")
    set_homepage("https://github.com/SkyrimScriptingBeta/Champollion")
    set_description("A PEX to Papyrus Decompiler for Skyrim, Fallout 4 and Starfield")
    add_urls("https://github.com/SkyrimScriptingBeta/Champollion.git")
    add_versions("mrowrpurr", "mrowrpurr")

    add_configs("kind", {description = "Library type (static or shared)", default = "static", values = {"static", "shared"}})
    add_configs("build_exe", {description = "Build the Champollion command-line executable", default = false, type = "boolean"})

    on_load(function(package)
        if package:config("build_exe") then
            package:add("deps", "boost", {configs = {program_options = true}})
            package:add("deps", "fmt")
        end
    end)

    on_install(function(package)
        local configs = {}
        configs.kind = package:config("kind")
        configs.build_exe = package:config("build_exe")
        import("package.tools.xmake").install(package, configs)
    end)
