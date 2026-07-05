/****************************************************************************
** Meta object code from reading C++ file 'ffmpegrunner.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.5.3)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../core/ffmpegrunner.h"
#include <QtCore/qmetatype.h>

#if __has_include(<QtCore/qtmochelpers.h>)
#include <QtCore/qtmochelpers.h>
#else
QT_BEGIN_MOC_NAMESPACE
#endif


#include <memory>

#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'ffmpegrunner.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 68
#error "This file was generated using the moc from 6.5.3. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {

#ifdef QT_MOC_HAS_STRINGDATA
struct qt_meta_stringdata_CLASSFFmpegRunnerENDCLASS_t {};
static constexpr auto qt_meta_stringdata_CLASSFFmpegRunnerENDCLASS = QtMocHelpers::stringData(
    "FFmpegRunner",
    "QML.Element",
    "auto",
    "gifPathChanged",
    "",
    "waterPathChanged",
    "outPathChanged",
    "wmXChanged",
    "wmYChanged",
    "wmScaleChanged",
    "wmOpacityChanged",
    "wmRotateChanged",
    "progressChanged",
    "runningChanged",
    "qualityLevelChanged",
    "maxWidthChanged",
    "targetFpsChanged",
    "ditherModeChanged",
    "deepOptimizeChanged",
    "useTextWaterChanged",
    "textContentChanged",
    "textFontSizeChanged",
    "textColorChanged",
    "finished",
    "ok",
    "status",
    "outputPath",
    "errorMsg",
    "previewFrameReady",
    "pngPath",
    "width",
    "height",
    "totalDurationMs",
    "exportGif",
    "cancelExport",
    "openContainingFolder",
    "path",
    "extractPreview",
    "gifPath",
    "requestPreviewAsync",
    "waterPath",
    "outPath",
    "wmX",
    "wmY",
    "wmScale",
    "wmOpacity",
    "wmRotate",
    "progress",
    "running",
    "qualityLevel",
    "maxWidth",
    "targetFps",
    "ditherMode",
    "deepOptimize",
    "useTextWater",
    "textContent",
    "textFontSize",
    "textColor",
    "ExportState",
    "ExportSuccess",
    "ExportFailed",
    "ExportCancelled"
);
#else  // !QT_MOC_HAS_STRING_DATA
struct qt_meta_stringdata_CLASSFFmpegRunnerENDCLASS_t {
    uint offsetsAndSizes[124];
    char stringdata0[13];
    char stringdata1[12];
    char stringdata2[5];
    char stringdata3[15];
    char stringdata4[1];
    char stringdata5[17];
    char stringdata6[15];
    char stringdata7[11];
    char stringdata8[11];
    char stringdata9[15];
    char stringdata10[17];
    char stringdata11[16];
    char stringdata12[16];
    char stringdata13[15];
    char stringdata14[20];
    char stringdata15[16];
    char stringdata16[17];
    char stringdata17[18];
    char stringdata18[20];
    char stringdata19[20];
    char stringdata20[19];
    char stringdata21[20];
    char stringdata22[17];
    char stringdata23[9];
    char stringdata24[3];
    char stringdata25[7];
    char stringdata26[11];
    char stringdata27[9];
    char stringdata28[18];
    char stringdata29[8];
    char stringdata30[6];
    char stringdata31[7];
    char stringdata32[16];
    char stringdata33[10];
    char stringdata34[13];
    char stringdata35[21];
    char stringdata36[5];
    char stringdata37[15];
    char stringdata38[8];
    char stringdata39[20];
    char stringdata40[10];
    char stringdata41[8];
    char stringdata42[4];
    char stringdata43[4];
    char stringdata44[8];
    char stringdata45[10];
    char stringdata46[9];
    char stringdata47[9];
    char stringdata48[8];
    char stringdata49[13];
    char stringdata50[9];
    char stringdata51[10];
    char stringdata52[11];
    char stringdata53[13];
    char stringdata54[13];
    char stringdata55[12];
    char stringdata56[13];
    char stringdata57[10];
    char stringdata58[12];
    char stringdata59[14];
    char stringdata60[13];
    char stringdata61[16];
};
#define QT_MOC_LITERAL(ofs, len) \
    uint(sizeof(qt_meta_stringdata_CLASSFFmpegRunnerENDCLASS_t::offsetsAndSizes) + ofs), len 
Q_CONSTINIT static const qt_meta_stringdata_CLASSFFmpegRunnerENDCLASS_t qt_meta_stringdata_CLASSFFmpegRunnerENDCLASS = {
    {
        QT_MOC_LITERAL(0, 12),  // "FFmpegRunner"
        QT_MOC_LITERAL(13, 11),  // "QML.Element"
        QT_MOC_LITERAL(25, 4),  // "auto"
        QT_MOC_LITERAL(30, 14),  // "gifPathChanged"
        QT_MOC_LITERAL(45, 0),  // ""
        QT_MOC_LITERAL(46, 16),  // "waterPathChanged"
        QT_MOC_LITERAL(63, 14),  // "outPathChanged"
        QT_MOC_LITERAL(78, 10),  // "wmXChanged"
        QT_MOC_LITERAL(89, 10),  // "wmYChanged"
        QT_MOC_LITERAL(100, 14),  // "wmScaleChanged"
        QT_MOC_LITERAL(115, 16),  // "wmOpacityChanged"
        QT_MOC_LITERAL(132, 15),  // "wmRotateChanged"
        QT_MOC_LITERAL(148, 15),  // "progressChanged"
        QT_MOC_LITERAL(164, 14),  // "runningChanged"
        QT_MOC_LITERAL(179, 19),  // "qualityLevelChanged"
        QT_MOC_LITERAL(199, 15),  // "maxWidthChanged"
        QT_MOC_LITERAL(215, 16),  // "targetFpsChanged"
        QT_MOC_LITERAL(232, 17),  // "ditherModeChanged"
        QT_MOC_LITERAL(250, 19),  // "deepOptimizeChanged"
        QT_MOC_LITERAL(270, 19),  // "useTextWaterChanged"
        QT_MOC_LITERAL(290, 18),  // "textContentChanged"
        QT_MOC_LITERAL(309, 19),  // "textFontSizeChanged"
        QT_MOC_LITERAL(329, 16),  // "textColorChanged"
        QT_MOC_LITERAL(346, 8),  // "finished"
        QT_MOC_LITERAL(355, 2),  // "ok"
        QT_MOC_LITERAL(358, 6),  // "status"
        QT_MOC_LITERAL(365, 10),  // "outputPath"
        QT_MOC_LITERAL(376, 8),  // "errorMsg"
        QT_MOC_LITERAL(385, 17),  // "previewFrameReady"
        QT_MOC_LITERAL(403, 7),  // "pngPath"
        QT_MOC_LITERAL(411, 5),  // "width"
        QT_MOC_LITERAL(417, 6),  // "height"
        QT_MOC_LITERAL(424, 15),  // "totalDurationMs"
        QT_MOC_LITERAL(440, 9),  // "exportGif"
        QT_MOC_LITERAL(450, 12),  // "cancelExport"
        QT_MOC_LITERAL(463, 20),  // "openContainingFolder"
        QT_MOC_LITERAL(484, 4),  // "path"
        QT_MOC_LITERAL(489, 14),  // "extractPreview"
        QT_MOC_LITERAL(504, 7),  // "gifPath"
        QT_MOC_LITERAL(512, 19),  // "requestPreviewAsync"
        QT_MOC_LITERAL(532, 9),  // "waterPath"
        QT_MOC_LITERAL(542, 7),  // "outPath"
        QT_MOC_LITERAL(550, 3),  // "wmX"
        QT_MOC_LITERAL(554, 3),  // "wmY"
        QT_MOC_LITERAL(558, 7),  // "wmScale"
        QT_MOC_LITERAL(566, 9),  // "wmOpacity"
        QT_MOC_LITERAL(576, 8),  // "wmRotate"
        QT_MOC_LITERAL(585, 8),  // "progress"
        QT_MOC_LITERAL(594, 7),  // "running"
        QT_MOC_LITERAL(602, 12),  // "qualityLevel"
        QT_MOC_LITERAL(615, 8),  // "maxWidth"
        QT_MOC_LITERAL(624, 9),  // "targetFps"
        QT_MOC_LITERAL(634, 10),  // "ditherMode"
        QT_MOC_LITERAL(645, 12),  // "deepOptimize"
        QT_MOC_LITERAL(658, 12),  // "useTextWater"
        QT_MOC_LITERAL(671, 11),  // "textContent"
        QT_MOC_LITERAL(683, 12),  // "textFontSize"
        QT_MOC_LITERAL(696, 9),  // "textColor"
        QT_MOC_LITERAL(706, 11),  // "ExportState"
        QT_MOC_LITERAL(718, 13),  // "ExportSuccess"
        QT_MOC_LITERAL(732, 12),  // "ExportFailed"
        QT_MOC_LITERAL(745, 15)   // "ExportCancelled"
    },
    "FFmpegRunner",
    "QML.Element",
    "auto",
    "gifPathChanged",
    "",
    "waterPathChanged",
    "outPathChanged",
    "wmXChanged",
    "wmYChanged",
    "wmScaleChanged",
    "wmOpacityChanged",
    "wmRotateChanged",
    "progressChanged",
    "runningChanged",
    "qualityLevelChanged",
    "maxWidthChanged",
    "targetFpsChanged",
    "ditherModeChanged",
    "deepOptimizeChanged",
    "useTextWaterChanged",
    "textContentChanged",
    "textFontSizeChanged",
    "textColorChanged",
    "finished",
    "ok",
    "status",
    "outputPath",
    "errorMsg",
    "previewFrameReady",
    "pngPath",
    "width",
    "height",
    "totalDurationMs",
    "exportGif",
    "cancelExport",
    "openContainingFolder",
    "path",
    "extractPreview",
    "gifPath",
    "requestPreviewAsync",
    "waterPath",
    "outPath",
    "wmX",
    "wmY",
    "wmScale",
    "wmOpacity",
    "wmRotate",
    "progress",
    "running",
    "qualityLevel",
    "maxWidth",
    "targetFps",
    "ditherMode",
    "deepOptimize",
    "useTextWater",
    "textContent",
    "textFontSize",
    "textColor",
    "ExportState",
    "ExportSuccess",
    "ExportFailed",
    "ExportCancelled"
};
#undef QT_MOC_LITERAL
#endif // !QT_MOC_HAS_STRING_DATA
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_CLASSFFmpegRunnerENDCLASS[] = {

 // content:
      11,       // revision
       0,       // classname
       1,   14, // classinfo
      27,   16, // methods
      19,  225, // properties
       1,  320, // enums/sets
       0,    0, // constructors
       0,       // flags
      21,       // signalCount

 // classinfo: key, value
       1,    2,

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       3,    0,  178,    4, 0x06,   20 /* Public */,
       5,    0,  179,    4, 0x06,   21 /* Public */,
       6,    0,  180,    4, 0x06,   22 /* Public */,
       7,    0,  181,    4, 0x06,   23 /* Public */,
       8,    0,  182,    4, 0x06,   24 /* Public */,
       9,    0,  183,    4, 0x06,   25 /* Public */,
      10,    0,  184,    4, 0x06,   26 /* Public */,
      11,    0,  185,    4, 0x06,   27 /* Public */,
      12,    0,  186,    4, 0x06,   28 /* Public */,
      13,    0,  187,    4, 0x06,   29 /* Public */,
      14,    0,  188,    4, 0x06,   30 /* Public */,
      15,    0,  189,    4, 0x06,   31 /* Public */,
      16,    0,  190,    4, 0x06,   32 /* Public */,
      17,    0,  191,    4, 0x06,   33 /* Public */,
      18,    0,  192,    4, 0x06,   34 /* Public */,
      19,    0,  193,    4, 0x06,   35 /* Public */,
      20,    0,  194,    4, 0x06,   36 /* Public */,
      21,    0,  195,    4, 0x06,   37 /* Public */,
      22,    0,  196,    4, 0x06,   38 /* Public */,
      23,    4,  197,    4, 0x06,   39 /* Public */,
      28,    3,  206,    4, 0x06,   44 /* Public */,

 // methods: name, argc, parameters, tag, flags, initial metatype offsets
      32,    0,  213,    4, 0x102,   48 /* Public | MethodIsConst  */,
      33,    0,  214,    4, 0x02,   49 /* Public */,
      34,    0,  215,    4, 0x02,   50 /* Public */,
      35,    1,  216,    4, 0x02,   51 /* Public */,
      37,    1,  219,    4, 0x02,   53 /* Public */,
      39,    1,  222,    4, 0x02,   55 /* Public */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Bool, QMetaType::Int, QMetaType::QString, QMetaType::QString,   24,   25,   26,   27,
    QMetaType::Void, QMetaType::QString, QMetaType::Int, QMetaType::Int,   29,   30,   31,

 // methods: parameters
    QMetaType::LongLong,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Bool, QMetaType::QString,   36,
    QMetaType::QString, QMetaType::QString,   38,
    QMetaType::Void, QMetaType::QString,   38,

 // properties: name, type, flags
      38, QMetaType::QString, 0x00015103, uint(0), 0,
      40, QMetaType::QString, 0x00015103, uint(1), 0,
      41, QMetaType::QString, 0x00015103, uint(2), 0,
      42, QMetaType::Double, 0x00015103, uint(3), 0,
      43, QMetaType::Double, 0x00015103, uint(4), 0,
      44, QMetaType::Double, 0x00015103, uint(5), 0,
      45, QMetaType::Double, 0x00015103, uint(6), 0,
      46, QMetaType::Double, 0x00015103, uint(7), 0,
      47, QMetaType::Int, 0x00015001, uint(8), 0,
      48, QMetaType::Bool, 0x00015001, uint(9), 0,
      49, QMetaType::Int, 0x00015103, uint(10), 0,
      50, QMetaType::Int, 0x00015103, uint(11), 0,
      51, QMetaType::Int, 0x00015103, uint(12), 0,
      52, QMetaType::Int, 0x00015103, uint(13), 0,
      53, QMetaType::Bool, 0x00015103, uint(14), 0,
      54, QMetaType::Bool, 0x00015103, uint(15), 0,
      55, QMetaType::QString, 0x00015103, uint(16), 0,
      56, QMetaType::Int, 0x00015103, uint(17), 0,
      57, QMetaType::QString, 0x00015103, uint(18), 0,

 // enums: name, alias, flags, count, data
      58,   58, 0x0,    3,  325,

 // enum data: key, value
      59, uint(FFmpegRunner::ExportSuccess),
      60, uint(FFmpegRunner::ExportFailed),
      61, uint(FFmpegRunner::ExportCancelled),

       0        // eod
};

