#################################################
#
# Useful funtions
#
#################################################
cmake_minimum_required(VERSION 3.1)

# --[ correctly show folder structure in Visual Studio
function(assign_source_group)
  foreach(_source IN ITEMS ${ARGN})
    if (IS_ABSOLUTE "${_source}")
      file(RELATIVE_PATH _source_rel "${CMAKE_CURRENT_SOURCE_DIR}" "${_source}")
    else()
      set(_source_rel "${_source}")
    endif()
    get_filename_component(_source_path "${_source_rel}" PATH)
    string(REPLACE "/" "\\" _source_path_msvc "${_source_path}")
    source_group("${_source_path_msvc}" FILES "${_source}")
  endforeach()
endfunction(assign_source_group)

function(overlook_add_executable)
  if (CMAKE_SYSTEM_NAME MATCHES "Windows" OR CMAKE_SYSTEM_NAME MATCHES "Darwin")
    foreach(_source IN ITEMS ${ARGN})
      assign_source_group(${_source})
    endforeach()
    #message("${ARGV}\n")
  endif ()
  add_executable(${ARGV})
endfunction(overlook_add_executable)

function(overlook_cuda_add_executable)
  if (CMAKE_SYSTEM_NAME MATCHES "Windows" OR CMAKE_SYSTEM_NAME MATCHES "Darwin")
    foreach(_source IN ITEMS ${ARGN})
      assign_source_group(${_source})
    endforeach()
    #message("${ARGV}\n")
  endif ()
  cuda_add_executable(${ARGV})
endfunction(overlook_cuda_add_executable)

function(overlook_add_library)
  if (CMAKE_SYSTEM_NAME MATCHES "Windows" OR CMAKE_SYSTEM_NAME MATCHES "Darwin")
    foreach(_source IN ITEMS ${ARGN})
      assign_source_group(${_source})
    endforeach()
    #message("${ARGV}\n")
  endif ()
  add_library(${ARGV})
endfunction(overlook_add_library)

function(overlook_cuda_add_library)
  if (CMAKE_SYSTEM_NAME MATCHES "Windows" OR CMAKE_SYSTEM_NAME MATCHES "Darwin")
    foreach(_source IN ITEMS ${ARGN})
      assign_source_group(${_source})
    endforeach()
    #message("${ARGV}\n")
  endif ()
  cuda_add_library(${ARGV})
endfunction(overlook_cuda_add_library)

# append element to list with space as seperator 
function(overlook_list_append __string __element)
  # set(__list ${${__string}})
  # set(__list "${__list} ${__element}")
  # set(${__string} ${__list} PARENT_SCOPE)
  #set(__list ${${__string}})
  set(${__string} "${${__string}} ${__element}" PARENT_SCOPE)
endfunction()

option(USE_OVERLOOK_FLAGS "use safe compilation flags?" ON)
option(OVERLOOK_STRICT_FLAGS "strict c/c++ flags checking?" OFF)
option(USE_CPPCHECK "use cppcheck for static checkingg?" OFF)
option(OVERLOOK_VERBOSE "verbose output?" OFF)

#################################################
#
# Important CFLAGS/CXXFLAGS
#
#################################################

set(OVERLOOK_C_FLAGS "")
set(OVERLOOK_CXX_FLAGS "")


# 0. ???????????????????????????????????????????????????????????????????????????????????????????????????
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND CLANG_VERSION_STRING)
  message(STATUS "--- CLANG_VERSION_MAJOR is: ${CLANG_VERSION_MAJOR}")
  message(STATUS "--- CLANG_VERSION_MINOR is: ${CLANG_VERSION_MINOR}")
  message(STATUS "--- CLANG_VERSION_PATCHLEVEL is: ${CLANG_VERSION_PATCHLEVEL}")
  message(STATUS "--- CLANG_VERSION_STRING is: ${CLANG_VERSION_STRING}")
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  message(STATUS "--- CMAKE_CXX_COMPILER_VERSION is: ${CMAKE_CXX_COMPILER_VERSION}")
  # if(CMAKE_CXX_COMPILER_VERSION GREATER 9.1) # when >= 9.2, not support this option
  #   message(STATUS "---- DEBUG INFO HERE !!!")
  # endif()
endif()

# 1. ???????????????????????????
# ??????bug??????????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4013)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4013)
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=implicit-function-declaration)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=implicit-function-declaration)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=implicit-function-declaration)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=implicit-function-declaration)
endif()

