# ###############################################################
#
# Overlook: a cmake plugin for safer c/c++ programming.
#
# Author:   Zhuo Zhang <imzhuo@foxmail.com>
# Homepage: https://github.com/zchrissirhcz/overlook
#
###############################################################

# GREATER_EQUAL New in version 3.7.

cmake_minimum_required(VERSION 3.7)

# Only included once
if(OVERLOOK_INCLUDE_GUARD)
  return()
endif()
set(OVERLOOK_INCLUDE_GUARD TRUE)
set(OVERLOOK "${CMAKE_CURRENT_LIST_FILE}")

set(OVERLOOK_VERSION "2023.10.01")

option(OVERLOOK_APPLY_FLAGS_GLOBAL "Apply overlook globally?" ON)
option(OVERLOOK_VERBOSE            "Verbose output?"          OFF)

set(OVERLOOK_C_FLAGS "")
set(OVERLOOK_CXX_FLAGS "")

# Append element to list with space as seperator
function(overlook_list_append __string __element)
  # set(__list ${${__string}})
  # set(__list "${__list} ${__element}")
  # set(${__string} ${__list} PARENT_SCOPE)
  #set(__list ${${__string}})
  set(${__string} "${${__string}} ${__element}" PARENT_SCOPE)
endfunction()

# Print overlook information
message(STATUS "----------------------------------------------------------")
message(STATUS "  Overlook: a cmake plugin for safer C/C++ programming    ")
message(STATUS "  Author  : Zhuo Zhang (imzhuo@foxmail.com)               ")
message(STATUS "  Homepage: https://github.com/zchrissirhcz/overlook      ")
message(STATUS "  Version : ${OVERLOOK_VERSION}                           ")
message(STATUS "----------------------------------------------------------")

if(CMAKE_C_COMPILER_ID)
  set(OVERLOOK_WITH_C TRUE)
else()
  set(OVERLOOK_WITH_C FALSE)
endif()

if(CMAKE_CXX_COMPILER_ID)
  set(OVERLOOK_WITH_CXX TRUE)
else()
  set(OVERLOOK_WITH_CXX FALSE)
endif()

# Project LANGUAGE not including C and CXX so we return
if((NOT OVERLOOK_WITH_C) AND (NOT OVERLOOK_WITH_CXX))
  message("OVERLOOK/W: Neither C nor CXX compilers available. No OVERLOOK C/C++ flags will be set")
  message("  NOTE: You many consider add C and CXX in `project()` command")
  return()
endif()

# rule0: don't ignore all that warnings
# If `-w` specified for GCC/Clang, report an error
if((CMAKE_C_COMPILER_ID MATCHES "GNU") OR (CMAKE_C_COMPILER_ID MATCHES "Clang"))
  get_directory_property(overlook_detected_global_compile_options COMPILE_OPTIONS)
  message(STATUS "Overlook Detected Global Compile Options: ${overlook_detected_global_compile_options}")
  string(REGEX MATCH "-w" ignore_all_warnings "${overlook_detected_global_compile_options}" )
  if(ignore_all_warnings)
    message(FATAL_ERROR "OverLook won't work due to `-w` found in compile options. Consider remove it (in `add_compile_options)`")
  endif()
endif()

#--------------------------------------------------------------------------------
# Function return value related
#--------------------------------------------------------------------------------
# rule1: calls a function when it is not declared. C compiler doesn't treat it an error, but we do.
# 函数没有声明就使用, C编译器默认不报错，改为强制报错
# 解决bug: 地址截断; 内存泄漏
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4013)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4013)
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=implicit-function-declaration)
  if(CMAKE_CXX_COMPILER_VERSION LESS 9.1)
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=implicit-function-declaration)
  endif()
  if(CMAKE_C_COMPILER_VERSION GREATER_EQUAL 11.1)
    overlook_list_append(OVERLOOK_C_FLAGS -Werror=builtin-declaration-mismatch)
  endif()
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=implicit-function-declaration)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=implicit-function-declaration)
endif()

# rulex
if(CMAKE_C_COMPILER_ID MATCHES "GNU")
endif()

# rule2: 函数虽然有声明，但是声明不完整，没有写出返回值类型，C编译器默认不报错，改为强制报错
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4431)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4431)
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=implicit-int)
  if(CMAKE_CXX_COMPILER_VERSION LESS 9.1)
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=implicit-int)
  endif()
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=implicit-int)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=implicit-int)
endif()

