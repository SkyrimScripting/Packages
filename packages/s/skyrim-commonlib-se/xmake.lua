-- This configuration is based on code from https://github.com/xmake-io/xmake-repo
-- License: Apache 2.0
-- Original xmake configuration for CommonLibSSE-NG project by Qudix (https://github.com/Qudix)
-- Modifications were made to the original code

package("skyrim-commonlib-se")
    set_homepage("https://github.com/powerof3/CommonLibSSE")
    set_description("A reverse engineered library for Skyrim Special Edition.")
    set_license("MIT")

    add_urls("https://github.com/powerof3/CommonLibSSE.git")

    add_deps("fmt", "rsm-binary-io", "vcpkg::boost-stl-interfaces")
    add_deps("spdlog", { configs = { header_only = false, fmt_external = true } })

    add_syslinks("version", "user32", "shell32", "ole32", "advapi32")

    add_configs("xbyak", {description = "Enable trampoline support for Xbyak", default = false, type = "boolean"})

    on_load("windows|x64", function(package)
        if package:config("xbyak") then
            package:add("defines", "SKSE_SUPPORT_XBYAK=1")
            package:add("deps", "xbyak")
        end
    end)

    on_install("windows|x64", function(package)
        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")

        import("package.tools.xmake").install(package, {
            xbyak = package:config("xbyak")
        })

        -- Evil! Let's inject the 'SKSEPluginLoad' macro for compatibility with NG
        local skse_header_path = path.join(package:installdir(), "include/SKSE/SKSE.h")
        local content = io.readfile(skse_header_path)
        content = content .. "\n#define SKSEPluginLoad extern \"C\" __declspec(dllexport) bool SKSEPlugin_Load"
        io.writefile(skse_header_path, content)
    end)
