# Qt GIF水印工具 完整开发方案（自用高颜值Windows版）

> 版本：v3（2026-06-21 修订）
> **v3 修订摘要**（基于实施性评估）：
> - 新增 **§5.2 Windows + QProcess 参数转义**（最高频踩坑点，原方案遗漏）
> - 重写 **§5.1 坐标系映射**：overlay 改为"锁水印中心"表达式，彻底规避旋转导致的外接矩形换算难题
> - 新增 **§5.7 预览/导出渲染一致性** 说明，明确"所见即所得"的像素级偏差边界
> - **§4.2 命令模板**：overlay 表达式改为锁中心；补"取消导出"流程
> - **§5.2/§5.3 进度解析**：增加 `qBound(0,100)` 兜底与降级策略，应对异常 duration 的 GIF
> - **§5.6 palettegen**：增加 `stats_mode` 适用边界 + 质量模式开关
> - **§6 FFmpegRunner**：补 `cancelExport()`、参数防注入（clamp + 定点格式化，禁科学计数法/逗号）
> - **§3 工程结构**：统一目标名为 `GifWaterMarkTool`；新增 §3.2「当前工程现状与落地起点」
> - **§2.3 依赖**：明确锁定一个 ffmpeg release 版本，规避滤镜兼容性
>
> v2 修订说明：v1 采用 giflib + stb_image 手写图像处理，存在"GIF 无法无损、giflib 编码需自写色彩量化、缺 disposal 帧合成"等硬伤。v2 起改为 **ffmpeg 全权负责 GIF 解码/水印叠加/量化/编码**，C++/QML 只负责界面、预览、拼命令、调度，复杂度降低约 70%，质量更高、更省事。

---

## 一、项目整体概述

### 1.1 项目定位

自用轻量化 Windows 桌面工具，基于 Qt Quick 开发高颜值现代化界面，实现**自定义 GIF 图片批量帧叠加水印**功能。支持可视化拖拽水印位置、调节缩放/透明度/旋转，保留原 GIF 帧率、循环，最终导出高质量新 GIF。

核心特点：高颜值无老旧控件、可视化交互顺滑、导出质量高、开发省事稳定。

### 1.2 需求清单

- 支持导入本地 GIF 动图、透明 PNG 水印图片
- 可视化画布预览，鼠标拖拽水印、滚轮缩放水印
- 参数调节：水印 XY 坐标、缩放比例、透明度、旋转角度
- 全自动逐帧叠加水印，保留原 GIF 帧率与无限循环
- 自定义导出路径，实时进度反馈、**支持导出中途取消**
- 现代化 UI：圆角、阴影、深浅色主题、动画过渡

### 1.3 关键设计决策

| 决策 | 选择 | 理由 |
|---|---|---|
| GIF 解码 / 编码 / 量化 | **ffmpeg** | 成熟稳定、质量最高、无需自写量化算法 |
| 水印叠加 | ffmpeg `overlay` 滤镜 | 支持缩放/旋转/透明/边界裁剪，无需手写像素混合 |
| 实时预览 | QML（只读播放 + 拖拽） | Qt 原生只读播放没问题，问题只在"写出"，故预览用 QML |
| UI 框架 | Qt Quick (QML) | 原生支持圆角/模糊/阴影/动画，高颜值 |
| 后端 | C++ Qt | 负责文件管理、拼 ffmpeg 命令、QProcess 调度、进度解析 |

> ⚠️ 关于"无损 GIF"：GIF 格式每帧最多 256 色、透明度仅 1-bit，**叠加水印后必然重新量化，本质有损**。本方案以"高质量量化 + 抖动"为目标（ffmpeg `palettegen`/`paletteuse`），而非追求不可能的无损。

---

## 二、最终确定技术栈

### 2.1 整体架构

```
UI 前端 ：Qt 6 + Qt Quick (QML)        —— 高颜值现代界面
预览引擎：QImageReader / QMovie          —— 只读播放 GIF、无编辑需求
导出引擎：ffmpeg.exe + QProcess          —— 唯一核心，全权负责 GIF 处理
构建系统：CMake + qt_add_qml_module       —— Qt 6 主推方式
打包分发：windeployqt + 随程序分发 ffmpeg.exe
```

### 2.2 技术选型理由

