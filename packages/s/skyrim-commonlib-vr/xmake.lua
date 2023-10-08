-- This configuration is based on code from https://github.com/xmake-io/xmake-repo
-- License: Apache 2.0
-- Original xmake configuration for CommonLibSSE-NG project by Qudix (https://github.com/Qudix)
-- Modifications were made to the original code

package("skyrim-commonlib-vr")
    set_homepage("https://github.com/alandtse/CommonLibVR")
    set_description("A reverse engineered library for Skyrim Special Edition.")
    set_license("MIT")

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

    on_load("windows|x64", function(package)
        package:add("defines", "SKYRIMVR", "_CRT_SECURE_NO_WARNINGS")
    end)

    on_install("windows|x64", function(package)
        -- Clone main repo manually (to tweak .gitmodules)
        os.vrun("git clone https://github.com/alandtse/CommonLibVR.git")
        os.cd("CommonLibVR")

        -- Replace SSH paths with HTTPS in .gitmodules (for Windows users without SSH keys)
        local gitmodules_path = ".gitmodules"
        if os.isfile(gitmodules_path) then
            local content = io.readfile(gitmodules_path)
            content = content:gsub("git@github.com:", "https://github.com/")
            io.writefile(gitmodules_path, content)
        end

        -- Update submodules
        os.vrun("git add .gitmodules")
        os.vrun("git submodule init")
        os.vrun("git submodule update --init --recursive")

        os.cd("..")
        os.cp("CommonLibVR/*", ".")

        -- Evil! Let's make sure that SFTypes is included super early, so replace the #pragma one with the include
        -- I'm sure there'a another way to make this work, but - hey - this works (for now)
        local pch_path = "include/SKSE/Impl/PCH.h"
        local content = io.readfile(pch_path)
        content = content:gsub("#pragma once", "#pragma once\n\n// SFTypes first (cstddef for size_t/ptrdiff_t, limits for numeric_limits):\n#include <cstddef>\n#include <limits>\n#include \"RE/S/SFTypes.h\"\n")
        io.writefile(pch_path, content)

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
