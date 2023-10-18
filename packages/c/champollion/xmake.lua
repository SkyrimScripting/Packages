package("champollion")
    set_homepage("https://github.com/Orvid/Champollion")
    set_description("A description for Champollion")
    add_urls("https://github.com/Orvid/Champollion.git")
    
    add_configs("standalone", { description = "Compile as a static library.", default = false, type = "boolean"})

    on_install(function(package)
        local configs = {}
        if package:config("standalone") then
            table.insert(configs, "-DCHAMPOLLION_STATIC_LIBRARY=ON")
        else
            table.insert(configs, "-DCHAMPOLLION_STATIC_LIBRARY=OFF")
        end
        
        import("package.tools.cmake").install(package, configs)
        
        if package:config("standalone") then
            os.mv("$(package:installdir())/lib/cmake/Champollion", "$(package:installdir())/lib/cmake/ChampollionStatic")
        end

        os.cp("$(package:installdir())/LICENSE", "$(package:installdir())/share/Champollion/copyright")
    end)
    
    on_test(function(package)
        -- 
    end)