- **ffmpeg 负责全部 GIF 处理**：解码、`overlay` 叠加水印、`scale`/`rotate`/`colorchannelmixer` 做缩放/旋转/透明、`palettegen` + `paletteuse` 做高质量量化与 Floyd-Steinberg 抖动、自动处理 disposal 帧合成与循环。一条命令搞定，无需任何手写图像算法。
- **弃用 Qt 原生 GIF 编辑**（QMovie / QImageWriter 写 GIF）：原生写出多帧 GIF 调色板丢失、透明白边、帧率错乱，仅用于**只读预览播放**。
- **弃用 giflib / stb_image 手写方案**：giflib 编码器需自写色彩量化，stb 不支持写多帧 GIF，工作量大且质量不如 ffmpeg。
- **Qt Quick 做 UI**：原生圆角、毛玻璃、阴影、动画、自适应布局，质感远超 WPF 默认样式。
- **QProcess 异步调度**：ffmpeg 在独立进程运行，UI 线程零阻塞，天然解决大 GIF 卡顿问题；可随时 `kill()` 取消。

### 2.3 依赖清单

| 依赖 | 来源 | 体积 | 说明 |
|---|---|---|---|
| Qt 6.5+ MinGW64 | Qt 官方安装器 | — | UI 框架（当前工程实测 **6.5.3 MinGW64**） |
| ffmpeg.exe（静态构建） | gyan.dev | ~97MB | 放入 `tools/`，运行时按 app 目录定位，自用无需精简 |

> **🔒 ffmpeg 版本锁定**：当前工程已部署 **gyan.dev `ffmpeg-8.1.1-essentials_build`**（96.8MB，含 `overlay`/`palettegen`/`paletteuse`/`colorchannelmixer`/`rotate` 等全部所需滤镜，essentials 即够用，无需 full build）。固定使用该 release 写进 `README`，避免 `paletteuse diff_mode`、`palettegen stats_mode` 等参数在老版本的行为差异。自用不考虑版权与体积，直接随程序分发完整静态 ffmpeg 即可。

---

## 三、项目工程结构

### 3.1 目标结构

```
GifWaterMarkTool/
├── main.cpp                     # 程序入口、QML 与 C++ 类注册（QML_ELEMENT）
├── qml/
│   ├── Main.qml                 # 主界面：布局、预览画布、控制面板
│   ├── CanvasPreview.qml        # 预览画布：GIF 底图 + 可拖拽水印
│   └── ParameterPanel.qml       # 参数面板：坐标/缩放/透明度/旋转
├── core/
│   ├── ffmpegrunner.h/cpp       # 核心类：构建命令、QProcess、进度解析、导出、取消
│   ├── gifprobe.h/cpp           # 探测 GIF 时长/尺寸（用于进度百分比）
│   └── paths.h/cpp              # ffmpeg.exe 定位、临时文件路径管理
├── tools/
│   └── ffmpeg.exe               # 随程序分发的静态 ffmpeg
└── CMakeLists.txt               # Qt 6 构建配置
```

> 相比 v1 砍掉 `gifprocessor`、`watermarker`、`filehelper`、`dragimage` 等手写类，合并为 `FFmpegRunner` 一个核心类。

### 3.2 当前工程现状与落地起点（v3 新增）

当前仓库是 Qt Creator 生成的**纯空骨架**，与目标结构的差异需在 P0 阶段先行对齐：

| 项 | 现状 | P0 目标 |
|---|---|---|
| 目录布局 | `main.cpp`/`Main.qml` 均在根目录 | 拆分至 `qml/`、新增 `core/`、`tools/` |
| 目标名 | `appGifWaterMarkTool` | 统一为 `GifWaterMarkTool`（同步改 `main.cpp` 的 `loadFromModule`） |
| Main.qml | Hello World + 虚拟键盘空壳 | 重写为卡片式主界面 |
| Qt 版本 | 6.5.3 MinGW64 Debug | ✅ 已匹配，无需更换套件 |
| C++ 核心类 | 不存在 | 新建 `core/FFmpegRunner` 等 |

> ⚠️ `main.cpp` 中 `qputenv("QT_IM_MODULE", "qtvirtualkeyboard")` 与 Main.qml 的 `InputPanel` 是模板残留，桌面端不需要虚拟键盘，P0 一并移除。

---

## 四、核心功能实现流程

### 4.1 界面 UI 设计（QML 现代化布局）

整体采用**卡片式分区布局**，适配 Win11 现代风格，所有控件自带圆角、悬浮动画、阴影层级：

