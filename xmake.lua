set_project("meshoptimizer")
set_version("0.23")
set_languages("cxx11")

-- 配置选项
option("build_demo")
    set_default(false)
    set_showmenu(true)
    set_description("Build demo")
option_end()

option("build_gltfpack")
    set_default(false)
    set_showmenu(true)
    set_description("Build gltfpack")
option_end()

option("build_shared")
    set_default(false)
    set_showmenu(true)
    set_description("Build shared libraries")
option_end()

option("stable_exports")
    set_default(false)
    set_showmenu(true)
    set_description("Only export stable APIs from shared library")
option_end()

option("werror")
    set_default(false)
    set_showmenu(true)
    set_description("Treat warnings as errors")
option_end()

option("basisu_path")
    set_default("")
    set_showmenu(true)
    set_description("Path to Basis Universal library")
option_end()

-- 编译选项配置
if is_plat("windows") then
    add_cxflags("/W4")
else
    add_cxflags("-Wall", "-Wextra", "-Wshadow", "-Wno-missing-field-initializers")
end

if has_config("werror") then
    if is_plat("windows") then
        add_cxflags("/WX")
    else
        add_cxflags("-Werror")
    end
end

-- 主库目标
target("meshoptimizer")
    if has_config("build_shared") then
        set_kind("shared")
        set_symbols("hidden")
        
        if is_plat("windows") then
            add_defines("MESHOPTIMIZER_API=__declspec(dllexport)", {public = false})
            add_defines("MESHOPTIMIZER_API=__declspec(dllimport)", {interface = true})
        else
            add_defines("MESHOPTIMIZER_API=__attribute__((visibility(\"default\")))")
        end
        
        if has_config("stable_exports") then
            add_defines("MESHOPTIMIZER_EXPERIMENTAL=")
        end
    else
        set_kind("static")
    end
    
    add_files("src/allocator.cpp")
    add_files("src/clusterizer.cpp")
    add_files("src/indexanalyzer.cpp")
    add_files("src/indexcodec.cpp")
    add_files("src/indexgenerator.cpp")
    add_files("src/overdrawoptimizer.cpp")
    add_files("src/partition.cpp")
    add_files("src/quantization.cpp")
    add_files("src/rasterizer.cpp")
    add_files("src/simplifier.cpp")
    add_files("src/spatialorder.cpp")
    add_files("src/stripifier.cpp")
    add_files("src/vcacheoptimizer.cpp")
    add_files("src/vertexcodec.cpp")
    add_files("src/vertexfilter.cpp")
    add_files("src/vfetchoptimizer.cpp")
    
    add_headerfiles("src/meshoptimizer.h")
    add_includedirs("src", {public = true})
target_end()

-- Demo 目标
if has_config("build_demo") then
    target("demo")
        set_kind("binary")
        set_languages("cxx11")
        
        add_files("demo/main.cpp")
        add_files("demo/nanite.cpp")
        add_files("demo/tests.cpp")
        add_files("tools/objloader.cpp")
        
        add_deps("meshoptimizer")
    target_end()
end

-- gltfpack 目标
if has_config("build_gltfpack") then
    target("gltfpack")
        set_kind("binary")
        set_languages("cxx11")
        
        add_files("gltf/animation.cpp")
        add_files("gltf/basisenc.cpp")
        add_files("gltf/basislib.cpp")
        add_files("gltf/fileio.cpp")
        add_files("gltf/gltfpack.cpp")
        add_files("gltf/image.cpp")
        add_files("gltf/json.cpp")
        add_files("gltf/material.cpp")
        add_files("gltf/mesh.cpp")
        add_files("gltf/node.cpp")
        add_files("gltf/parseobj.cpp")
        add_files("gltf/parselib.cpp")
        add_files("gltf/parsegltf.cpp")
        add_files("gltf/stream.cpp")
        add_files("gltf/write.cpp")
        
        if is_plat("windows") then
            add_files("gltf/gltfpack.manifest")
        end
        
        add_deps("meshoptimizer")
        
        -- Basis Universal 支持
        if has_config("basisu_path") and get_config("basisu_path") ~= "" then
            local basisu_path = get_config("basisu_path")
            add_defines("WITH_BASISU")
            add_includedirs(basisu_path, {files = {"gltf/basisenc.cpp", "gltf/basislib.cpp"}})
            
            if not is_plat("windows") and is_arch("x86_64") then
                add_cxflags("-msse4.1", {files = "gltf/basislib.cpp"})
            end
            
            if is_plat("linux", "macosx") then
                add_syslinks("pthread")
            end
        end
        
        -- 设置 RPATH（仅在构建共享库时）
        if has_config("build_shared") then
            if is_plat("linux") then
                add_ldflags("-Wl,-rpath,$ORIGIN/../lib")
            elseif is_plat("macosx") then
                add_ldflags("-Wl,-rpath,@loader_path/../lib")
            end
        end
    target_end()
end

-- 安装规则
on_install(function (target)
    -- 安装库文件
    if target:name() == "meshoptimizer" then
        os.cp(target:targetfile(), path.join(target:installdir(), "lib"))
        os.cp("src/meshoptimizer.h", path.join(target:installdir(), "include"))
    elseif target:name() == "gltfpack" then
        os.cp(target:targetfile(), path.join(target:installdir(), "bin"))
    elseif target:name() == "demo" then
        os.cp(target:targetfile(), path.join(target:installdir(), "bin"))
    end
end)
