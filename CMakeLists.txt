cmake_minimum_required(VERSION 3.16)

project(GifWaterMarkTool VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Qml)

qt_standard_project_setup(REQUIRES 6.5)

# Content of downloaded design from Figma to Qt or similar
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

qt_add_executable(GifWaterMarkTool
    main.cpp
    core/paths.cpp
    core/gifprobe.cpp
    core/ffmpegrunner.cpp
)

qt_add_qml_module(GifWaterMarkTool
    URI GifWaterMarkTool
    QML_FILES
        qml/Main.qml
        qml/CanvasPreview.qml
        qml/ParameterPanel.qml
        qml/Toast.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(GifWaterMarkTool PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.GifWaterMarkTool
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(GifWaterMarkTool
    PRIVATE Qt6::Quick Qt6::Qml
)

# core/ 头文件：qmltyperegistrar 生成的注册代码用 #include <ffmpegrunner.h> 引用
target_include_directories(GifWaterMarkTool PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/core
)

# 开发期 ffmpeg.exe 定位：paths.cpp 找不到 exe 同级 tools/ 时回退到源码 tools/
target_compile_definitions(GifWaterMarkTool PRIVATE
    SOURCE_TOOLS_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tools"
)

install(TARGETS GifWaterMarkTool
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
