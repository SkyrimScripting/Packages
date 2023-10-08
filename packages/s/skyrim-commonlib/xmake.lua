-- This configuration is based on code from https://github.com/xmake-io/xmake-repo
-- License: Apache 2.0
-- Original xmake configuration for CommonLibSSE-NG project by Qudix (https://github.com/Qudix)
-- Modifications were made to the original code

-- Default "skyrim-commonlib" ---> NG (it's a complete copy for the rules to work OK)
package("skyrim-commonlib")
    set_homepage("https://github.com/CharmedBaryon/CommonLibSSE-NG")
    set_description("A reverse engineered library for Skyrim Special Edition.")
    set_license("MIT")

    add_urls("https://github.com/CharmedBaryon/CommonLibSSE-NG/archive/$(version).zip",
             "https://github.com/CharmedBaryon/CommonLibSSE-NG.git")

    add_configs("xbyak", {description = "Enable trampoline support for Xbyak", default = false, type = "boolean"})
    add_configs("se", {description = "Enable runtime support for Skyrim SE", default = true, type = "boolean"})
    add_configs("ae", {description = "Enable runtime support for Skyrim AE", default = true, type = "boolean"})
    add_configs("vr", {description = "Enable runtime support for Skyrim VR", default = true, type = "boolean"})

    add_deps("fmt", "rapidcsv")
    add_deps("spdlog", { configs = { header_only = false, fmt_external = true } })

    add_syslinks("version", "user32", "shell32", "ole32", "advapi32")

    on_load("windows|x64", function(package)
        if package:config("se") then
            package:add("defines", "ENABLE_SKYRIM_SE=1")
        end
        if package:config("ae") then
            package:add("defines", "ENABLE_SKYRIM_AE=1")
        end
        if package:config("vr") then
            package:add("defines", "ENABLE_SKYRIM_VR=1")
        end
        if package:config("xbyak") then
            package:add("defines", "SKSE_SUPPORT_XBYAK=1")
            package:add("deps", "xbyak")
        end

        package:add("defines", "HAS_SKYRIM_MULTI_TARGETING=1")
    end)

    on_install("windows|x64", function(package)
        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")

        local options = {}
        options.se = package:config("se")
        options.ae = package:config("ae")
        options.vr = package:config("vr")
        options.xbyak = package:config("xbyak")

        import("package.tools.xmake").install(package, options)
    end)

    on_test("windows|x64", function(package)
        assert(package:check_cxxsnippets({test = [[
            #include <SKSE/SKSE.h>

            SKSEPluginLoad(const SKSE::LoadInterface*) {
                return true;
            };
        ]]}, { configs = { languages = "c++20" } }))
    end)