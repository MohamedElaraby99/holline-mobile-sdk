require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "holline-react-native"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = "https://holline.cloud"
  s.license      = { :type => "MIT", :text => "See the LICENSE file in the SDK repository." }
  s.authors      = "Holline"
  s.platforms    = { :ios => "15.0" }
  s.source       = { :path => "." }
  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.swift_version = "5.9"

  install_modules_dependencies(s)
end
