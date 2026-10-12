cmake_minimum_required(VERSION 3.16)

project(GifWaterMarkTool VERSION 1.0.5 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Qml)

qt_standard_project_setup(REQUIRES 6.5)

# Content of downloaded design from Figma to Qt or similar
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

# Windows 可执行文件图标（朱砂印章）：configure 出绝对路径的 .rc 交给 windres
if (WIN32)
    enable_language(RC)
    set(GWM_ICON_ICO "${CMAKE_CURRENT_SOURCE_DIR}/resources/app.ico")
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/resources/app.rc.in
                   ${CMAKE_CURRENT_BINARY_DIR}/app.rc @ONLY)
    set(GWM_WIN_RC ${CMAKE_CURRENT_BINARY_DIR}/app.rc)
endif()

qt_add_executable(GifWaterMarkTool
    main.cpp
    core/paths.cpp
    core/gifprobe.cpp
    core/ffmpegrunner.cpp
    core/renamer.cpp
    core/videoexporter.cpp
    ${GWM_WIN_RC}
)

# Theme.qml 是 QML 单例（pragma Singleton），需显式标记
set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(GifWaterMarkTool
    URI GifWaterMarkTool
    QML_FILES
        qml/Main.qml
        qml/CanvasPreview.qml
        qml/Inspector.qml
        qml/Toast.qml
        qml/Theme.qml
        qml/GlassPanel.qml
        qml/AppMark.qml
        qml/AppButton.qml
        qml/FileChip.qml
        qml/Segmented.qml
        qml/ParamSlider.qml
        qml/NumberField.qml
        qml/Section.qml
        qml/ColorField.qml
        qml/Select.qml
        qml/SwitchRow.qml
        qml/SettingsDialog.qml
        qml/RenameDialog.qml
        qml/VideoView.qml
)

# 窗口/任务栏图标：嵌入 :/icons/appicon.png，main.cpp 里 setWindowIcon
qt_add_resources(GifWaterMarkTool "gwm_appicon"
    PREFIX "/icons"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/resources"
    FILES "${CMAKE_CURRENT_SOURCE_DIR}/resources/appicon.png"
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
