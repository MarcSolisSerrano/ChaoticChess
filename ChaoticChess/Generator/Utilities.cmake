
function(GetDefaultCppHeaderFileExtensions out_extensions)
	set(${out_extensions} "*.h" "*.hpp" "*.inl" PARENT_SCOPE)
endfunction()

function(GetDefaultCppSourceFileExtensions out_extensions)
	set(${out_extensions} "*.c" "*.cpp" PARENT_SCOPE)
endfunction()

function(AppendCodeFilesRecursively out_header_files out_source_files top_dir relative_dirs exclude_main)
	GetDefaultCppHeaderFileExtensions(AppendCodeFilesRecursively_HEADER_EXTENSIONS)
	GetDefaultCppSourceFileExtensions(AppendCodeFilesRecursively_SOURCE_EXTENSIONS)

	set(AppendCodeFilesRecursively_${out_header_files} ${${out_header_files}})
	set(AppendCodeFilesRecursively_${out_source_files} ${${out_source_files}})

	AppendFilesRecursively(AppendCodeFilesRecursively_${out_header_files} ${top_dir} "${relative_dirs}" "${AppendCodeFilesRecursively_HEADER_EXTENSIONS}" ${exclude_main})
	AppendFilesRecursively(AppendCodeFilesRecursively_${out_source_files} ${top_dir} "${relative_dirs}" "${AppendCodeFilesRecursively_SOURCE_EXTENSIONS}" ${exclude_main})

	set(${out_header_files} ${AppendCodeFilesRecursively_${out_header_files}} PARENT_SCOPE)
	set(${out_source_files} ${AppendCodeFilesRecursively_${out_source_files}} PARENT_SCOPE)
endfunction()

function(AppendFilesRecursively out_files top_dir relative_dirs extensions exclude_main)
	foreach (relative_dir ${relative_dirs})
		set(AppendFilesRecursively_EXTENSIONS ${extensions})
		list(TRANSFORM AppendFilesRecursively_EXTENSIONS PREPEND ${relative_dir}/)

		file(GLOB_RECURSE AppendFilesRecursively_FILES RELATIVE ${top_dir} ${AppendFilesRecursively_EXTENSIONS})

		if(exclude_main)
			set(filtered_files "")
			foreach(file ${AppendFilesRecursively_FILES})
				string(TOLOWER "${file}" file_lower)
				if(NOT file_lower MATCHES "^.*main\\.cpp$")
					list(APPEND filtered_files "${file}")
				endif()
			endforeach()

			set(AppendFilesRecursively_${out_files} ${AppendFilesRecursively_${out_files}} ${filtered_files})
		else()
			set(AppendFilesRecursively_${out_files} ${AppendFilesRecursively_${out_files}} ${AppendFilesRecursively_FILES})
		endif()

    endforeach ()
	
	set(AppendFilesRecursively_${out_files} ${${out_files}} ${AppendFilesRecursively_${out_files}})

	set(${out_files} ${AppendFilesRecursively_${out_files}} PARENT_SCOPE)
endfunction()

function(AddIncludeDirectoriesToCurrentProject scope include_dirs)
	foreach (include_dir ${include_dirs})
		target_include_directories(${PROJECT_NAME} ${scope} "${include_dir}")
    endforeach ()
endfunction()

function(AddLibraryToCurrentProject root_dir source_dir)
	AppendCodeFilesRecursively(AddLibraryToCurrentProject_CODE_FILES AddLibraryToCurrentProject_CODE_FILES ${PROJECT_SOURCE_DIR} "${source_dir}" FALSE)
	AddExecutableToCurrentProject(${root_dir} "${AddLibraryToCurrentProject_CODE_FILES}" ${source_dir})
endfunction()

function(AddLibraryToCurrentTestProject root_dir source_dir)
	AppendCodeFilesRecursively(AddLibraryToCurrentProject_CODE_FILES AddLibraryToCurrentProject_CODE_FILES ${PROJECT_SOURCE_DIR} "${source_dir}" TRUE)
	set(include_dirs "${source_dir}/Code" "${source_dir}")
	AddExecutableToCurrentProject(${root_dir} "${AddLibraryToCurrentProject_CODE_FILES}" "${include_dirs}")
	target_link_libraries(${PROJECT_NAME} PRIVATE GTest::gtest_main GTest::gmock)
	target_compile_definitions(${PROJECT_NAME} PRIVATE USING_GTEST)
	include(GoogleTest)
endfunction()

function(AddExecutableToCurrentProject root_dir code_files public_include_dirs)
	source_group(TREE ${root_dir} FILES ${code_files})
	add_executable(${PROJECT_NAME} ${code_files})
	AddIncludeDirectoriesToCurrentProject(PUBLIC "${public_include_dirs}")
endfunction()

function(SetLibraryCppStandard target_name cpp_standard)
	set_target_properties(${target_name} PROPERTIES
		CXX_STANDARD ${cpp_standard}
		CXX_STANDARD_REQUIRED ON)
endfunction()

function(SetCompileOptionsMSVC project_name)
	target_compile_options(${project_name} PUBLIC /bigobj)
	target_compile_options(${project_name} PRIVATE /WX)	#Enable Warnings as errors

	#Enable Address sanitizer on Debug
	target_compile_options(${project_name} PRIVATE "$<$<CONFIG:Debug>:/fsanitize=address>")
endfunction()

function(SetCompileOptionsGNU project_name)
	target_compile_options(${project_name} PRIVATE -Werror)	#Enable Warnings as errors

	#Enable Address sanitizer on Debug
	target_compile_options(${project_name} PRIVATE
        "$<$<CONFIG:Debug>:-fsanitize=address>"
        "$<$<CONFIG:Debug>:-fno-omit-frame-pointer>"
    )
    target_link_options(${project_name} PRIVATE "$<$<CONFIG:Debug>:-fsanitize=address>")
endfunction()

function(GetProjectExternalPath full_path out_external_path)
	get_filename_component(current_path "${full_path}" ABSOLUTE)
	set(result "")

 	while(TRUE)
        # Check whether this directory contains an External folder
        if(IS_DIRECTORY "${current_path}/External")
            set(result "${current_path}/External")
            break()
        endif()

        # Move one directory up
        get_filename_component(parent_path "${current_path}" DIRECTORY)

        # Stop if we reached the filesystem root
        if("${parent_path}" STREQUAL "${current_path}")
            break()
        endif()

        set(current_path "${parent_path}")
    endwhile()

    # External folder not found
    if("${result}" STREQUAL "")
        message(FATAL_ERROR
            "Could not find an \"External\" directory starting from: ${full_path}"
        )
    endif()

    set(${out_external_path} "${result}" PARENT_SCOPE)
endfunction()