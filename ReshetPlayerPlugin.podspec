Pod::Spec.new do |s|

  s.name             = 'ReshetPlayerPlugin'
  s.version          = '0.0.2'
  s.summary          = 'ReshetPlayerPlugin'
  s.description      = 'Plugin Player for Reshet including DVR support and arti media adds'
  s.homepage         = 'https://github.com/applicaster-plugins/ReshetPlayerPlugin-iOS'
  s.authors          = { 'Roi Kedarya' => 'r.kedarya@applicaster.com' }
  s.license          = 'MIT'
  s.source           = { :git => 'git@github.com:applicaster-plugins/ReshetPlayerPlugin-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target  = '10.0'
  s.platform               = :ios, '10.0'
  s.requires_arc           = true
  s.static_framework       = true
  s.swift_version          = '5.0'

  s.frameworks = 'UIKit'
  s.public_header_files = 'ReshetPlayerPlugin/Classes/**/*.h'
  s.source_files = ['ReshetPlayerPlugin/Classes/**/*.{h,m,swift}']
  s.resources = ['ReshetPlayerPlugin/Resources/**/*.{xib}']
  s.dependency 'ArtiSDK', '1.4.000'
  s.dependency 'ZappPlugins'
  s.dependency 'ApplicasterSDK'

  s.subspec 'Kantar' do |k|
    # k.vendored_libraries  = 'ReshetPlayerPlugin/Kantar/kantarmedia-streaming-fat.a'
    k.public_header_files = "ReshetPlayerPlugin/Kantar/*.h"
    k.source_files = 'ReshetPlayerPlugin/Kantar/*.{swift,h,m}'
    # k.xcconfig = {
    #                 'OTHER_LDFLAGS' => '$(inherited) -l"kantarmedia-streaming-fat"'
    #              }
  end

  # s.subspec 'Core' do |c|
    # c.frameworks = 'UIKit'
    # c.public_header_files = 'ReshetPlayerPlugin/Classes/**/*.h'
    # c.source_files = ['ReshetPlayerPlugin/Classes/**/*.{h,m,swift}']
    # c.resources = ['ReshetPlayerPlugin/Resources/**/*.{xib}']
    # c.dependency 'ArtiSDK', '1.1.015'
    # c.dependency 'ZappPlugins'
    # c.dependency 'ApplicasterSDK'
  # end

  s.xcconfig =  {
                  'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'ENABLE_BITCODE' => 'YES',
                  'SWIFT_VERSION' => '5.0'
                }

  # s.default_subspec = 'Core', 'Kantar'
  s.default_subspec = 'Kantar'

end
