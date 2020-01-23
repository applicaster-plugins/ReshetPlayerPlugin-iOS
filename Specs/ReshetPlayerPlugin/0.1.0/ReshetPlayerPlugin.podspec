Pod::Spec.new do |s|

  s.name             = 'ReshetPlayerPlugin'
  s.version          = '0.1.0'
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
  s.swift_version          = '5.1'

  c.frameworks = 'UIKit'
  c.public_header_files = 'ReshetPlayerPlugin/Classes/**/*.h'
  c.source_files = ['ReshetPlayerPlugin/Classes/**/*.{h,m,swift}']
  c.resources = ['ReshetPlayerPlugin/Resources/**/*.{xib}']
  c.dependency 'ArtiSDK', '1.4.000'
  c.dependency 'ZappPlugins'
  c.dependency 'ApplicasterSDK'
  # c.dependency 'KantarKitAdapter'

  # s.subspec 'Kantar' do |k|
  #   k.vendored_libraries  = 'ReshetPlayerPlugin/Kantar/kantarmedia-streaming-fat.a'
  #   k.public_header_files = "ReshetPlayerPlugin/Kantar/*.h"
  #   k.source_files = 'ReshetPlayerPlugin/Kantar/*.{swift,h,m}'
  #   # k.xcconfig = {
  #   #                 'OTHER_LDFLAGS' => '$(inherited) -l"kantarmedia-streaming-fat"'
  #   #              }
  # end

  # s.subspec 'Core' do |c|
  #   c.frameworks = 'UIKit'
  #   c.public_header_files = 'ReshetPlayerPlugin/Classes/**/*.h'
  #   c.source_files = ['ReshetPlayerPlugin/Classes/**/*.{h,m,swift}']
  #   c.resources = ['ReshetPlayerPlugin/Resources/**/*.{xib}']
  #   c.dependency 'ArtiSDK', '1.4.000'
  #   c.dependency 'ZappPlugins'
  #   c.dependency 'ApplicasterSDK'
  #   c.dependency 'KantarKitAdapter'
  # end

  s.xcconfig =  {
                  'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'ENABLE_BITCODE' => 'YES',
                  'SWIFT_VERSION' => '5.1'
                }

  # s.default_subspec = 'Core', 'Kantar'

end
