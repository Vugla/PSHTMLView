#
# Be sure to run `pod lib lint PSHTMLView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PSHTMLView'
  s.version          = '0.1.2'
  s.summary          = 'WKWebView wrapper for using in UITableView and UIScrollView'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
PSHTMLView is a non scrollable WKWebView wrapper, adapt for using in UITableView and UIScrollView.
                       DESC

  s.homepage         = 'https://github.com/Vugla/PSHTMLView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Vugla' => 'predragsamardzic@msn.com' }
  s.source           = { :git => 'https://github.com/Vugla/PSHTMLView.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'PSHTMLView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'PSHTMLView' => ['PSHTMLView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end