# rule4: when missing return value for non-void function, C/C++ compiler treat it as UB and not report error, we treat it as error.
# it may cause crash, or just return un-expected result, depends on the compiler and the code you write
# 函数应该有返回值但没有 return 返回值，或不是所有路径都有返回值，C和C++编译器默认不报错，改为强制报错
# 解决bug: lane detect; vpdt for循环无法跳出(android输出trap); lane calib库读取到随机值导致获取非法格式asvl, 开asan则表现为读取NULL指针
# -O3时输出内容和其他优化等级不一样 (from 三老师)
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4716 /we4715)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4716 /we4715)
else()
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=return-type)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=return-type)
endif()

# rule30: 所有的控件路径(if/else)必须都有返回值
# NDK21 Clang / Linux Clang/GCC/G++ 默认都报 error
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4715)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4715)
endif()

# rule6: 函数不应该返回局部变量的地址
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

#--------------------------------------------------------------------------------
# Function argument/parameter, type conversion/casting related
#--------------------------------------------------------------------------------

# rule12: 函数声明中的参数列表和定义中不一样。在 MSVC C 下为警告, Linux Clang 下报错
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4029)
endif()

# rule13: 实参太多, 比函数定义或声明中的要多。只在MSVC C 下为警告, Linux Clang下报错
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4020)
endif()

# rule14: 避免 void* 类型的指针参参与算术运算
# MSVC C/C++ 默认会报错, Linux gcc 不报 warning 和 error, Linux g++ 只报 warning
# Linux 下 Clang 开 -Wpedentric 才报 warning, Clang++ 报 error
if(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=pointer-arith)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=pointer-arith)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=pointer-arith)
endif()

# rule3: 指针类型不兼容，C编译器默认不报错，改为强制报错
# 解决bug: crash或结果异常
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4133)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4133)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  if(CMAKE_CXX_COMPILER_VERSION GREATER 4.8) # gcc/g++ 4.8.3 not ok
    overlook_list_append(OVERLOOK_C_FLAGS -Werror=incompatible-pointer-types)
    if(CMAKE_CXX_COMPILER_VERSION LESS 9.1)
      overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=incompatible-pointer-types)
    endif()
  endif()
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=incompatible-pointer-types)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=incompatible-pointer-types)
endif()

# rule10: 避免把 int 指针赋值给 int 类型变量
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4047)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4047)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  if(CMAKE_CXX_COMPILER_VERSION GREATER 4.8)
    overlook_list_append(OVERLOOK_C_FLAGS -Werror=int-conversion)
    if(CMAKE_CXX_COMPILER_VERSION LESS 9.1)
      overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=int-conversion)
    endif()
  endif()
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=int-conversion)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=int-conversion)
endif()

# rule8: printf 等语句中的格式串和实参类型不匹配，要避免
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4477)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4477)
else()
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=format)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=format)
endif()

# rule17: 形参与声明不同。场景：静态库(.h/.c)，集成时换库但没换头文件，且函数形参有变化（类型或数量）
# 只报 warning 不报 error。仅 VS 出现
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4028)
endif()

# rule21: “类型强制转换”: 例如从 int 转换到更大的 void*
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

# rule23: 类函数宏的调用 参数过多
# VC/VC++ 报警告。Linux 下的 GCC/Clang 报 error
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4002)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4002)
endif()

# rule24: 类函数宏的调用 参数不足
# VC/VC++ 同时会报 error C2059
# Linux GCC/Clang 直接报错
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4003)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4003)
endif()

#--------------------------------------------------------------------------------
# Initialization, memory release related
#--------------------------------------------------------------------------------

# rule7: 变量没初始化就使用，要避免
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS "/we4700 /we26495")
  overlook_list_append(OVERLOOK_CXX_FLAGS "/we4700 /we26495")
else()
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=uninitialized)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=uninitialized)
endif()

# rule11: 检查数组下标越界访问
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS "/we6201 /we6386 /we4789")
  overlook_list_append(OVERLOOK_CXX_FLAGS "/we6201 /we6386 /we4789")
else()
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=array-bounds)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=array-bounds)
endif()

# rule16: 释放非堆内存
# TODO: 检查 MSVC
# Linux Clang8.0 无法检测到
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=free-nonheap-object)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=free-nonheap-object)
endif()

# rule32: 用 memset 等 C 函数设置 非 POD class 对象
# Linux下, GCC9.3 能发现此问题, 但clang10 不能发现
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  if(CMAKE_CXX_COMPILER_VERSION GREATER 7.5)
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=class-memaccess)
  endif()
endif()

# rule15: 避免符号重复定义（变量对应的强弱符号）。只在 C 中出现。
# 暂时没找到 MSVC 的对应编译选项
if(CMAKE_C_COMPILER_ID MATCHES "GNU" OR CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -fno-common)
endif()

#--------------------------------------------------------------------------------
# Pre-compilation directive related
#--------------------------------------------------------------------------------