1. **顶部导航区**：深色标题栏、窗口圆角、主题切换按钮（亮/暗模式）
2. **文件操作卡片**：选择 GIF、选择水印 PNG 按钮，显示当前文件路径
3. **预览画布卡片（核心）**
   - 底层：QImageReader 播放 GIF 作为动态预览底图（只读）
   - 上层：可拖拽、可缩放、可旋转的水印 `Image` 控件
   - 交互：鼠标左键拖拽移位、滚轮缩放、滑条改透明度/旋转，实时同步参数面板
4. **水印参数卡片**：XY 坐标输入、缩放滑块、透明度滑块、旋转角度调节
5. **导出控制卡片**：开始处理、进度条、**取消按钮**、保存路径选择、导出按钮

### 4.2 核心业务流程

整个流程分为两段：**预览（纯 QML，即时）** 与 **导出（一条 ffmpeg 命令）**。

#### 阶段 A：预览（QML 完成，无 ffmpeg 参与）

- `QImageReader` / `QMovie` 播放 GIF 底图（**只读播放，Qt 原生无坑**）
- 水印用 QML `Image` 叠加，鼠标拖拽改位置、滚轮改缩放、滑条改透明度/旋转
- 用户在画布上调整的参数实时缓存到 C++ 的 `WatermarkParams` 结构
- **拖拽锚点固定为水印中心点**（见 §5.1，与导出坐标系一致）

#### 阶段 B：导出（ffmpeg 一条命令完成全部）

用户点击导出后，`FFmpegRunner` 做五件事：

1. **参数校验**：clamp 所有数值到合法区间，定点格式化（禁科学计数法/逗号，防滤镜表达式注入）
2. **坐标换算**：把 QML 预览的"水印中心点"换算回 GIF 原图像素坐标（§5.1）
3. **构建滤镜图**：根据参数填充 ffmpeg `-filter_complex` 字符串
4. **异步执行**：`QProcess` 启动 ffmpeg，解析 `-progress` 输出更新进度条；**支持 `cancelExport()` 中途 kill**
5. **完成回调**：导出结束（成功/失败/取消三态）弹窗提示，成功时打开输出文件夹

#### ffmpeg 导出命令模板（v3：overlay 锁中心）

```bash
ffmpeg -y -i input.gif -i watermark.png -filter_complex "
  [1:v]scale=iw*S:ih*S,
       rotate=A*PI/180:ow=rotw(A*PI/180):oh=roth(A*PI/180):fillcolor=0x00000000,
       format=rgba,colorchannelmixer=aa=O[wm];
  [0:v][wm]overlay=x=CX-w/2:y=CY-h/2[comp];
  [comp]split=2[a][b];
  [a]palettegen=stats_mode=diff[pal];
  [b][pal]paletteuse=dither=floyd_steinberg:diff_mode=rectangle[out]
" -map "[out]" -progress pipe:1 -nostats output.gif
```

| 片段 | 作用 | 参数来源 |
|---|---|---|
| `scale=iw*S:ih*S` | 水印按比例缩放 | 缩放滑块 S |
| `rotate=A*PI/180:fillcolor=0x00000000` + `ow/oh=rotw/roth` | 旋转、透明填充、不切角 | 旋转角度 A |
| `colorchannelmixer=aa=O` | 透明度（O=0~1） | 透明度滑块 O |
| `overlay=x=CX-w/2:y=CY-h/2` | **以水印中心 (CX,CY) 定位**，`w/h` 为旋转后实际尺寸，旋转外接矩形偏移由 ffmpeg 自动处理 | 换算后的中心坐标 CX、CY |
| `palettegen=stats_mode=diff` | 针对动画生成调色板，静态区域保真 | 质量模式开关（§5.6） |
| `paletteuse=dither=floyd_steinberg:diff_mode=rectangle` | 高质量抖动 + 只编码变化区域（文件更小） | 固定 |
| `-progress pipe:1` | 进度以 key=value 输出到 stdout，便于解析 | 固定 |

> **🔑 为何用锁中心而非 `overlay=X:Y`（v3 关键修订）**：rotate 用 `ow=rotw()/oh=roth()` 把画布扩到旋转外接矩形，若用左上角 `X:Y`，旋转角度越大、用户拖拽的视觉中心与实际锚点偏移越大，坐标换算极易出错。改用 `x=CX-w/2:y=CY-h/2`，`w/h` 是 overlay 前景（旋转后水印）的实际尺寸——**用户拖中心、导出锚中心，旋转带来的尺寸变化由 ffmpeg 内部消化**，换算公式退化为纯线性（§5.1），彻底规避此难点。

