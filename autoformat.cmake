##################################################
#
#	BUILD/AUTOFORMAT.CMAKE
#
# 	Provides an easy mean to reformat a file using
#   uncrustify and the settings as defined in autoformat.cfg
#
#	Copyright (c) 2013 Marius Zwicker
#
#
#
# PROVIDED MACROS
# -----------------------
# mz_auto_format <target> [<file1> <file2>]...
#   Format the sourcefiles whenever the given target is built.
#   When no explicit sourcefiles are given, all sources the target
#   depends on and ending with (cxx|hpp|cpp|c) will be automatically
#   marked for autoformat
#
########################################################################


########################################################################
## no need to change anything beyond here
########################################################################

find_program(
    UNCRUSTIFY_BIN
    uncrustify
)

set(MZ_CPPLINT_TOOL ${MZ_TOOLS_PATH}/cpplint.py)
option(MZ_DO_AUTO_FORMAT "Enable to run cpplint and autoformat on configured targets" ON)

macro(mz_auto_format _TARGET)
  set(_sources ${ARGN})
  list(LENGTH _sources arg_count)
  configure_file(${MZ_TOOLS_PATH}/autoformat.cfg.in ${CMAKE_BINARY_DIR}/autoformat.cfg)

  if( NOT arg_count GREATER 0 )
    mz_debug_message("Autoformat was no files given, using the target's sources")
    get_target_property(_sources ${_TARGET} SOURCES)
  endif()

  set(CPPLINT_FILTERS
    -whitespace,-build/header_guard,-build/include,+build/include_what_you_use,-readability/multiline_comment,-readability/namespace,-readability/streams,-runtime/references,-runtime/threadsafe_fn
  )
    
  foreach(file ${_sources})
    get_filename_component(abs_file ${file} ABSOLUTE)
    get_filename_component(file_dir ${abs_file} PATH)
    
    if( ${file} MATCHES ".+(cpp|cxx|hpp|h|c)$" AND UNCRUSTIFY_BIN AND MZ_DO_AUTO_FORMAT )
      mz_debug_message("Autoformat using ${UNCRUSTIFY_BIN} for ${abs_file}")
      add_custom_command(TARGET ${_TARGET}
        PRE_BUILD
        COMMAND ${UNCRUSTIFY_BIN} -c ${CMAKE_BINARY_DIR}/autoformat.cfg --no-backup --mtime ${abs_file}
        COMMAND ${MZ_CPPLINT_TOOL} --root=${file_dir} --filter=${CPPLINT_FILTERS} ${abs_file}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      )
    endif()
  endforeach()

  mz_debug_message("WORKING_DIRECTORY=${MZ_TOOLS_PATH}")
endmacro()

macro(mz_auto_header _TARGET _HEADER)
   set(__MZ_AUTOFORMAT_ADD_CONFIG "cmt_insert_file_header=${_HEADER}")
   mz_auto_format(${_TARGET} ${ARGN})
endmacro()