# 2. ???????????????????????????????????????????????????????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4431)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4431)
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
  if(CMAKE_CXX_COMPILER_VERSION LESS 9.4) # gcc/g++ <= 9.3 required
    overlook_list_append(OVERLOOK_C_FLAGS -Werror=implicit-int)
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=implicit-int)
  endif()
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=implicit-int)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=implicit-int)
endif()

# 3. ?????????????????????
# ??????bug???crash???????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4133)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4133)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  if(CMAKE_CXX_COMPILER_VERSION GREATER 4.8 AND CMAKE_CXX_COMPILER_VERSION LESS 9.2) # gcc/g++ <= 9.1 required, gcc/g++ 4.8.3 not ok
    overlook_list_append(OVERLOOK_C_FLAGS -Werror=incompatible-pointer-types)
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=incompatible-pointer-types)
  endif()
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=incompatible-pointer-types)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=incompatible-pointer-types)
endif()

# 4. ?????????????????????????????????return?????????;????????????????????????????????????
# ??????bug???lane detect; vpdt for??????????????????(android??????trap)
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4716 /we4715)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4716 /we4715)
else()
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=return-type)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=return-type)
endif()

# 5. ??????????????????(shadow)??????
# ???????????????????????????eigen????????????????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we6244 /we6246 /we4457 /we4456)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we6244 /we6246 /we4457 /we4456)
else()
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=shadow)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=shadow)
endif()

# 6. ??????????????????????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4172)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4172)
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=return-local-addr)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=return-local-addr)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=return-stack-address)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=return-stack-address)
endif()

# 7. ???????????????????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS "/we4700 /we26495")
  overlook_list_append(OVERLOOK_CXX_FLAGS "/we4700 /we26495")
else()
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=uninitialized)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=uninitialized)
endif()

# 8. printf????????????????????????????????????????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4477)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4477)
else()
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=format)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=format)
endif()

# 9. ?????????unsigned int???int????????????
# ????????????????????????for??????????????????????????????
if(OVERLOOK_STRICT_FLAGS)
  if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    overlook_list_append(OVERLOOK_C_FLAGS /we4018)
    overlook_list_append(OVERLOOK_CXX_FLAGS /we4018)
  elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
    overlook_list_append(OVERLOOK_C_FLAGS -Werror=sign-compare)
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=sign-compare)
  elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
    overlook_list_append(OVERLOOK_C_FLAGS -Werror=sign-compare)
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=sign-compare)
  endif()
endif()

# 10. ?????????int???????????????int????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4047)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4047)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  if(CMAKE_CXX_COMPILER_VERSION GREATER 4.8 AND CMAKE_CXX_COMPILER_VERSION LESS 9.2) # gcc/g++ <= 9.1 required
    overlook_list_append(OVERLOOK_C_FLAGS -Werror=int-conversion)
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=int-conversion)
  endif()
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=int-conversion)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=int-conversion)
endif()

# 11. ??????????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS "/we6201 /we6386 /we4789")
  overlook_list_append(OVERLOOK_CXX_FLAGS "/we6201 /we6386 /we4789")
else()
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=array-bounds)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=array-bounds)
endif()

# 12. ?????????????????????????????????????????????????????????MSVC C???????????????Linux Clang?????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4029)
endif()

# 13. ???????????????????????????????????????????????????????????????MSVC C???????????????Linux Clang?????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4020)
endif()

# 14. ??????void*????????????????????????????????????
# MSVC C/C++??????????????????Linux gcc??????warning???error???Linux g++??????warning
# Linux??? Clang???-Wpedentric??????warning???Clang++???error
if(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=pointer-arith)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=pointer-arith)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=pointer-arith)
endif()

# 15. ?????????????????????????????????????????????????????????????????????C????????????
# ???????????????MSVC?????????????????????
if(CMAKE_C_COMPILER_ID MATCHES "GNU" OR CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -fno-common)
endif()

# 16. Windows?????????????????????UTF-8???????????????????????????stdout???
# ??????????????????????????????????????????????????????????????????GBK??????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS "/source-charset:utf-8 /execution-charset:gbk")
  overlook_list_append(OVERLOOK_CXX_FLAGS "/source-charset:utf-8 /execution-charset:gbk")
endif()

# 17. ??????????????????
# TODO: ??????MSVC
# Linux Clang8.0???????????????
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=free-nonheap-object)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=free-nonheap-object)
endif()

