Pod::Spec.new do |spec|
  spec.name         = "PersistedPropertyWrapper"
  spec.version      = "2.1.0"
  spec.summary      = "A Swift Property Wrapper to enable easy persistence in UserDefaults"
  spec.description  = <<-DESC
	Persisted Property Wrapper is a Swift library to enable extremely easy persistance of variables in the UserDefaults database on iOS.

	To use Persisted Property Wrapper you simply annotate a variable as being @Persisted. It supports the standard UserDefaults types, along with RawRepresentable types - where the RawValue is storable in UserDefaults - and Codable types. Plus of course any Optional type wrapping any of these types. The type-validity is checked at compile-time: attempting to use on any variables of a non-supported type will cause a compile-time error.
                   DESC

  spec.homepage     = "https://github.com/AndrewBennet/PersistedPropertyWrapper"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "Andrew Bennet" => "me@andrewbennet.com" }
  spec.osx.deployment_target = "10.13"
  spec.ios.deployment_target = "10.0"
  spec.watchos.deployment_target = "2.0"
  spec.tvos.deployment_target = "10.0"
  spec.source       = { :git => "https://github.com/AndrewBennet/PersistedPropertyWrapper.git", :tag => "v#{spec.version}" }
  spec.source_files  = "Sources/PersistedPropertyWrapper/*.swift"
  spec.swift_versions = "5.3"
end
