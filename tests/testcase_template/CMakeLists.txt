cmake_minimum_required(VERSION 3.15)

project(testcase_N)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include("../../overlook.cmake")

add_executable(testcase_N
  ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp
)

