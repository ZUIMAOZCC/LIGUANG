#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成标准 Xcode 工程 GRRoll.xcodeproj（Xcode 15 / objectVersion 56）。
用法: python3 generate_xcodeproj.py
会在脚本同级目录（即外层 GRRoll/）下创建 GRRoll.xcodeproj。
"""
import hashlib
import os

# ---- 配置 ----
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))  # 外层 GRRoll/
INNER = "GRRoll"  # 源码所在内层文件夹
PRODUCT_NAME = "GRRoll"
BUNDLE_ID = "com.grroll.camera"
APP_DISPLAY = "GR ROLL"

# 所有 Swift 源文件（相对于内层 GRRoll/ 的路径）
SWIFT_FILES = [
    "GRRollApp.swift",
    "ContentView.swift",
    "Core/Theme.swift",
    "Model/FilmLook.swift",
    "Model/AspectRatio.swift",
    "Model/Preset.swift",
    "Engine/GRLookFilter.swift",
    "Camera/CameraManager.swift",
    "Camera/CameraPreviewView.swift",
    "Store/SubscriptionManager.swift",
    "Utilities/WatermarkRenderer.swift",
    "Utilities/PhotoLibrary.swift",
    "Utilities/ImagePicker.swift",
    "Views/LookBar.swift",
    "Views/ParameterPanel.swift",
    "Views/EditorView.swift",
    "Views/CameraView.swift",
    "Views/PaywallView.swift",
    "Views/LibraryView.swift",
    "Views/PresetsView.swift",
    "Views/SettingsView.swift",
]

RESOURCE_FILES = ["Assets.xcassets", "Info.plist"]


def uid(tag: str) -> str:
    """生成 24 位大写十六进制稳定 UUID（基于内容哈希，保证可复现且不冲突）。"""
    return hashlib.sha1(tag.encode("utf-8")).hexdigest()[:24].upper()


# 预生成各类对象 ID
fr = {f: uid("FR:" + f) for f in SWIFT_FILES + RESOURCE_FILES}          # FileReference
bb = {f: uid("BB:" + f) for f in SWIFT_FILES}                           # BuildFile(源文件)
rb = {f: uid("RB:" + f) for f in RESOURCE_FILES}                        # BuildFile(资源)
assets_bb = rb["Assets.xcassets"]

MAIN_GROUP = uid("G:main")
SRC_GROUP = uid("G:src")
PROD_GROUP = uid("G:prod")
APP_FR = uid("FR:app")
TARGET = uid("T:grroll")
PROJECT = uid("P:grroll")
SOURCES_PHASE = uid("PH:sources")
FW_PHASE = uid("PH:frameworks")
RES_PHASE = uid("PH:resources")
PROJ_CLS = uid("CLS:proj")
TARGET_CLS = uid("CLS:target")
PROJ_DEBUG = uid("BC:projdebug")
PROJ_RELEASE = uid("BC:projrelease")
TARGET_DEBUG = uid("BC:tdebug")
TARGET_RELEASE = uid("BC:trelease")

T = "\t"


def build_pbxproj() -> str:
    lines = []
    lines.append("// !$*UTF8*$!")
    lines.append("{")
    lines.append(T + "archiveVersion = 1;")
    lines.append(T + "classes = {")
    lines.append(T + "};")
    lines.append(T + "objectVersion = 56;")
    lines.append(T + "objects = {")
    lines.append("")

    # ---- PBXBuildFile ----
    lines.append("/* Begin PBXBuildFile section */")
    for f in SWIFT_FILES:
        lines.append(T + fr[f] + " /* " + os.path.basename(f) + " in Sources */ = {isa = PBXBuildFile; fileRef = " + fr[f] + " /* " + os.path.basename(f) + " */; };")
    for f in RESOURCE_FILES:
        lines.append(T + rb[f] + " /* " + f + " in Resources */ = {isa = PBXBuildFile; fileRef = " + fr[f] + " /* " + f + " */; };")
    lines.append("/* End PBXBuildFile section */")
    lines.append("")

    # ---- PBXFileReference ----
    lines.append("/* Begin PBXFileReference section */")
    for f in SWIFT_FILES:
        lines.append(T + fr[f] + " /* " + os.path.basename(f) + " */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = " + INNER + "/" + f + "; sourceTree = \"<group>\"; };")
    # Assets.xcassets 是文件夹资源
    lines.append(T + fr["Assets.xcassets"] + " /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assets; path = " + INNER + "/Assets.xcassets; sourceTree = \"<group>\"; };")
    # Info.plist
    lines.append(T + fr["Info.plist"] + " /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = " + INNER + "/Info.plist; sourceTree = \"<group>\"; };")
    # 产物 .app
    lines.append(T + APP_FR + " /* " + PRODUCT_NAME + ".app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = " + PRODUCT_NAME + ".app; sourceTree = BUILT_PRODUCTS_DIR; };")
    lines.append("/* End PBXFileReference section */")
    lines.append("")

    # ---- PBXFrameworksBuildPhase（系统框架走 Swift 自动链接，留空即可）----
    lines.append("/* Begin PBXFrameworksBuildPhase section */")
    lines.append(T + FW_PHASE + " /* Frameworks */ = {")
    lines.append(T + T + "isa = PBXFrameworksBuildPhase;")
    lines.append(T + T + "buildActionMask = 2147483647;")
    lines.append(T + T + "files = (")
    lines.append(T + T + ");")
    lines.append(T + T + "runOnlyForDeploymentPostprocessing = 0;")
    lines.append(T + "};")
    lines.append("/* End PBXFrameworksBuildPhase section */")
    lines.append("")

    # ---- PBXGroup ----
    lines.append("/* Begin PBXGroup section */")
    lines.append(T + MAIN_GROUP + " = {")
    lines.append(T + T + "isa = PBXGroup;")
    lines.append(T + T + "children = (")
    lines.append(T + T + T + SRC_GROUP + " /* " + INNER + " */,")
    lines.append(T + T + T + PROD_GROUP + " /* Products */,")
    lines.append(T + T + ");")
    lines.append(T + T + "sourceTree = \"<group>\";")
    lines.append(T + "};")
    # 源码组（扁平列出，磁盘目录结构不受影响）
    lines.append(T + SRC_GROUP + " /* " + INNER + " */ = {")
    lines.append(T + T + "isa = PBXGroup;")
    lines.append(T + T + "children = (")
    for f in SWIFT_FILES:
        lines.append(T + T + T + fr[f] + " /* " + os.path.basename(f) + " */,")
    for f in RESOURCE_FILES:
        lines.append(T + T + T + fr[f] + " /* " + f + " */,")
    lines.append(T + T + ");")
    lines.append(T + T + "path = " + INNER + ";")
    lines.append(T + T + "sourceTree = \"<group>\";")
    lines.append(T + "};")
    # Products 组
    lines.append(T + PROD_GROUP + " /* Products */ = {")
    lines.append(T + T + "isa = PBXGroup;")
    lines.append(T + T + "children = (")
    lines.append(T + T + T + APP_FR + " /* " + PRODUCT_NAME + ".app */,")
    lines.append(T + T + ");")
    lines.append(T + T + "name = Products;")
    lines.append(T + T + "sourceTree = \"<group>\";")
    lines.append(T + "};")
    lines.append("/* End PBXGroup section */")
    lines.append("")

    # ---- PBXNativeTarget ----
    lines.append("/* Begin PBXNativeTarget section */")
    lines.append(T + TARGET + " /* " + PRODUCT_NAME + " */ = {")
    lines.append(T + T + "isa = PBXNativeTarget;")
    lines.append(T + T + "buildConfigurationList = " + TARGET_CLS + " /* Build configuration list for PBXNativeTarget \"" + PRODUCT_NAME + "\" */;")
    lines.append(T + T + "buildPhases = (")
    lines.append(T + T + T + SOURCES_PHASE + " /* Sources */,")
    lines.append(T + T + T + FW_PHASE + " /* Frameworks */,")
    lines.append(T + T + T + RES_PHASE + " /* Resources */,")
    lines.append(T + T + ");")
    lines.append(T + T + "buildRules = (")
    lines.append(T + T + ");")
    lines.append(T + T + "dependencies = (")
    lines.append(T + T + ");")
    lines.append(T + T + "name = " + PRODUCT_NAME + ";")
    lines.append(T + T + "productName = " + PRODUCT_NAME + ";")
    lines.append(T + T + "productReference = " + APP_FR + " /* " + PRODUCT_NAME + ".app */;")
    lines.append(T + T + "productType = \"com.apple.product-type.application\";")
    lines.append(T + "};")
    lines.append("/* End PBXNativeTarget section */")
    lines.append("")

    # ---- PBXProject ----
    lines.append("/* Begin PBXProject section */")
    lines.append(T + PROJECT + " /* Project object */ = {")
    lines.append(T + T + "isa = PBXProject;")
    lines.append(T + T + "attributes = {")
    lines.append(T + T + T + "BuildIndependentTargetsInParallel = 1;")
    lines.append(T + T + T + "LastSwiftUpdateCheck = 1500;")
    lines.append(T + T + T + "LastUpgradeCheck = 1500;")
    lines.append(T + T + T + "TargetAttributes = {")
    lines.append(T + T + T + T + TARGET + " = {")
    lines.append(T + T + T + T + T + T + "CreatedOnToolsVersion = 15.0;")
    lines.append(T + T + T + T + "};")
    lines.append(T + T + T + "};")
    lines.append(T + T + "};")
    lines.append(T + T + "buildConfigurationList = " + PROJ_CLS + " /* Build configuration list for PBXProject \"" + PRODUCT_NAME + "\" */;")
    lines.append(T + T + "compatibilityVersion = \"Xcode 14.0\";")
    lines.append(T + T + "developmentRegion = en;")
    lines.append(T + T + "hasScannedForEncodings = 0;")
    lines.append(T + T + "knownRegions = (")
    lines.append(T + T + T + "en,")
    lines.append(T + T + T + "Base,")
    lines.append(T + T + ");")
    lines.append(T + T + "mainGroup = " + MAIN_GROUP + ";")
    lines.append(T + T + "productRefGroup = " + PROD_GROUP + " /* Products */;")
    lines.append(T + T + "projectDirPath = \"\";")
    lines.append(T + T + "projectRoot = \"\";")
    lines.append(T + T + "targets = (")
    lines.append(T + T + T + TARGET + " /* " + PRODUCT_NAME + " */,")
    lines.append(T + T + ");")
    lines.append(T + "};")
    lines.append("/* End PBXProject section */")
    lines.append("")

    # ---- PBXResourcesBuildPhase ----
    lines.append("/* Begin PBXResourcesBuildPhase section */")
    lines.append(T + RES_PHASE + " /* Resources */ = {")
    lines.append(T + T + "isa = PBXResourcesBuildPhase;")
    lines.append(T + T + "buildActionMask = 2147483647;")
    lines.append(T + T + "files = (")
    lines.append(T + T + T + assets_bb + " /* Assets.xcassets in Resources */,")
    lines.append(T + T + ");")
    lines.append(T + T + "runOnlyForDeploymentPostprocessing = 0;")
    lines.append(T + "};")
    lines.append("/* End PBXResourcesBuildPhase section */")
    lines.append("")

    # ---- PBXSourcesBuildPhase ----
    lines.append("/* Begin PBXSourcesBuildPhase section */")
    lines.append(T + SOURCES_PHASE + " /* Sources */ = {")
    lines.append(T + T + "isa = PBXSourcesBuildPhase;")
    lines.append(T + T + "buildActionMask = 2147483647;")
    lines.append(T + T + "files = (")
    for f in SWIFT_FILES:
        lines.append(T + T + T + bb[f] + " /* " + os.path.basename(f) + " in Sources */,")
    lines.append(T + T + ");")
    lines.append(T + T + "runOnlyForDeploymentPostprocessing = 0;")
    lines.append(T + "};")
    lines.append("/* End PBXSourcesBuildPhase section */")
    lines.append("")

    # ---- XCBuildConfiguration ----
    proj_debug_settings = [
        ("ALWAYS_SEARCH_USER_PATHS", "NO"),
        ("CLANG_ANALYZER_NONNULL", "YES"),
        ("CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION", "YES_AGGRESSIVE"),
        ("CLANG_CXX_LANGUAGE_STANDARD", '"gnu++20"'),
        ("CLANG_ENABLE_MODULES", "YES"),
        ("CLANG_ENABLE_OBJC_ARC", "YES"),
        ("CLANG_ENABLE_OBJC_WEAK", "YES"),
        ("CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING", "YES"),
        ("CLANG_WARN_BOOL_CONVERSION", "YES"),
        ("CLANG_WARN_COMMA", "YES"),
        ("CLANG_WARN_CONSTANT_CONVERSION", "YES"),
        ("CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS", "YES"),
        ("CLANG_WARN_DIRECT_OBJC_ISA_USAGE", "YES_ERROR"),
        ("CLANG_WARN_DOCUMENTATION_COMMENTS", "YES"),
        ("CLANG_WARN_EMPTY_BODY", "YES"),
        ("CLANG_WARN_ENUM_CONVERSION", "YES"),
        ("CLANG_WARN_INFINITE_RECURSION", "YES"),
        ("CLANG_WARN_INT_CONVERSION", "YES"),
        ("CLANG_WARN_NON_LITERAL_NULL_CONVERSION", "YES"),
        ("CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF", "YES"),
        ("CLANG_WARN_OBJC_LITERAL_CONVERSION", "YES"),
        ("CLANG_WARN_OBJC_ROOT_CLASS", "YES_ERROR"),
        ("CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER", "YES"),
        ("CLANG_WARN_RANGE_LOOP_ANALYSIS", "YES"),
        ("CLANG_WARN_STRICT_PROTOTYPES", "YES"),
        ("CLANG_WARN_SUSPICIOUS_MOVE", "YES"),
        ("CLANG_WARN_UNGUARDED_AVAILABILITY", "YES_AGGRESSIVE"),
        ("CLANG_WARN_UNREACHABLE_CODE", "YES"),
        ("CLANG_WARN__DUPLICATE_METHOD_MATCH", "YES"),
        ("COPY_PHASE_STRIP", "NO"),
        ("DEBUG_INFORMATION_FORMAT", "dwarf"),
        ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
        ("ENABLE_TESTABILITY", "YES"),
        ("GCC_C_LANGUAGE_STANDARD", "gnu17"),
        ("GCC_DYNAMIC_NO_PIC", "NO"),
        ("GCC_NO_COMMON_BLOCKS", "YES"),
        ("GCC_OPTIMIZATION_LEVEL", "0"),
        ("GCC_PREPROCESSOR_DEFINITIONS", "(\n\t\t\t\t\"DEBUG=1\",\n\t\t\t\t\"$(inherited)\",\n\t\t\t);"),
        ("GCC_WARN_64_TO_32_BIT_CONVERSION", "YES"),
        ("GCC_WARN_ABOUT_RETURN_TYPE", "YES_ERROR"),
        ("GCC_WARN_UNDECLARED_SELECTOR", "YES"),
        ("GCC_WARN_UNINITIALIZED_AUTOS", "YES_AGGRESSIVE"),
        ("GCC_WARN_UNUSED_FUNCTION", "YES"),
        ("GCC_WARN_UNUSED_VARIABLE", "YES"),
        ("IPHONEOS_DEPLOYMENT_TARGET", "16.0"),
        ("LOCALIZATION_PREFERS_STRING_CATALOGS", "YES"),
        ("MTL_ENABLE_DEBUG_INFO", "INCLUDE_SOURCE"),
        ("MTL_FAST_MATH", "YES"),
        ("ONLY_ACTIVE_ARCH", "YES"),
        ("SDKROOT", "iphoneos"),
        ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "DEBUG"),
        ("SWIFT_OPTIMIZATION_LEVEL", "-Onone"),
    ]

    proj_release_settings = [
        ("ALWAYS_SEARCH_USER_PATHS", "NO"),
        ("CLANG_ANALYZER_NONNULL", "YES"),
        ("CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION", "YES_AGGRESSIVE"),
        ("CLANG_CXX_LANGUAGE_STANDARD", '"gnu++20"'),
        ("CLANG_ENABLE_MODULES", "YES"),
        ("CLANG_ENABLE_OBJC_ARC", "YES"),
        ("CLANG_ENABLE_OBJC_WEAK", "YES"),
        ("CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING", "YES"),
        ("CLANG_WARN_BOOL_CONVERSION", "YES"),
        ("CLANG_WARN_COMMA", "YES"),
        ("CLANG_WARN_CONSTANT_CONVERSION", "YES"),
        ("CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS", "YES"),
        ("CLANG_WARN_DIRECT_OBJC_ISA_USAGE", "YES_ERROR"),
        ("CLANG_WARN_DOCUMENTATION_COMMENTS", "YES"),
        ("CLANG_WARN_EMPTY_BODY", "YES"),
        ("CLANG_WARN_ENUM_CONVERSION", "YES"),
        ("CLANG_WARN_INFINITE_RECURSION", "YES"),
        ("CLANG_WARN_INT_CONVERSION", "YES"),
        ("CLANG_WARN_NON_LITERAL_NULL_CONVERSION", "YES"),
        ("CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF", "YES"),
        ("CLANG_WARN_OBJC_LITERAL_CONVERSION", "YES"),
        ("CLANG_WARN_OBJC_ROOT_CLASS", "YES_ERROR"),
        ("CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER", "YES"),
        ("CLANG_WARN_RANGE_LOOP_ANALYSIS", "YES"),
        ("CLANG_WARN_STRICT_PROTOTYPES", "YES"),
        ("CLANG_WARN_SUSPICIOUS_MOVE", "YES"),
        ("CLANG_WARN_UNGUARDED_AVAILABILITY", "YES_AGGRESSIVE"),
        ("CLANG_WARN_UNREACHABLE_CODE", "YES"),
        ("CLANG_WARN__DUPLICATE_METHOD_MATCH", "YES"),
        ("COPY_PHASE_STRIP", "NO"),
        ("DEBUG_INFORMATION_FORMAT", "dwarf-with-dsym"),
        ("ENABLE_NS_ASSERTIONS", "NO"),
        ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
        ("GCC_C_LANGUAGE_STANDARD", "gnu17"),
        ("GCC_NO_COMMON_BLOCKS", "YES"),
        ("GCC_WARN_64_TO_32_BIT_CONVERSION", "YES"),
        ("GCC_WARN_ABOUT_RETURN_TYPE", "YES_ERROR"),
        ("GCC_WARN_UNDECLARED_SELECTOR", "YES"),
        ("GCC_WARN_UNINITIALIZED_AUTOS", "YES_AGGRESSIVE"),
        ("GCC_WARN_UNUSED_FUNCTION", "YES"),
        ("GCC_WARN_UNUSED_VARIABLE", "YES"),
        ("IPHONEOS_DEPLOYMENT_TARGET", "16.0"),
        ("LOCALIZATION_PREFERS_STRING_CATALOGS", "YES"),
        ("MTL_ENABLE_DEBUG_INFO", "NO"),
        ("MTL_FAST_MATH", "YES"),
        ("SDKROOT", "iphoneos"),
        ("SWIFT_COMPILATION_MODE", "wholemodule"),
        ("SWIFT_OPTIMIZATION_LEVEL", "-O"),
        ("VALIDATE_PRODUCT", "YES"),
    ]

    target_debug_settings = [
        ("ASSETCATALOG_COMPILER_APPICON_NAME", "AppIcon"),
        ("CODE_SIGN_STYLE", "Automatic"),
        ("CURRENT_PROJECT_VERSION", "1"),
        ("ENABLE_PREVIEWS", "YES"),
        ("GENERATE_INFOPLIST_FILE", "NO"),
        ("INFOPLIST_FILE", INNER + "/Info.plist"),
        ("IPHONEOS_DEPLOYMENT_TARGET", "16.0"),
        ("LD_RUNPATH_SEARCH_PATHS", "(\n\t\t\t\t\"@executable_path/Frameworks\",\n\t\t\t);"),
        ("MARKETING_VERSION", "1.0.0"),
        ("PRODUCT_BUNDLE_IDENTIFIER", BUNDLE_ID),
        ("PRODUCT_NAME", '"$(TARGET_NAME)"'),
        ("SWIFT_EMIT_LOC_STRINGS", "YES"),
        ("SWIFT_VERSION", "5.0"),
        ("TARGETED_DEVICE_FAMILY", '"1,2"'),
    ]

    target_release_settings = list(target_debug_settings) + [
        ("COPY_PHASE_STRIP", "NO"),
        ("SWIFT_COMPILATION_MODE", "wholemodule"),
        ("SWIFT_OPTIMIZATION_LEVEL", "-O"),
    ]

    def emit_settings(name, settings):
        out = []
        out.append(T + name + " /* " + ("Debug" if "Debug" in name else "Release") + " */ = {")
        out.append(T + T + "isa = XCBuildConfiguration;")
        out.append(T + T + "buildSettings = {")
        for k, v in settings:
            if v.startswith("("):
                out.append(T + T + T + k + " = " + v + ";")
            else:
                out.append(T + T + T + k + " = " + v + ";")
        out.append(T + T + "};")
        out.append(T + T + "name = " + ("Debug" if "Debug" in name else "Release") + ";")
        out.append(T + "};")
        return out

    lines.append("/* Begin XCBuildConfiguration section */")
    for ln in emit_settings(PROJ_DEBUG, proj_debug_settings):
        lines.append(T + ln)
    for ln in emit_settings(PROJ_RELEASE, proj_release_settings):
        lines.append(T + ln)
    for ln in emit_settings(TARGET_DEBUG, target_debug_settings):
        lines.append(T + ln)
    for ln in emit_settings(TARGET_RELEASE, target_release_settings):
        lines.append(T + ln)
    lines.append("/* End XCBuildConfiguration section */")
    lines.append("")

    # ---- XCConfigurationList ----
    lines.append("/* Begin XCConfigurationList section */")
    lines.append(T + PROJ_CLS + " /* Build configuration list for PBXProject \"" + PRODUCT_NAME + "\" */ = {")
    lines.append(T + T + "isa = XCConfigurationList;")
    lines.append(T + T + "buildConfigurations = (")
    lines.append(T + T + T + PROJ_DEBUG + " /* Debug */,")
    lines.append(T + T + T + PROJ_RELEASE + " /* Release */,")
    lines.append(T + T + ");")
    lines.append(T + T + "defaultConfigurationIsVisible = 0;")
    lines.append(T + T + "defaultConfigurationName = Release;")
    lines.append(T + "};")
    lines.append(T + TARGET_CLS + " /* Build configuration list for PBXNativeTarget \"" + PRODUCT_NAME + "\" */ = {")
    lines.append(T + T + "isa = XCConfigurationList;")
    lines.append(T + T + "buildConfigurations = (")
    lines.append(T + T + T + TARGET_DEBUG + " /* Debug */,")
    lines.append(T + T + T + TARGET_RELEASE + " /* Release */,")
    lines.append(T + T + ");")
    lines.append(T + T + "defaultConfigurationIsVisible = 0;")
    lines.append(T + T + "defaultConfigurationName = Release;")
    lines.append(T + "};")
    lines.append("/* End XCConfigurationList section */")
    lines.append("")

    lines.append(T + "};")
    lines.append(T + "rootObject = " + PROJECT + " /* Project object */;")
    lines.append("}")
    return "\n".join(lines) + "\n"


def write_workspace(xcodeproj_dir):
    ws_dir = os.path.join(xcodeproj_dir, "project.xcworkspace")
    os.makedirs(ws_dir, exist_ok=True)
    contents = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Workspace\n'
        '\tversion = "1.0">\n'
        '\t<FileRef\n'
        '\t\tlocation = "self:GRRoll.xcodeproj">\n'
        '\t</FileRef>\n'
        '</Workspace>\n'
    )
    with open(os.path.join(ws_dir, "contents.xcworkspacedata"), "w", encoding="utf-8") as f:
        f.write(contents)


def main():
    xcodeproj_dir = os.path.join(PROJECT_ROOT, "GRRoll.xcodeproj")
    os.makedirs(xcodeproj_dir, exist_ok=True)
    pbx = build_pbxproj()
    with open(os.path.join(xcodeproj_dir, "project.pbxproj"), "w", encoding="utf-8") as f:
        f.write(pbx)
    write_workspace(xcodeproj_dir)
    print("Wrote", os.path.join(xcodeproj_dir, "project.pbxproj"))
    print("Swift files:", len(SWIFT_FILES), "Resources:", len(RESOURCE_FILES))


if __name__ == "__main__":
    main()
