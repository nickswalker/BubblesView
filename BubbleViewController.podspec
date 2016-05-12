Pod::Spec.new do |s|
  s.name             = "BubbleViewController"
  s.version          = "0.1.0"
  s.summary          = "Navigate data represented as a graph"

  s.description      = <<-DESC
    Navigate data represented as a graph.
                       DESC

  s.homepage         = "https://github.com/nickswalker/BubbleViewController"
  s.license          = 'MIT'
  s.author           = { "Nicholas Walker" => "nick@nickwalker.us" }
  s.source           = { :git => "https://github.com/nickswalker/BubbleViewController.git", :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'BubbleViewController/Classes/**/*'

end
