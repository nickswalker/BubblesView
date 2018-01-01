Pod::Spec.new do |s|
  s.name             = "BubblesView"
  s.version          = "0.2.0"
  s.summary          = "Use bubbles to navigate graph data"

  s.description      = <<-DESC
    Navigate data represented as a graph.
                       DESC

  s.homepage         = "https://github.com/nickswalker/BubblesView"
  s.license          = 'MIT'
  s.author           = { "Nicholas Walker" => "nick@nickwalker.us" }
  s.source           = { :git => "https://github.com/nickswalker/BubblesView.git", :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.swift_version = '4.1'
  s.source_files = 'Sources/Classes/**/*'

end
