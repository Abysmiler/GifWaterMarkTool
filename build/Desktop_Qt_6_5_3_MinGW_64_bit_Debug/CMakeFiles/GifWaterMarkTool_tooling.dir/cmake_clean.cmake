file(REMOVE_RECURSE
  "GifWaterMarkTool/qml/CanvasPreview.qml"
  "GifWaterMarkTool/qml/Main.qml"
  "GifWaterMarkTool/qml/ParameterPanel.qml"
  "GifWaterMarkTool/qml/Toast.qml"
)

# Per-language clean rules from dependency scanning.
foreach(lang )
  include(CMakeFiles/GifWaterMarkTool_tooling.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
