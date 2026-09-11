from pathlib import Path
import hashlib
import re

root = Path(__file__).resolve().parents[1]
objects = {}
existing_project = root / 'WhatWasThat.xcodeproj/project.pbxproj'
existing_text = existing_project.read_text() if existing_project.exists() else ''
team_match = re.search(r'DEVELOPMENT_TEAM = ([A-Z0-9]+);', existing_text)
team = team_match.group(1) if team_match else '9R9YA6B34L'
app_group = 'group.com.platret.whatwasthat.shared'



def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()


def obj(name, value):
    objects[uid(name)] = value
    return uid(name)


def array(values):
    return '(' + ', '.join(values) + ')'


def settings(values):
    return '{' + ' '.join(f'{k} = {v};' for k, v in values.items()) + '}'


targets = []
products = []
groups = []
for target in ['WhatWasThat', 'WhatWasThatWidgets', 'WhatWasThatTests', 'WhatWasThatUITests']:
    files = sorted((root / target).rglob('*.swift'))
    if target in ['WhatWasThat', 'WhatWasThatWidgets']:
        files += sorted((root / 'Shared').rglob('*.swift'))
    if target == 'WhatWasThat':
        files += [root / target / 'Resources/Assets.xcassets']
    if target in ['WhatWasThat', 'WhatWasThatWidgets']:
        files += [root / target / 'PrivacyInfo.xcprivacy']
    refs, sources, resources = [], [], []
    for path in files:
        relative = str(path.relative_to(root))
        kind = 'sourcecode.swift' if path.suffix == '.swift' else 'folder.assetcatalog' if path.suffix == '.xcassets' else 'text.xml' if path.suffix == '.xcprivacy' else 'text.json'
        ref = obj(target + ':' + relative, f'{{isa = PBXFileReference; lastKnownFileType = {kind}; path = "{relative}"; sourceTree = SOURCE_ROOT;}}')
        refs.append(ref)
        build = obj('build:' + target + ':' + relative, f'{{isa = PBXBuildFile; fileRef = {ref};}}')
        (sources if path.suffix == '.swift' else resources).append(build)
    groups.append(obj('group:' + target, f'{{isa = PBXGroup; children = {array(refs)}; name = {target}; sourceTree = "<group>";}}'))
    source_phase = obj('sources:' + target, f'{{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {array(sources)}; runOnlyForDeploymentPostprocessing = 0;}}')
    resource_phase = obj('resources:' + target, f'{{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {array(resources)}; runOnlyForDeploymentPostprocessing = 0;}}')
    framework_phase = obj('frameworks:' + target, '{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;}')
    is_app = target == 'WhatWasThat'
    is_extension = target in ['WhatWasThatWidgets']
    product = obj('product:' + target, f'{{isa = PBXFileReference; explicitFileType = {"wrapper.application" if is_app else "wrapper.app-extension" if is_extension else "wrapper.cfbundle"}; path = {target}{".app" if is_app else ".appex" if is_extension else ".xctest"}; sourceTree = BUILT_PRODUCTS_DIR;}}')
    products.append(product)
    configs = []
    for config in ['Debug', 'Release']:
        values = {
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.platret.whatwasthat' + ('' if is_app else '.' + target),
            'PRODUCT_NAME': '"$(TARGET_NAME)"', 'SWIFT_VERSION': '5.0',
            'IPHONEOS_DEPLOYMENT_TARGET': '26.0', 'TARGETED_DEVICE_FAMILY': '1',
            'SDKROOT': 'iphoneos', 'SUPPORTED_PLATFORMS': '"iphoneos iphonesimulator"',
            'GENERATE_INFOPLIST_FILE': 'YES', 'CODE_SIGN_STYLE': 'Automatic',
            'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'DEBUG' if config == 'Debug' else '""', 'SWIFT_EMIT_LOC_STRINGS': 'YES', 'SWIFT_STRICT_CONCURRENCY': 'complete',
            'SWIFT_OPTIMIZATION_LEVEL': '"-Onone"' if config == 'Debug' else '"-O"',
            'DEBUG_INFORMATION_FORMAT': 'dwarf' if config == 'Debug' else '"dwarf-with-dsym"',
        }
        if team:
            values['DEVELOPMENT_TEAM'] = team
        if is_app or is_extension:
            values.update({'MARKETING_VERSION': '1.0', 'CURRENT_PROJECT_VERSION': '2'})
        if target in ['WhatWasThat', 'WhatWasThatWidgets']:
            values.update({'WWT_APP_GROUP': app_group, 'CODE_SIGN_ENTITLEMENTS': target + '/' + target + '.entitlements'})
        if is_extension:
            values.update({'INFOPLIST_FILE': target + '/Info.plist', 'APPLICATION_EXTENSION_API_ONLY': 'YES', 'SKIP_INSTALL': 'YES'})
        if is_app:
            values.update({
                'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
                'INFOPLIST_FILE': 'WhatWasThat/Info.plist',
                'INFOPLIST_KEY_CFBundleDisplayName': '"What Was That?"',
                'INFOPLIST_KEY_LSApplicationCategoryType': '"public.app-category.lifestyle"',
                'INFOPLIST_KEY_UIApplicationSceneManifest_Generation': 'YES',
                'INFOPLIST_KEY_UILaunchScreen_Generation': 'YES',
                'INFOPLIST_KEY_UISupportedInterfaceOrientations': '"UIInterfaceOrientationPortrait"',
                'MARKETING_VERSION': '1.0', 'CURRENT_PROJECT_VERSION': '2',
                'ENABLE_PREVIEWS': 'YES',
            })
        elif target == 'WhatWasThatTests':
            values.update({'TEST_HOST': '"$(BUILT_PRODUCTS_DIR)/WhatWasThat.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/WhatWasThat"', 'BUNDLE_LOADER': '"$(TEST_HOST)"'})
        elif not is_extension:
            values['TEST_TARGET_NAME'] = 'WhatWasThat'
        configs.append(obj('config:' + target + config, f'{{isa = XCBuildConfiguration; buildSettings = {settings(values)}; name = {config};}}'))
    config_list = obj('configs:' + target, f'{{isa = XCConfigurationList; buildConfigurations = {array(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;}}')
    dependencies = []
    if not is_app and not is_extension:
        proxy = obj('proxy:' + target, f'{{isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("target:WhatWasThat")}; remoteInfo = WhatWasThat;}}')
        dependencies.append(obj('dependency:' + target, f'{{isa = PBXTargetDependency; target = {uid("target:WhatWasThat")}; targetProxy = {proxy};}}'))
    phases = [source_phase, framework_phase, resource_phase]
    if is_app:
        embed_builds = []
        for extension in ['WhatWasThatWidgets']:
            embed_builds.append(obj('embed:' + extension, f'{{isa = PBXBuildFile; fileRef = {uid("product:" + extension)}; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy);}};}}'))
            dependencies.append(obj('dependency:' + extension, f'{{isa = PBXTargetDependency; target = {uid("target:" + extension)};}}'))
        phases.append(obj('embed-extensions', f'{{isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = {array(embed_builds)}; name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;}}'))
    product_type = 'application' if is_app else 'app-extension' if is_extension else 'bundle.unit-test' if target == 'WhatWasThatTests' else 'bundle.ui-testing'
    targets.append(obj('target:' + target, f'{{isa = PBXNativeTarget; buildConfigurationList = {config_list}; buildPhases = {array(phases)}; buildRules = (); dependencies = {array(dependencies)}; name = {target}; productName = {target}; productReference = {product}; productType = "com.apple.product-type.{product_type}";}}'))

