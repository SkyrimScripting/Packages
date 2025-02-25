-- This configuration is based on code from https://github.com/xmake-io/xmake-repo
-- License: Apache 2.0
-- Original xmake configuration for CommonLibSSE-NG project by Qudix (https://github.com/Qudix)
-- Modifications were made to the original code

rule("plugin")

    add_deps("win.sdk.resource")

    before_build(function(target)
        target:add("packages", "skyrim-commonlib-ng")
    end)

    on_config(function(target)
        import("core.base.semver")
        import("core.project.depend")
        import("core.project.project")

        target:add("defines", "UNICODE", "_UNICODE")

        target:set("kind", "shared")
        target:set("arch", "x64")
        target:set("languages", "cxxlatest")
        target:add("cxxflags", "/Zc:__cplusplus")

        local config = target:extraconf("rules", "@skyrim-commonlib-ng/plugin")

        if config.ae ~= false then
            target:add("defines", "ENABLE_SKYRIM_AE=1")
        end

        if config.se ~= false then
            target:add("defines", "ENABLE_SKYRIM_SE=1")
        end

        if config.vr ~= false then
            target:add("defines", "ENABLE_SKYRIM_VR=1")
        end

        if config.xbyak then
            target:add("defines", "SKSE_SUPPORT_XBYAK=1")
        end

        local plugin_name = config.name or target:name()
        local author_name = config.author or ""
        local author_email = config.email or ""

        local version = semver.new(config.version or target:version() or "0.0.0")
        local version_string = string.format("%s.%s.%s", version:major(), version:minor(), version:patch())

        local product_version = semver.new(config.product_version or project.version() or config.version or target:version() or "0.0.0")
        local product_version_string = string.format("%s.%s.%s", product_version:major(), product_version:minor(), product_version:patch())

        local output_files_folder = path.join(target:autogendir(), "rules", "skyrim-commonlib-ng", "plugin")

        local version_file = path.join(output_files_folder, "version.rc")
        depend.on_changed(function()
            local file = io.open(version_file, "w")
            if file then
                file:print("#include <winres.h>\n")
                file:print("1 VERSIONINFO")
                file:print("FILEVERSION %s, %s, %s, 0", version:major(), version:minor(), version:patch())
                file:print("PRODUCTVERSION %s, %s, %s, 0", product_version:major(), product_version:minor(), product_version:patch())
                file:print("FILEFLAGSMASK 0x17L")
                file:print("#ifdef _DEBUG")
                file:print("    FILEFLAGS 0x1L")
                file:print("#else")
                file:print("    FILEFLAGS 0x0L")
                file:print("#endif")
                file:print("FILEOS 0x4L")
                file:print("FILETYPE 0x1L")
                file:print("FILESUBTYPE 0x0L")
                file:print("BEGIN")
                file:print("    BLOCK \"StringFileInfo\"")
                file:print("    BEGIN")
                file:print("        BLOCK \"040904b0\"")
                file:print("        BEGIN")
                file:print("            VALUE \"FileDescription\", \"%s\"", config.description or "")
                file:print("            VALUE \"FileVersion\", \"%s.0\"", version_string)
                file:print("            VALUE \"InternalName\", \"%s\"", config.name or target:name())
                file:print("            VALUE \"LegalCopyright\", \"%s, %s\"", config.author or "", config.license or target:license() or "Unknown License")
                file:print("            VALUE \"ProductName\", \"%s\"", config.product_name or project.name() or config.name or target:name())
                file:print("            VALUE \"ProductVersion\", \"%s.0\"", product_version_string)
                file:print("        END")
                file:print("    END")
                file:print("    BLOCK \"VarFileInfo\"")
                file:print("    BEGIN")
                file:print("        VALUE \"Translation\", 0x409, 1200")
                file:print("    END")
                file:print("END")
                file:close()
            end
        end, { dependfile = target:dependfile(version_file), files = project.allfiles()})

        local plugin_file = path.join(output_files_folder, "plugin.cpp")
        depend.on_changed(function()
            local file = io.open(plugin_file, "w")
            if file then
                local struct_compat = "Independent"
                local runtime_compat = "AddressLibrary"

                if config.options then
                    local address_library = config.options.address_library or true
                    local signature_scanning = config.options.signature_scanning or false
                    if not address_library and signature_scanning then
                        runtime_compat = "SignatureScanning"
                    end
                end

                file:print("#include <SKSEPluginInfo.h>")
                file:print("")
                file:print("using namespace std::literals;\n")
                file:print("")
                file:print("SKSEPluginInfo(")
                file:print("    .Version = { %s, %s, %s, 0 },", version:major(), version:minor(), version:patch())
                file:print("    .Name = \"%s\"sv,", plugin_name)
                file:print("    .Author = \"%s\"sv,", author_name)
                file:print("    .SupportEmail = \"%s\"sv,", author_email)
                file:print("    .StructCompatibility = SKSE::StructCompatibility::%s,", struct_compat)
                file:print("    .RuntimeCompatibility = SKSE::VersionIndependence::%s", runtime_compat)
                file:print(")")
                file:print("")
                file:print("// For standard access from your SKSE plugin")
                file:print("// These are functions for flexibility")
                file:print("// Note: could also have these use NG's PluginDeclaration if desired")
                file:print("namespace SKSEPluginInfo {")
                file:print("    const char* GetPluginName() { return \"" .. plugin_name .. "\"; }")
                file:print("    const char* GetAuthorName() { return \"" .. author_name .. "\"; }")
                file:print("    const char* GetAuthorEmail() { return \"" .. author_email .. "\"; }")
                file:print("    const REL::Version GetPluginVersion() { return REL::Version{" .. version:major() .. ", " .. version:minor() .. ", " .. version:patch() .. "}; }")
                file:print("}")
                file:print("")
                file:close()
            end
        end, { dependfile = target:dependfile(plugin_file), files = project.allfiles()})

        target:add("files", version_file)
        target:add("files", plugin_file)

        -- target:add("cxxflags", "/permissive-", "/Zc:alignedNew", "/Zc:__cplusplus", "/Zc:forScope", "/Zc:ternary")
        -- target:add("cxxflags", "cl::/Zc:externConstexpr", "cl::/Zc:hiddenFriend", "cl::/Zc:preprocessor", "cl::/Zc:referenceBinding")
    end)

after_build(function(target)
    local game_version = "ng"

    import("core.base.table")

    -- Use `game_version` in the extraconf call:
    local config = target:extraconf("rules", "@skyrim-commonlib-" .. game_version .. "/plugin")

    local dll = target:targetfile()
    local pdb = dll:gsub("%.dll$", ".pdb")

    -- copy config.mod_files to avoid mutation
    local base_mod_files = config.mod_files or {}
    local mod_files = {}
    for _, file in ipairs(base_mod_files) do
        table.insert(mod_files, file)
    end
    table.insert(mod_files, dll)
    if os.isfile(pdb) then
        table.insert(mod_files, pdb)
    end

    -- Now do your copying logic
    local all_folders_set = {}
    local mod_names = { "mod_folder", "mods_folder", "mods_folders", "mod_folders" }

    for _, mod_name in ipairs(mod_names) do
        local mod_value = config[mod_name]
        if mod_value then
            if type(mod_value) == "table" then
                for _, entry in ipairs(mod_value) do
                    for _, item in ipairs(split(entry, ";")) do
                        if item ~= "" then
                            addToSet(all_folders_set, item)
                        end
                    end
                end
            elseif type(mod_value) == "string" then
                for _, item in ipairs(split(mod_value, ";")) do
                    if item ~= "" then
                        addToSet(all_folders_set, item)
                    end
                end
            end
        end
    end

    local mod_folders = {}
    for folder in pairs(all_folders_set) do
        table.insert(mod_folders, folder)
    end

    local mod_name = config.mod_name or config.name or target:name()

    for _, mods_folder in ipairs(mod_folders) do
        local mod_folder = path.join(mods_folder, mod_name)
        for _, mod_file in ipairs(mod_files) do
            if os.isfile(mod_file) then
                local mod_file_target = path.join(mod_folder, path.filename(mod_file))
                if mod_file == dll or mod_file == pdb then
                    mod_file_target = path.join(mod_folder, "SKSE", "Plugins", path.filename(mod_file))
                end

                local mod_file_target_dir = path.directory(mod_file_target)
                if not os.isdir(mod_file_target_dir) then
                    os.mkdir(mod_file_target_dir)
                end

                if os.isfile(mod_file_target) then
                    os.rm(mod_file_target)
                end
                os.cp(mod_file, mod_file_target_dir)

            elseif os.isdir(mod_file) then
                local mod_folder_target = path.join(mod_folder, path.filename(mod_file))
                print("[" .. game_version .. "] Copying directory " .. mod_file .. " to " .. mod_folder_target)

                if not os.isdir(mod_folder_target) then
                    os.mkdir(mod_folder_target)
                end

                for _, file in ipairs(os.files(path.join(mod_file, "*"))) do
                    local target_file = path.join(mod_folder_target, path.filename(file))
                    if os.isfile(target_file) then
                        print("Deleting file: " .. target_file)
                        os.rm(target_file)
                    end
                    print("Copying file: " .. file .. " to " .. mod_folder_target)
                    os.cp(file, mod_folder_target)
                end

                for _, dir in ipairs(os.dirs(path.join(mod_file, "*"))) do
                    local target_dir = path.join(mod_folder_target, path.filename(dir))
                    if os.isdir(target_dir) then
                        print("Deleting directory: " .. target_dir)
                        os.rmdir(target_dir)
                    end
                    print("Copying directory: " .. dir .. " to " .. target_dir)
                    os.cp(dir, target_dir)
                end
            else
                print("[" .. game_version .. "] File or directory not found: " .. mod_file)
            end
        end
    end
end)