# 18. ??????????????????????????????????????????(.h/.c)????????????????????????????????????????????????????????????????????????????????????
# ??????warning??????error??????VS??????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4028)
endif()

# 19. ???????????????
# gcc5~gcc9????????????
if (0)
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4005)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4005)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=macro-redefined)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=macro-redefined)
endif()
endif()

# 20. pragma init_seg????????????????????????????????????section??????
# VC++?????????Linux??????gcc/clang??????
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4075)
endif()

# 21. size_t???????????????????????????
# VC/VC++?????????Linux??????gcc/clang??????
# ?????????????????????
if (OVERLOOK_STRICT_FLAGS)
  if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    overlook_list_append(OVERLOOK_C_FLAGS /we4267)
    overlook_list_append(OVERLOOK_CXX_FLAGS /we4267)
  endif()
endif()

# 22. ????????????????????????: ????????????int????????????????????????void *???
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4312)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4312)
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=int-to-pointer-cast)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=int-to-pointer-cast)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=int-to-pointer-cast)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=int-to-pointer-cast)
endif()

# 23. ?????????????????????????????????
# GCC5.4?????????warning?????????????????????????????????error
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4129)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4129)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=unknown-escape-sequence)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=unknown-escape-sequence)
endif()

# 24. ????????????????????? ????????????
# VC/VC++????????????Linux??????GCC/Clang???error
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4002)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4002)
endif()

# 25. ????????????????????? ????????????
# VC/VC++????????????error C2059
# Linux GCC/Clang????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4003)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4003)
endif()

# 26. #undef????????????????????????
# Linux GCC/Clang????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4006)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4006)
endif()

# 27. ??????????????????????????????
# ???????????????????????????????????????????????????????????????????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4006)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4006)
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=comment)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=comment)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=comment)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=comment)
endif()

# 28. ???????????????????????????????????????????????????????????????
# ??????????????????????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS "/we4552 /we4555")
  overlook_list_append(OVERLOOK_CXX_FLAGS "/we4552 /we4555")
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=unused-value)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=unused-value)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=unused-value)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=unused-value)
endif()

# 29. ???==???: ????????????????????????????????????????????????=????
# Linux GCC ???????????????????????????
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4553)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4553)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=unused-comparison)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=unused-comparison)
endif()

# 30. C++???????????????????????????????????????char*??????
# VS2019??????/Wall???????????????
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=write-strings)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  # Linux Clang ??? AppleClang ????????????
  if (CMAKE_SYSTEM_NAME MATCHES "Linux")
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=writable-strings)
  elseif(CMAKE_SYSTEM_NAME MATCHES "Darwin")
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=c++11-compat-deprecated-writable-strings)
  endif()
endif()

# 31. ?????????????????????(if/else)?????????????????????
# NDK21 Clang / Linux Clang/GCC/G++ ???????????? error
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4715)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4715)
endif()

# 32. multi-char constant
# MSVC ?????????????????????
if(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=multichar)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=multichar)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=multichar)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=multichar)
endif()




# ??????????????????FLAGS?????????CMAKE????????????????????????
# ???????????????????????????????????????????????????toolchain?????????android???????????????
if (USE_OVERLOOK_FLAGS)
  overlook_list_append(CMAKE_C_FLAGS "${OVERLOOK_C_FLAGS}")
  overlook_list_append(CMAKE_CXX_FLAGS "${OVERLOOK_CXX_FLAGS}")
endif()

if (OVERLOOK_VERBOSE)
  message(STATUS "--- OVERLOOK_C_FLAGS are: ${OVERLOOK_C_FLAGS}")
  message(STATUS "--- OVERLOOK_CXX_FLAGS are: ${OVERLOOK_CXX_FLAGS}")
endif()

#################################################
#
# Add whole archive when build static library
#
#################################################
function (overlook_add_whole_archive_flag lib output_var)
  #message(FATAL_ERROR "=== linker is: ${ANDROID_LD}")
  if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    message(STATUS "not supported yet")
  elseif(CMAKE_C_COMPILER_ID MATCHES "Clang" AND NOT ANDROID)
    set(${output_var} -Wl,-force_load ${lib} PARENT_SCOPE)
  else()
    #?????????NDK21??????????????????ANDROID_LD=lld???????????????ld?????????????????????????????????
    set(${output_var} -Wl,--whole-archive ${lib} -Wl,--no-whole-archive PARENT_SCOPE)
  endif()
