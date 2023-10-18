package("champollion")
    set_homepage("https://github.com/Orvid/Champollion")
    set_description("A description for Champollion")
    add_urls("https://github.com/Orvid/Champollion.git")
    on_install(function(package)
        local configs = {"-DCHAMPOLLION_STATIC_LIBRARY=ON"}
    
        if package:debug() then
            table.insert(configs, "-DCMAKE_BUILD_TYPE=Debug")
        else
            table.insert(configs, "-DCMAKE_BUILD_TYPE=Release")
        end

        import("package.tools.cmake").install(package, configs)
    end)
