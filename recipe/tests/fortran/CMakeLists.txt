cmake_minimum_required(VERSION 3.15)
project(med_fortran_tests Fortran)

# Locate the installed MED library in the conda prefix
if(WIN32)
    set(MED_PREFIX "$ENV{LIBRARY_PREFIX}")
else()
    set(MED_PREFIX "$ENV{PREFIX}")
endif()

find_library(MED_LIB NAMES med PATHS "${MED_PREFIX}/lib" REQUIRED NO_DEFAULT_PATH)
find_path(MED_INCLUDE NAMES med.hf PATHS "${MED_PREFIX}/include" REQUIRED NO_DEFAULT_PATH)

# On Windows, the Fortran wrappers live in a separate medfwrap library.
# On Unix, they are part of libmed.so via transitive linking.
find_library(MEDFWRAP_LIB NAMES medfwrap PATHS "${MED_PREFIX}/lib" NO_DEFAULT_PATH)

message(STATUS "MED library: ${MED_LIB}")
message(STATUS "MED include: ${MED_INCLUDE}")
if(MEDFWRAP_LIB)
    message(STATUS "MED Fortran wrapper library: ${MEDFWRAP_LIB}")
endif()

set(TESTS test_file_ops test_mesh test_field)

foreach(T ${TESTS})
    add_executable(${T} ${T}.f)
    target_include_directories(${T} PRIVATE ${MED_INCLUDE})
    if(MEDFWRAP_LIB)
        # On Windows: link medfwrap (Fortran symbols) + med (iterator/C glue)
        target_link_libraries(${T} ${MEDFWRAP_LIB} ${MED_LIB})
    else()
        target_link_libraries(${T} ${MED_LIB})
    endif()
endforeach()