# rule18: 宏定义重复
# gcc5~gcc9 无法检查
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4005)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4005)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=macro-redefined)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=macro-redefined)
endif()

# rule19: pragma init_seg 指定了非法(不能识别的)section名字
# VC++ 特有。Linux 下的 gcc/clang 没有
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4075)
endif()

# rule25: #undef 没有跟一个标识符
# Linux GCC/Clang 直接报错
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4006)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4006)
endif()


#--------------------------------------------------------------------------------
# Unused stuffs related
#--------------------------------------------------------------------------------

# rule27: 没有使用到表达式结果（无用代码行，应删除）
# 感觉容易被误伤，可以考虑关掉
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

# rule28: “==”: 未使用表达式结果；是否打算使用“=”?
# Linux GCC 没有对应的编译选项
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4553)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4553)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=unused-comparison)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=unused-comparison)
endif()

# 可能会导致下一行代码报错，而问题根源在包含继续符的这行注释
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


#--------------------------------------------------------------------------------
# String/Char related
#--------------------------------------------------------------------------------

# rule22: 不可识别的字符转义序列
# GCC5.4 能显示 warning 但无别名，因而无法视为 error
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  overlook_list_append(OVERLOOK_C_FLAGS /we4129)
  overlook_list_append(OVERLOOK_CXX_FLAGS /we4129)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=unknown-escape-sequence)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=unknown-escape-sequence)
endif()

# rule29: C++中，禁止把字符串常量赋值给 char* 变量
# VS2019 开启 /Wall 后也查不到
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=write-strings)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  # Linux Clang 和 AppleClang 不太一样
  if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=writable-strings)
  elseif(CMAKE_SYSTEM_NAME MATCHES "Darwin")
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=c++11-compat-deprecated-writable-strings)
  endif()
endif()

# rule31: multi-char constant
# MSVC 没有对应的选项
if(CMAKE_C_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=multichar)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=multichar)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=multichar)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=multichar)
endif()


#--------------------------------------------------------------------------------
# Misc
#--------------------------------------------------------------------------------

## rule33: 括号里面是单个等号而不是双等号
# Linux Clang14 可以发现问题，但 GCC9.3 无法发现; android clang 可以发现
if(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=parentheses)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=parentheses)
endif()


## rule35: 父类有 virtual 的成员函数，但析构函数是 public 并且不是 virtual, 会导致 UB
# https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#c35-a-base-class-destructor-should-be-either-public-and-virtual-or-protected-and-non-virtual
# -Wnon-virtual-dtor (C++ and Objective-C++ only)
# Warn when a class has virtual functions and an accessible non-virtual destructor itself or in an accessible polymorphic base
# class, in which case it is possible but unsafe to delete an instance of a derived class through a pointer to the class
# itself or base class.  This warning is automatically enabled if -Weffc++ is specified.
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=non-virtual-dtor)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=non-virtual-dtor)
endif()

## rule36: switch case 忘记写 break, 会 fallthrough 执行， 可能导致数组越界(具体取决于你的代码). 不写break我们视为错误。
if((CMAKE_C_COMPILER_ID MATCHES "GNU") OR (CMAKE_CXX_COMPILER_ID MATCHES "GNU"))
  overlook_list_append(OVERLOOK_C_FLAGS -Werror=implicit-fallthrough)
  overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=implicit-fallthrough)
elseif((CMAKE_C_COMPILER_ID MATCHES "Clang") OR (CMAKE_CXX_COMPILER_ID MATCHES "Clang"))
  overlook_list_append(OVERLOOK_C_FLAGS  -Werror=implicit-fallthrough)
  overlook_list_append(OVERLOOK_CXX_FLAGS  -Werror=implicit-fallthrough)
endif()


#--------------------------------------------------------------------------------
# Usually false positive type casting/conversions
#--------------------------------------------------------------------------------

if (0)
  # rule5: 避免使用影子(shadow)变量
  # 有时候会误伤, 例如eigen等开源项目, 可以手动关掉
  if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    overlook_list_append(OVERLOOK_C_FLAGS /we6244 /we6246 /we4457 /we4456)
    overlook_list_append(OVERLOOK_CXX_FLAGS /we6244 /we6246 /we4457 /we4456)
  else()
    overlook_list_append(OVERLOOK_C_FLAGS -Werror=shadow)
    overlook_list_append(OVERLOOK_CXX_FLAGS -Werror=shadow)
  endif()

  # rule9: 避免把 unsigned int 和 int 直接比较
  # 通常会误伤，例如 for 循环中。可以考虑关掉
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

  # rule20: size_t 类型被转为更窄类型
  # VC/VC++ 特有。 Linux 下的 gcc/clang 没有
  # 有点过于严格了
  if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    overlook_list_append(OVERLOOK_C_FLAGS /we4267)
    overlook_list_append(OVERLOOK_CXX_FLAGS /we4267)
  endif()

  ## rule34: double 型转 float 型，可能有精度丢失（尤其在 float 较大时）
  # MSVC 默认是放在 /W3
  if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    overlook_list_append(OVERLOOK_C_FLAGS /we4244)
    overlook_list_append(OVERLOOK_CXX_FLAGS /we4244)
  endif()

