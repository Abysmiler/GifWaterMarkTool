# GIF 水印工具

一个基于 Qt6 + ffmpeg 的 GIF 水印工具，支持图片水印和文字水印。

## 功能

- 图片水印（PNG）和文字水印
- 拖拽调整水印位置，滚轮缩放
- 导出参数可调：分辨率、帧率、调色板、抖动算法
- gifsicle 深度优化，文件体积更小
- 水印参数记忆，换 GIF 自动复用

## 技术栈

- Qt 6.5 QML (Fusion)
- ffmpeg + gifsicle
- C++17 / CMake

## 构建

```bash
cmake -B build -DCMAKE_PREFIX_PATH=/path/to/Qt/6.5.3/mingw_64
cmake --build build
```