Q_CONSTINIT const QMetaObject FFmpegRunner::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_CLASSFFmpegRunnerENDCLASS.offsetsAndSizes,
    qt_meta_data_CLASSFFmpegRunnerENDCLASS,
    qt_static_metacall,
    nullptr,
    qt_metaTypeArray<
        // property 'gifPath'
        QString,
        // property 'waterPath'
        QString,
        // property 'outPath'
        QString,
        // property 'wmX'
        double,
        // property 'wmY'
        double,
        // property 'wmScale'
        double,
        // property 'wmOpacity'
        double,
        // property 'wmRotate'
        double,
        // property 'progress'
        int,
        // property 'running'
        bool,
        // property 'qualityLevel'
        int,
        // property 'maxWidth'
        int,
        // property 'targetFps'
        int,
        // property 'ditherMode'
        int,
        // property 'deepOptimize'
        bool,
        // property 'useTextWater'
        bool,
        // property 'textContent'
        QString,
        // property 'textFontSize'
        int,
        // property 'textColor'
        QString,
        // Q_OBJECT / Q_GADGET
        FFmpegRunner,
        // method 'gifPathChanged'
        void,
        // method 'waterPathChanged'
        void,
        // method 'outPathChanged'
        void,
        // method 'wmXChanged'
        void,
        // method 'wmYChanged'
        void,
        // method 'wmScaleChanged'
        void,
        // method 'wmOpacityChanged'
        void,
        // method 'wmRotateChanged'
        void,
        // method 'progressChanged'
        void,
        // method 'runningChanged'
        void,
        // method 'qualityLevelChanged'
        void,
        // method 'maxWidthChanged'
        void,
        // method 'targetFpsChanged'
        void,
        // method 'ditherModeChanged'
        void,
        // method 'deepOptimizeChanged'
        void,
        // method 'useTextWaterChanged'
        void,
        // method 'textContentChanged'
        void,
        // method 'textFontSizeChanged'
        void,
        // method 'textColorChanged'
        void,
        // method 'finished'
        void,
        bool,
        int,
        const QString &,
        const QString &,
        // method 'previewFrameReady'
        void,
        const QString &,
        int,
        int,
        // method 'totalDurationMs'
        qint64,
        // method 'exportGif'
        void,
        // method 'cancelExport'
        void,
        // method 'openContainingFolder'
        bool,
        const QString &,
        // method 'extractPreview'
        QString,
        const QString &,
        // method 'requestPreviewAsync'
        void,
        const QString &
    >,
    nullptr
} };