product_group = obj('products', f'{{isa = PBXGroup; children = {array(products)}; name = Products; sourceTree = "<group>";}}')
main_group = obj('main', f'{{isa = PBXGroup; children = {array(groups + [product_group])}; sourceTree = "<group>";}}')
project_configs = [obj('project:' + c, '{isa = XCBuildConfiguration; buildSettings = {CLANG_ENABLE_MODULES = YES; ENABLE_TESTABILITY = YES;}; name = ' + c + ';}') for c in ['Debug', 'Release']]
project_config_list = obj('project-configs', f'{{isa = XCConfigurationList; buildConfigurations = {array(project_configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;}}')
obj('project', f'{{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = YES; LastSwiftUpdateCheck = 2600; LastUpgradeCheck = 2600;}}; buildConfigurationList = {project_config_list}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (de, en, Base); mainGroup = {main_group}; productRefGroup = {product_group}; projectDirPath = ""; projectRoot = ""; targets = {array(targets)};}}')
project = root / 'WhatWasThat.xcodeproj'
project.mkdir(exist_ok=True)
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n' + '\n'.join(f'{key} = {value};' for key, value in objects.items()) + f'\n}}; rootObject = {uid("project")};}}\n')
schemes = project / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)


def reference(target, suffix):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target:" + target)}" BuildableName="{target}.{suffix}" BlueprintName="{target}" ReferencedContainer="container:WhatWasThat.xcodeproj"/>'


app = reference('WhatWasThat', 'app')
tests = ''.join(f'<TestableReference skipped="NO">{reference(t, "xctest")}</TestableReference>' for t in ['WhatWasThatTests', 'WhatWasThatUITests'])
(schemes / 'WhatWasThat.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>{tests}</Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Generated WhatWasThat.xcodeproj')
