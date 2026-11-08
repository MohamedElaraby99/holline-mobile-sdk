Pod::Spec.new do |s|
  s.name             = 'holline_sdk'
  s.version          = '0.2.0'
  s.summary          = "Open a company's Holline call screen inside a Flutter app."
  s.homepage         = 'https://holline.cloud'
  s.license          = { :type => 'MIT', :file => '../../LICENSE' }
  s.author           = 'Holline'
  s.source           = { :path => '.' }
  s.source_files     = 'holline_sdk/Sources/holline_sdk/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.9'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
