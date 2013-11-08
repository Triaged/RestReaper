Pod::Spec.new do |s|
  s.name         = "RestReaper"
  s.version      = "0.0.1"
  s.summary      = "Asynchronous RESTFul interaction made fast and easy for iOS and Mac OSX"
  s.homepage     = "https://github.com/daltoniam/RestReaper"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Dalton Cherry" => "daltoniam@gmail.com" }
  s.source       = { :git => "https://github.com/daltoniam/RestReaper.git", :tag => '0.0.1' }
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.8'
  s.source_files = '*.{h,m}'
  s.dependency 'DCModel', '~> 0.0.3'  
  s.dependency'AFNetworking', '~> 2.0'
  s.dependency'JSONJoy', '~> 0.0.2'
  s.requires_arc = true
end