endif()


# 将上述定制的 FLAGS 追加到 CMAKE 默认的编译选项中
# 为什么是添加而不是直接设定呢？因为 xxx-toolchain.cmake 中可能会设置一些默认值 (如 Android NDK), 需要避免这些默认值被覆盖
if(OVERLOOK_APPLY_FLAGS_GLOBAL)
  overlook_list_append(CMAKE_C_FLAGS "${OVERLOOK_C_FLAGS}")
  overlook_list_append(CMAKE_CXX_FLAGS "${OVERLOOK_CXX_FLAGS}")
endif()

if(OVERLOOK_VERBOSE)
  message(STATUS "OVERLOOK_C_FLAGS are: ${OVERLOOK_C_FLAGS}")
  message(STATUS "OVERLOOK_CXX_FLAGS are: ${OVERLOOK_CXX_FLAGS}")
endif()


##################################################################################
# Add whole archive when build static library
# Usage:
#   overlook_add_whole_archive_flag(<lib> <output_var>)
# Example:
#   add_library(foo foo.hpp foo.cpp)
#   add_executable(bar bar.cpp)
#   overlook_add_whole_archive_flag(foo safe_foo)
#   target_link_libraries(bar ${safe_foo})
##################################################################################
function(overlook_add_whole_archive_flag lib output_var)
  if("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC")
    if(MSVC_VERSION GREATER 1900)
      set(${output_var} -WHOLEARCHIVE:$<TARGET_FILE:${lib}> PARENT_SCOPE)
    else()
      message(WARNING "MSVC version is ${MSVC_VERSION}, /WHOLEARCHIVE flag cannot be set")
      set(${output_var} ${lib} PARENT_SCOPE)
    endif()
  elseif("${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU")
    set(${output_var} -Wl,--whole-archive ${lib} -Wl,--no-whole-archive PARENT_SCOPE)
  elseif("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang" AND CMAKE_SYSTEM_NAME MATCHES "Linux")
    # set(${output_var} -Wl,--whole-archive ${lib} -Wl,--no-whole-archive PARENT_SCOPE)
  elseif("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang" AND NOT ANDROID)
    set(${output_var} -Wl,-force_load ${lib} PARENT_SCOPE)
  elseif(ANDROID)
    # 即使是 NDK21 并且手动传入 ANDROID_LD=lld, 依然要用ld的查重复符号的链接选项
    set(${output_var} -Wl,--whole-archive ${lib} -Wl,--no-whole-archive PARENT_SCOPE)
  else()
    message(FATAL_ERROR ">>> add_whole_archive_flag not supported yet for current compiler: ${CMAKE_CXX_COMPILER_ID}")
  endif()
endfunction()


###############################################################
#
# cppcheck, 开启静态代码检查, 主要是检查编译器检测不到的UB
#   注: 目前只有终端下能看到对应输出，其中 NDK 下仅第一次输出
#
###############################################################

# Usage:
# add_executable(hello hello.cpp)
# overlook_apply_cppcheck(hello)
function(overlook_apply_cppcheck targetName)
  find_program(CMAKE_CXX_CPPCHECK NAMES cppcheck)

  # collecting absolute paths for each source file in the given target
  get_target_property(target_sources ${targetName} SOURCES)
  get_target_property(target_source_dir ${targetName} SOURCE_DIR)
  # message(STATUS "target_source_dir: ${target_source_dir}")
  # message(STATUS "target_sources:")
  set(src_path_lst "")
  foreach(target_source ${target_sources})
    # message(STATUS "   ${target_source}")
    if(IS_ABSOLUTE ${target_source})
      set(target_source_absolute_path ${target_source})
    else()
      set(target_source_absolute_path ${target_source_dir}/${target_source})
    endif()
    list(APPEND src_path_lst ${target_source_absolute_path})
  endforeach()

  set(cppcheck_raw_command "cppcheck --enable=warning --inconclusive --force --inline-suppr ${src_path_lst}")
  string(REPLACE " " ";" cppcheck_converted_command "${cppcheck_raw_command}")
  add_custom_target(
    cppcheck
    COMMAND ${cppcheck_converted_command}
  )
  add_dependencies(${targetName} cppcheck)
endfunction()

