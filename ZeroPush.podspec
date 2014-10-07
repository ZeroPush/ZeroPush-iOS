Pod::Spec.new do |s|
  s.name         = "ZeroPush"
  s.version      = "2.0.2"
  s.summary      = "ZeroPush is a lightweight wrapper for the ZeroPush API."
  s.homepage     = "https://zeropush.com"
  s.license      = 'MIT'
  s.authors      = { "Adam Duke" => "adam.v.duke@gmail.com", "Stefan Natchev" => "stefan.natchev@gmail.com" }
  s.source       = { :git => "https://github.com/ZeroPush/ZeroPush-iOS.git", :tag => "2.0.2" }
  s.platform     = :ios
  s.source_files = 'ZeroPush-iOS/*.{h,m}'
  s.frameworks   = 'Foundation', 'UIKit'
  s.requires_arc = true
end