void FFmpegRunner::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<FFmpegRunner *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->gifPathChanged(); break;
        case 1: _t->waterPathChanged(); break;
        case 2: _t->outPathChanged(); break;
        case 3: _t->wmXChanged(); break;
        case 4: _t->wmYChanged(); break;
        case 5: _t->wmScaleChanged(); break;
        case 6: _t->wmOpacityChanged(); break;
        case 7: _t->wmRotateChanged(); break;
        case 8: _t->progressChanged(); break;
        case 9: _t->runningChanged(); break;
        case 10: _t->qualityLevelChanged(); break;
        case 11: _t->maxWidthChanged(); break;
        case 12: _t->targetFpsChanged(); break;
        case 13: _t->ditherModeChanged(); break;
        case 14: _t->deepOptimizeChanged(); break;
        case 15: _t->useTextWaterChanged(); break;
        case 16: _t->textContentChanged(); break;
        case 17: _t->textFontSizeChanged(); break;
        case 18: _t->textColorChanged(); break;
        case 19: _t->finished((*reinterpret_cast< std::add_pointer_t<bool>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast< std::add_pointer_t<QString>>(_a[3])),(*reinterpret_cast< std::add_pointer_t<QString>>(_a[4]))); break;
        case 20: _t->previewFrameReady((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast< std::add_pointer_t<int>>(_a[3]))); break;
        case 21: { qint64 _r = _t->totalDurationMs();
            if (_a[0]) *reinterpret_cast< qint64*>(_a[0]) = std::move(_r); }  break;
        case 22: _t->exportGif(); break;
        case 23: _t->cancelExport(); break;
        case 24: { bool _r = _t->openContainingFolder((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 25: { QString _r = _t->extractPreview((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = std::move(_r); }  break;
        case 26: _t->requestPreviewAsync((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::gifPathChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::waterPathChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::outPathChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::wmXChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 3;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::wmYChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 4;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::wmScaleChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 5;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::wmOpacityChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 6;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::wmRotateChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 7;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::progressChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 8;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::runningChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 9;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::qualityLevelChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 10;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::maxWidthChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 11;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::targetFpsChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 12;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::ditherModeChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 13;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::deepOptimizeChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 14;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::useTextWaterChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 15;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::textContentChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 16;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::textFontSizeChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 17;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)();
            if (_t _q_method = &FFmpegRunner::textColorChanged; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 18;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)(bool , int , const QString & , const QString & );
            if (_t _q_method = &FFmpegRunner::finished; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 19;
                return;
            }
        }
        {
            using _t = void (FFmpegRunner::*)(const QString & , int , int );
            if (_t _q_method = &FFmpegRunner::previewFrameReady; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 20;
                return;
            }
        }
    }else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<FFmpegRunner *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< QString*>(_v) = _t->gifPath(); break;
        case 1: *reinterpret_cast< QString*>(_v) = _t->waterPath(); break;
        case 2: *reinterpret_cast< QString*>(_v) = _t->outPath(); break;
        case 3: *reinterpret_cast< double*>(_v) = _t->wmX(); break;
        case 4: *reinterpret_cast< double*>(_v) = _t->wmY(); break;
        case 5: *reinterpret_cast< double*>(_v) = _t->wmScale(); break;
        case 6: *reinterpret_cast< double*>(_v) = _t->wmOpacity(); break;
        case 7: *reinterpret_cast< double*>(_v) = _t->wmRotate(); break;
        case 8: *reinterpret_cast< int*>(_v) = _t->progress(); break;
        case 9: *reinterpret_cast< bool*>(_v) = _t->running(); break;
        case 10: *reinterpret_cast< int*>(_v) = _t->qualityLevel(); break;
        case 11: *reinterpret_cast< int*>(_v) = _t->maxWidth(); break;
        case 12: *reinterpret_cast< int*>(_v) = _t->targetFps(); break;
        case 13: *reinterpret_cast< int*>(_v) = _t->ditherMode(); break;
        case 14: *reinterpret_cast< bool*>(_v) = _t->deepOptimize(); break;
        case 15: *reinterpret_cast< bool*>(_v) = _t->useTextWater(); break;
        case 16: *reinterpret_cast< QString*>(_v) = _t->textContent(); break;
        case 17: *reinterpret_cast< int*>(_v) = _t->textFontSize(); break;
        case 18: *reinterpret_cast< QString*>(_v) = _t->textColor(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
        auto *_t = static_cast<FFmpegRunner *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setGifPath(*reinterpret_cast< QString*>(_v)); break;
        case 1: _t->setWaterPath(*reinterpret_cast< QString*>(_v)); break;
        case 2: _t->setOutPath(*reinterpret_cast< QString*>(_v)); break;
        case 3: _t->setWmX(*reinterpret_cast< double*>(_v)); break;
        case 4: _t->setWmY(*reinterpret_cast< double*>(_v)); break;
        case 5: _t->setWmScale(*reinterpret_cast< double*>(_v)); break;
        case 6: _t->setWmOpacity(*reinterpret_cast< double*>(_v)); break;
        case 7: _t->setWmRotate(*reinterpret_cast< double*>(_v)); break;
        case 10: _t->setQualityLevel(*reinterpret_cast< int*>(_v)); break;
        case 11: _t->setMaxWidth(*reinterpret_cast< int*>(_v)); break;
        case 12: _t->setTargetFps(*reinterpret_cast< int*>(_v)); break;
        case 13: _t->setDitherMode(*reinterpret_cast< int*>(_v)); break;
        case 14: _t->setDeepOptimize(*reinterpret_cast< bool*>(_v)); break;
        case 15: _t->setUseTextWater(*reinterpret_cast< bool*>(_v)); break;
        case 16: _t->setTextContent(*reinterpret_cast< QString*>(_v)); break;
        case 17: _t->setTextFontSize(*reinterpret_cast< int*>(_v)); break;
        case 18: _t->setTextColor(*reinterpret_cast< QString*>(_v)); break;
        default: break;
        }
    } else if (_c == QMetaObject::ResetProperty) {
    } else if (_c == QMetaObject::BindableProperty) {
    }
}

const QMetaObject *FFmpegRunner::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *FFmpegRunner::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_CLASSFFmpegRunnerENDCLASS.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int FFmpegRunner::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 27)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 27;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 27)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 27;
    }else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 19;
    }
    return _id;
}

