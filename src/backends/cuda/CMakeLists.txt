enable_language(CUDA)
uipc_add_backend(cuda)

# basic setup
target_link_libraries(cuda PUBLIC
    muda
    cublas
    cusparse
    cusolver
    uipc_geometry
)

if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES "native")
endif()

target_compile_features(cuda PUBLIC cxx_std_20)
uipc_info("CMAKE_CUDA_ARCHITECTURES: ${CMAKE_CUDA_ARCHITECTURES}")
target_include_directories(cuda PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
set_target_properties(cuda PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
    CUDA_ARCHITECTURES ${CMAKE_CUDA_ARCHITECTURES}
    CUDA_STANDARD_REQUIRED ON
    CUDA_STANDARD 20
)

# add subdirectories
add_subdirectory(utils)
add_subdirectory(global_geometry)
add_subdirectory(implicit_geometry)
add_subdirectory(linear_system)
add_subdirectory(collision_detection)
add_subdirectory(algorithm)
add_subdirectory(line_search)
add_subdirectory(contact_system)
add_subdirectory(engine)
add_subdirectory(affine_body)
add_subdirectory(finite_element)
add_subdirectory(coupling_system)
add_subdirectory(animator)
add_subdirectory(diff_sim)
add_subdirectory(newton_tolerance)

# source files in this directory
file(GLOB SOURCES "*.cpp" "*.h" "*.cu" "details/*.inl")
target_sources(cuda PRIVATE ${SOURCES})

if(MSVC)
    # Disable some warnings 
    # C4819: The file contains a character that cannot be represented in the current code page
    # target_compile_options(cuda PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/wd4819>)
endif()

# ------------------------------------------------------------------------------
# setup source group for the IDE
# ------------------------------------------------------------------------------
file(GLOB_RECURSE SOURCE_GROUP_FILES "*.h" "*.cpp" "*.cu" "*.inl")
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/.." FILES ${SOURCE_GROUP_FILES})
