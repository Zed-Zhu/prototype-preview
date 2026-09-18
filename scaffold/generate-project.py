#!/usr/bin/env python3
"""
Generate ProtoViewer.xcodeproj — no Xcode GUI needed.
Creates a minimal iOS SwiftUI app project that loads HTML from local server.
"""
import os
import sys
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent / "ios-app"
XCODEPROJ = PROJECT_DIR / "ProtoViewer.xcodeproj"

# ── UUIDs ──────────────────────────────────────────────
# Deterministic IDs so the file is diff-friendly
def uid(suffix: str) -> str:
    """Generate a 24-char hex ID from a label."""
    return f"E0000000000000000000{suffix:04X}"


# Shorter aliases
OBJ = uid

# Every object we need:
P_ROOT      = OBJ(1)   # PBXProject
G_MAIN       = OBJ(2)   # Main group
G_PRODUCTS   = OBJ(3)   # Products group
G_SOURCES    = OBJ(4)   # ios-app source group
BP_SOURCES   = OBJ(5)   # Sources build phase
BP_FRAMEWORKS = OBJ(6)  # Frameworks build phase
BP_RESOURCES = OBJ(7)   # Resources build phase
T_TARGET     = OBJ(8)   # Native target
BC_PROJ_DBG  = OBJ(9)   # Project Debug config
BC_PROJ_REL  = OBJ(10)  # Project Release config
BC_TARG_DBG  = OBJ(11)  # Target Debug config
BC_TARG_REL  = OBJ(12)  # Target Release config
CL_PROJ      = OBJ(13)  # Project config list
CL_TARG      = OBJ(14)  # Target config list
FR_APP_SWIFT = OBJ(15)  # ProtoViewerApp.swift ref
FR_VIEW_SWIFT = OBJ(16) # ContentView.swift ref
FR_PLIST     = OBJ(17)  # Info.plist ref
FR_PRODUCT   = OBJ(18)  # ProtoViewer.app product ref
BF_APP_SWIFT = OBJ(19)  # ProtoViewerApp.swift build file
BF_VIEW_SWIFT = OBJ(20) # ContentView.swift build file

# ── Template ───────────────────────────────────────────
TEMPLATE = r"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* ── PBXBuildFile ───────────────────────────────────── */

		{bf_app} /* ProtoViewerApp.swift in Sources */ = {{
			isa = PBXBuildFile;
			fileRef = {fr_app};
		}};
		{bf_view} /* ContentView.swift in Sources */ = {{
			isa = PBXBuildFile;
			fileRef = {fr_view};
		}};

/* ── PBXFileReference ───────────────────────────────── */

		{fr_app} /* ProtoViewerApp.swift */ = {{
			isa = PBXFileReference;
			lastKnownFileType = sourcecode.swift;
			path = ProtoViewerApp.swift;
			sourceTree = "<group>";
		}};
		{fr_view} /* ContentView.swift */ = {{
			isa = PBXFileReference;
			lastKnownFileType = sourcecode.swift;
			path = ContentView.swift;
			sourceTree = "<group>";
		}};
		{fr_plist} /* Info.plist */ = {{
			isa = PBXFileReference;
			lastKnownFileType = text.plist.xml;
			path = Info.plist;
			sourceTree = "<group>";
		}};
		{fr_product} /* ProtoViewer.app */ = {{
			isa = PBXFileReference;
			explicitFileType = wrapper.application;
			includeInIndex = 0;
			path = ProtoViewer.app;
			sourceTree = BUILT_PRODUCTS_DIR;
		}};

/* ── PBXFrameworksBuildPhase ────────────────────────── */

		{bp_fw} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};

/* ── PBXGroup ───────────────────────────────────────── */

		{g_main} = {{
			isa = PBXGroup;
			children = (
				{g_src},
				{g_products},
			);
			sourceTree = "<group>";
		}};
		{g_src} /* ios-app */ = {{
			isa = PBXGroup;
			children = (
				{fr_app},
				{fr_view},
				{fr_plist},
			);
			path = ".";
			sourceTree = "<group>";
		}};
		{g_products} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{fr_product},
			);
			name = Products;
			sourceTree = "<group>";
		}};