> **帧率 / 循环**：不添加 `-r` 参数，ffmpeg 自动沿用输入 pts 保留原帧率；GIF muxer 默认 `loop=0`（无限循环），原需求自动满足。（异常 pts 的 GIF 见 §5.3 兜底）

---

## 五、ffmpeg 集成关键技术点

> 本章替代 v1 的"难点"章节。原白边、帧率错乱、色彩量化、大 GIF 卡顿等问题均由 ffmpeg 解决，本章只关注 ffmpeg 集成本身的注意点与已知边界。

### 5.1 坐标系映射（v3 重写）

QML 预览画布通常按窗口大小缩放显示 GIF，水印**中心点**坐标换算回 GIF 原始像素坐标，再填入锁中心表达式 `overlay=x=CX-w/2:y=CY-h/2`：

```
预览缩放比 displayScale = 显示宽度 / GIF 原始宽度
# qmlCx/qmlCy 是水印中心在预览画布中的坐标，canvasOffset 是 GIF 底图左上角相对画布原点的偏移
gifCenterX = (qmlCx - canvasOffsetX) / displayScale
gifCenterY = (qmlCy - canvasOffsetY) / displayScale
# 直接填入 overlay：x=gifCenterX-w/2:y=gifCenterY-h/2
```

由于采用锁中心表达式，**无需关心旋转导致的外接矩形尺寸变化**——这是 v3 相对原方案最大的简化。

### 5.2 Windows + QProcess 参数转义（v3 新增，最高频踩坑点）

filter_complex 字符串含大量括号、冒号、分号，Windows 下传参是经典坑。**正确做法**：

```cpp
// ✅ 用 QStringList 逐参数传递，让 QProcess 处理引号
QStringList args = {
    "-y",
    "-i", m_gifPath,
    "-i", m_waterPath,
    "-filter_complex", buildFilterComplex(),   // 整个滤镜图作为单个参数
    "-map", "[out]",                            // 不要手动加双引号！
    "-progress", "pipe:1",
    "-nostats",
    m_outPath
};
m_proc->setProgram(paths::ffmpegExecutable());
m_proc->setArguments(args);
m_proc->start();
```

**避坑要点**：
1. ❌ 不要把整条命令拼成单字符串再 `start(string)`——Windows 引号/空格转义会爆炸
2. ❌ 不要给 `-map "[out]"` 手动加双引号——那是 shell 语法，`QStringList` 元素 `[out]` 即可
3. ✅ filter_complex 内部尽量**避免双引号**（模板用 `fillcolor=0x00000000` 而非带引号写法，已规避）
4. ✅ 用 `pipe:1` 取 stdout，`pipe:2` 取 stderr；务必连接 `readyReadStandardOutput`/`readyReadStandardError` 信号流式读取，避免大输出缓冲区塞满死锁

### 5.3 进度解析（用 `-progress`，勿抓 stderr）

ffmpeg 加 `-progress pipe:1 -nostats` 后，stdout 输出机器可读的 key=value：

```
frame=123
out_time_ms=4920000
progress=continue
...
progress=end
```

- 解析 `out_time_ms` / GIF 总时长 → 进度百分比
- 出现 `progress=end` → 导出完成
- 比 v1 抓 stderr `frame=` 文本的方式稳定得多

**v3 兜底（应对异常 GIF）**：
- 百分比必须 `qBound(0, pct, 100)`，避免变帧率 GIF 导致 >100% 跳变
- `progress=end` 时强制设为 100%
- **降级策略**：若总时长探测失败（见 §5.4），改用"已处理帧数 / 总帧数"作为进度分子

### 5.4 GIF 总时长探测

导出前跑一次 `ffmpeg -i input.gif`（无输出参数），从 stderr 抓 `Duration: 00:00:05.00` 解析总时长，用于进度百分比计算（不耗帧、很快）。

> **边界**：部分 GIF（变帧率/异常 pts）的 `Duration:` 不准甚至缺失，此时进度百分比不可靠——启用 §5.3 的帧数降级策略，UI 上进度条仍能平滑推进。

### 5.5 ffmpeg.exe 定位