endfunction()

#################################################
#
# cppcheck?????????????????????????????????????????????????????????????????????UB
#   ?????????????????????????????????????????????????????????NDK?????????????????????
#
#################################################
if(USE_CPPCHECK)
  find_program(CMAKE_CXX_CPPCHECK NAMES cppcheck)
  if (CMAKE_CXX_CPPCHECK)
    message(STATUS "cppcheck found")
    list(APPEND CMAKE_CXX_CPPCHECK
      "--enable=warning"
      "--inconclusive"
      "--force"
      "--inline-suppr"
    )
  else()
    message(STATUS "cppcheck not found. ignore it")
  endif()
endif()


#################################################
#
# Platform determinations
#
#################################################
if (CMAKE_SYSTEM_NAME MATCHES "Windows")
  set(OVERLOOK_SYSTEM "Windows")
elseif (ANDROID)
  set(OVERLOOK_SYSTEM "Android")
elseif (CMAKE_SYSTEM_NAME MATCHES "Linux")
  set(OVERLOOK_SYSTEM "Linux")
elseif (CMAKE_SYSTEM_NAME MATCHES "Darwin")
  set(OVERLOOK_SYSTEM "MacOS")
else ()
  message(FATAL_ERROR "un-configured system: ${CMAKE_SYSTEM_NAME}")
endif()
if (OVERLOOK_VERBOSE)
  message(STATUS "----- OVERLOOK_SYSTEM: ${OVERLOOK_SYSTEM}")
endif()

#################################################
#
# Architecture determinations
#
#################################################
if((IOS AND CMAKE_OSX_ARCHITECTURES MATCHES "arm") #?????????ARM
  OR (CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm|Arm|ARM|aarch64|AAarch64|AARCH64)"))
  set(OVERLOOK_ARCH arm)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(mips|Mips|MIPS)")
  set(OVERLOOK_ARCH mips)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(riscv|Riscv|RISCV)")
  set(OVERLOOK_ARCH riscv)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(powerpc|PowerPC|POWERPC)")
  set(OVERLOOK_ARCH powerpc)
else()
  set(OVERLOOK_ARCH x86)
  #if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten") #wasm
  #endif()
endif()
if (OVERLOOK_VERBOSE)
  message(STATUS "----- OVERLOOK_ARCH: ${OVERLOOK_ARCH}")
endif()

#################################################
#
# ABI determinations
#
#################################################
if (ANDROID)
  set(OVERLOOK_ABI ${ANDROID_ABI})
elseif (OVERLOOK_ARCH STREQUAL x86)
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(OVERLOOK_ABI "x64")
  else()
    set(OVERLOOK_ABI "x86")
  endif()
elseif (OVERLOOK_ARCH STREQUAL arm)
  if (CMAKE_C_COMPILER MATCHES "arm-linux-gnueabihf-gcc")
    set(OVERLOOK_ABI "arm-eabihf")
  elseif(CMAKE_C_COMPILER MATCHES "aarch64-none-linux-gnu-gcc")
    set(OVERLOOK_ABI "aarch64-none")
  else()
    message(FATAL_ERROR "un-assigned ABI, please add it now")
  endif()
else()
  message(FATAL_ERROR "un-assigned ABI, please add it now")
endif()
if (OVERLOOK_VERBOSE)
  message(STATUS "----- OVERLOOK_ABI: ${OVERLOOK_ABI}")
endif()

#################################################
#
# Visual Studio stuffs: vs_version, vc_version
#
#################################################
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  if(MSVC_VERSION EQUAL 1600)
    set(vs_version vs2010)
    set(vc_version vc10)
  elseif(MSVC_VERSION EQUAL 1700)
    set(vs_version vs2012)
    set(vc_version vc11)
  elseif(MSVC_VERSION EQUAL 1800)
    set(vs_version vs2013)
    set(vc_version vc12)
  elseif(MSVC_VERSION EQUAL 1900)
    set(vs_version vs2015)
    set(vc_version vc14)
  elseif(MSVC_VERSION GREATER_EQUAL 1910 AND MSVC_VERSION LESS_EQUAL 1920)
    set(vs_version vs2017)
    set(vc_version vc15)
  elseif(MSVC_VERSION GREATER_EQUAL 1920)
    set(vs_version vs2019)
    set(vc_version vc16)
  endif()
endif()