/* ── PBXNativeTarget ────────────────────────────────── */

		{t_target} /* ProtoViewer */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {cl_targ};
			buildPhases = (
				{bp_src},
				{bp_fw},
				{bp_res},
			);
			buildRules = (
			);
			dependencies = (
			);
			name = ProtoViewer;
			productName = ProtoViewer;
			productReference = {fr_product};
			productType = "com.apple.product-type.application";
		}};

/* ── PBXProject ─────────────────────────────────────── */

		{p_root} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{t_target} = {{
						CreatedOnToolsVersion = 16.0;
					}};
				}};
			}};
			buildConfigurationList = {cl_proj};
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
				"zh-Hans",
			);
			mainGroup = {g_main};
			productRefGroup = {g_products};
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{t_target},
			);
		}};

/* ── PBXResourcesBuildPhase ─────────────────────────── */

		{bp_res} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};

/* ── PBXSourcesBuildPhase ───────────────────────────── */

		{bp_src} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{bf_app},
				{bf_view},
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};

/* ── XCBuildConfiguration ───────────────────────────── */

		{bc_proj_dbg} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{bc_proj_rel} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				GCC_OPTIMIZATION_LEVEL = s;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{bc_targ_dbg} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_IDENTITY = "";
				CODE_SIGNING_ALLOWED = NO;
				CODE_SIGNING_REQUIRED = NO;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				INFOPLIST_FILE = Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.prototypes.ProtoViewer;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Debug;
		}};
		{bc_targ_rel} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_IDENTITY = "";
				CODE_SIGNING_ALLOWED = NO;
				CODE_SIGNING_REQUIRED = NO;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				INFOPLIST_FILE = Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.prototypes.ProtoViewer;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Release;
		}};

/* ── XCConfigurationList ────────────────────────────── */

		{cl_proj} /* project config list */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{bc_proj_dbg},
				{bc_proj_rel},
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{cl_targ} /* target config list */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{bc_targ_dbg},
				{bc_targ_rel},
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};

/* ── End of objects ─────────────────────────────────── */

	}};
	rootObject = {p_root} /* Project object */;
}}
"""


def generate():
    PROJECT_DIR.mkdir(parents=True, exist_ok=True)

    content = TEMPLATE.format(
        p_root=P_ROOT, g_main=G_MAIN, g_products=G_PRODUCTS, g_src=G_SOURCES,
        bp_src=BP_SOURCES, bp_fw=BP_FRAMEWORKS, bp_res=BP_RESOURCES,
        t_target=T_TARGET,
        bc_proj_dbg=BC_PROJ_DBG, bc_proj_rel=BC_PROJ_REL,
        bc_targ_dbg=BC_TARG_DBG, bc_targ_rel=BC_TARG_REL,
        cl_proj=CL_PROJ, cl_targ=CL_TARG,
        fr_app=FR_APP_SWIFT, fr_view=FR_VIEW_SWIFT,
        fr_plist=FR_PLIST, fr_product=FR_PRODUCT,
        bf_app=BF_APP_SWIFT, bf_view=BF_VIEW_SWIFT,
    )

    pbxproj_dir = XCODEPROJ
    pbxproj_dir.mkdir(parents=True, exist_ok=True)
    pbxproj_path = pbxproj_dir / "project.pbxproj"
    pbxproj_path.write_text(content)

    # ── Create xcscheme ────────────────────────────────
    xcscheme_dir = pbxproj_dir / "xcshareddata" / "xcschemes"
    xcscheme_dir.mkdir(parents=True, exist_ok=True)

    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{T_TARGET}"
               BuildableName = "ProtoViewer.app"
               BlueprintName = "ProtoViewer"
               ReferencedContainer = "container:ProtoViewer.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{T_TARGET}"
            BuildableName = "ProtoViewer.app"
            BlueprintName = "ProtoViewer"
            ReferencedContainer = "container:ProtoViewer.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{T_TARGET}"
            BuildableName = "ProtoViewer.app"
            BlueprintName = "ProtoViewer"
            ReferencedContainer = "container:ProtoViewer.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    (xcscheme_dir / "ProtoViewer.xcscheme").write_text(scheme)

    print(f"✅ Xcode project generated at: {XCODEPROJ}")
    print(f"   Scheme: ProtoViewer")
    print(f"   Target: ProtoViewer")
    print(f"   Bundle: com.prototypes.ProtoViewer")


if __name__ == "__main__":
    generate()