用绝对路径调用，**不依赖系统 PATH**：

```cpp
QString ffmpegPath = QCoreApplication::applicationDirPath() + "/tools/ffmpeg.exe";
```

确保发布时 `tools/ffmpeg.exe` 随 exe 一起分发。启动前检查存在性，缺失则友好提示。

### 5.6 调色板质量模式（v3 新增）

`palettegen=stats_mode` 的选择影响质量与适用场景，自用建议提供**两档质量开关**：

| 模式 | stats_mode | 适用场景 | 代价 |
|---|---|---|---|
| 快速（默认） | `diff` | 静态背景 + 小动区（多数表情包） | 调色板生成快 |
| 高质量 | `full` | 全屏高频动态 GIF | 调色板扫描全帧，大 GIF 较慢 |

`paletteuse` 的 `diff_mode=rectangle` 固定保留（只编码变化区域，文件更小）。

### 5.7 预览/导出渲染一致性（v3 新增）

预览走 QML（`Image` 的旋转/缩放），导出走 ffmpeg（`scale`/`rotate`），**两条渲染管线算法不同**，旋转与半透明边缘存在像素级偏差：

- QML `Image` 旋转中心、缩放插值（平滑 vs 最近邻）与 ffmpeg 不完全一致
- 半透明水印边缘抗锯齿细节可能有 1~2px 差异

**对策**（按成本递增）：
1. **低成本（推荐 MVP）**：预览区标注"预览仅供参考，以导出结果为准"，导出后提供"一键重新导出"入口
2. **高一致性（可选增强）**：用 QML `Item::grabToImage()` 把**已处理好的水印**（含旋转/透明）导出为 PNG，再让 ffmpeg 仅做 `overlay` 贴图——渲染完全由 Qt 一手包办，所见即所得。代价：失去 ffmpeg 原生旋转/透明的矢量精度，但自用足够

### 5.8 出错处理

- 启动前检查 `ffmpeg.exe` 是否存在，缺失则提示用户
- `QProcess::exitCode() != 0` 时把 stderr 末尾内容弹给用户排错
- 导出目标路径不可写 / 磁盘满等，捕获并友好提示
- 用户主动取消：`m_proc->kill()`，`finished` 信号以"取消"状态回调（区别于失败）

---

## 六、FFmpegRunner 类设计（核心）

```cpp
// ffmpegrunner.h
class FFmpegRunner : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString gifPath    READ gifPath    WRITE setGifPath    NOTIFY gifPathChanged)
    Q_PROPERTY(QString waterPath READ waterPath WRITE setWaterPath NOTIFY waterPathChanged)
    Q_PROPERTY(QString outPath   READ outPath   WRITE setOutPath   NOTIFY outPathChanged)
    Q_PROPERTY(double wmX        READ wmX       WRITE setWmX       NOTIFY wmXChanged)       // 水印中心 X（GIF 原图像素）
    Q_PROPERTY(double wmY        READ wmY       WRITE setWmY       NOTIFY wmYChanged)       // 水印中心 Y
    Q_PROPERTY(double wmScale    READ wmScale   WRITE setWmScale   NOTIFY wmScaleChanged)   // S
    Q_PROPERTY(double wmOpacity  READ wmOpacity WRITE setWmOpacity NOTIFY wmOpacityChanged) // O 0~1
    Q_PROPERTY(double wmRotate   READ wmRotate  WRITE setWmRotate  NOTIFY wmRotateChanged)  // A 度
    Q_PROPERTY(int progress      READ progress  NOTIFY progressChanged)
    Q_PROPERTY(bool running      READ running   NOTIFY runningChanged)

public:
    Q_INVOKABLE void exportGif();       // 拼命令 + 启动 QProcess（§5.2 传参方式）
    Q_INVOKABLE void cancelExport();    // v3：中途 kill，finished 以"取消"状态回调
    Q_INVOKABLE double totalDurationMs(); // 探测 GIF 时长（失败返回 -1，触发帧数降级）

signals:
    void progressChanged(int percent);
    void runningChanged();
    // ok=false 时 errorMsg 有值；status 区分 失败/取消
    void finished(bool ok, int status, QString outputPath, QString errorMsg);

private:
    QString buildFilterComplex() const;   // 填充 -filter_complex 模板（锁中心版）
    QString fmt(double v) const;          // v3：定点格式化 QString::number(v,'f',4)，禁科学计数法/逗号
    void clampParams();                   // v3：S∈[0.01,10] O∈[0,1] A∈[-360,360]
    void parseProgress(const QByteArray &line);
    QProcess *m_proc = nullptr;
    // ... 字段省略
};
```