// SIGNAL 0
void FFmpegRunner::gifPathChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void FFmpegRunner::waterPathChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void FFmpegRunner::outPathChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void FFmpegRunner::wmXChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void FFmpegRunner::wmYChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void FFmpegRunner::wmScaleChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void FFmpegRunner::wmOpacityChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void FFmpegRunner::wmRotateChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 7, nullptr);
}

// SIGNAL 8
void FFmpegRunner::progressChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 8, nullptr);
}

// SIGNAL 9
void FFmpegRunner::runningChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 9, nullptr);
}

// SIGNAL 10
void FFmpegRunner::qualityLevelChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 10, nullptr);
}

// SIGNAL 11
void FFmpegRunner::maxWidthChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 11, nullptr);
}

// SIGNAL 12
void FFmpegRunner::targetFpsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 12, nullptr);
}

// SIGNAL 13
void FFmpegRunner::ditherModeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 13, nullptr);
}

// SIGNAL 14
void FFmpegRunner::deepOptimizeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 14, nullptr);
}

// SIGNAL 15
void FFmpegRunner::useTextWaterChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 15, nullptr);
}

// SIGNAL 16
void FFmpegRunner::textContentChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 16, nullptr);
}

// SIGNAL 17
void FFmpegRunner::textFontSizeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 17, nullptr);
}

// SIGNAL 18
void FFmpegRunner::textColorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 18, nullptr);
}

// SIGNAL 19
void FFmpegRunner::finished(bool _t1, int _t2, const QString & _t3, const QString & _t4)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t3))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t4))) };
    QMetaObject::activate(this, &staticMetaObject, 19, _a);
}

// SIGNAL 20
void FFmpegRunner::previewFrameReady(const QString & _t1, int _t2, int _t3)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t2))), const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t3))) };
    QMetaObject::activate(this, &staticMetaObject, 20, _a);
}
QT_WARNING_POP