> **`buildFilterComplex()` 安全要点（v3）**：调用前先 `clampParams()` 钳制范围，所有数值经 `fmt()` 转成定点字符串再拼接，**避免** `0.0001` 被格式化成 `1e-04`、或本地化逗号 `0,5` 导致 ffmpeg 滤镜表达式解析失败。

---

## 七、编译与打包流程（Windows）

### 7.1 编译配置

- 编译套件：Qt 6.5+ MinGW64（当前 6.5.3）
- 构建系统：**CMake**（Qt 6 主推，用 `qt_add_executable` + `qt_add_qml_module`）
- 编译模式：Release 发布模式

### 7.2 打包步骤

1. Release 编译生成 exe
2. `windeployqt --qmldir qml GifWaterMarkTool.exe` 拷贝 Qt 依赖库、插件、QML 资源
3. 把静态 `ffmpeg.exe` 复制到发布目录的 `tools/` 下
4. 发布目录整体打包（自用，无需单文件封装）

> v1 的 Enigma 单文件封装步骤可选（带 ffmpeg 后已非"单文件无依赖"，封装意义不大）。自用直接发文件夹即可，体积约 80~120MB。

---

## 八、可选拓展功能（后期迭代）

- 批量导入多个 GIF，统一批量加水印（`FFmpegRunner` 外层加队列循环即可）
- 保存水印参数预设，一键复用配置（序列化 `WatermarkParams` 到 JSON）
- 支持文字水印（ffmpeg `drawtext` 滤镜，或 QML 预渲染文字 PNG 再叠加）
- 水印平铺、居中、居底等快捷定位（预设 `overlay` 表达式）
- GIF 压缩、分辨率缩放（`scale` + `paletteuse` 降低帧数/分辨率）

---

## 九、方案优势总结

1. **省事稳定**：图像处理全部交给成熟的 ffmpeg，无需自写量化/抖动/disposal 等算法，bug 面极小
2. **质量最高**：ffmpeg `palettegen` + Floyd-Steinberg 抖动，输出质量优于手写方案
3. **颜值拉满**：Qt Quick 原生现代 UI，支持 Win11 圆角/阴影/模糊/动画/深浅主题
4. **交互顺滑**：QProcess 异步调度，UI 零阻塞，大 GIF 不卡顿，可随时取消
5. **开发高效**：核心仅一个 `FFmpegRunner` 类，QML 界面快速迭代，适合自用场景

---

## 附录：实施计划（v3 落地路线图）

| 阶段 | 内容 | 产出 | 验收标准 |
|---|---|---|---|
| **P0 脚手架** (0.5d) | 重组目录（`qml/` `core/` `tools/`）；改 CMake 加 `core/*.cpp`、统一目标名；移除虚拟键盘残留；下载 ffmpeg.exe 入 `tools/` | 能编译的空壳 + ffmpeg 就位 | `tools/ffmpeg.exe -version` 跑通；exe 能启动 |
| **P1 核心引擎** (1d) | `FFmpegRunner`：`buildFilterComplex()`（锁中心版）、坐标换算、QProcess 调度（§5.2 传参）、`-progress` 解析、`cancelExport`、错误兜底；`paths.cpp`；`gifprobe` | 命令行能跑通完整导出 | 手动设参数导出一张带水印 GIF，质量正常、可取消 |
| **P2 QML 界面** (1.5d) | `Main.qml` 卡片布局+主题；`CanvasPreview.qml`（QMovie 播放 + 可拖拽/缩放/旋转水印，锚点=中心）；`ParameterPanel.qml`；C++↔QML 双向绑定 | 完整可视化交互 | 拖拽水印→参数同步→导出与预览基本一致 |
| **P3 打磨** (0.5d) | 进度条/完成弹窗（三态）/打开输出目录；质量模式开关；错误提示美化；windeployqt 打包验证 | 可分发文件夹 | 拷贝到干净 Win 机器双击 exe 正常运行 |

**总计约 3.5 天**（自用 MVP）。核心风险集中于 **P1 的 QProcess 转义 + 坐标换算**，建议 P1 先用一个测试 GIF + 水印验证滤镜命令跑通，再写 C++ 包装。
