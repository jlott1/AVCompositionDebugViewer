#
# Be sure to run `pod lib lint AVCompositionDebugViewer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AVCompositionDebugViewer'
  s.version          = '0.1.0'
  s.summary          = 'AVComposition debugging viewer, borrowed from Apple sample project and converted to cocoapod'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'AVFoundation and AVComposition debugging viewer. Borrowed from Apple sample project and converted to cocoapod.  Allows you to create a custom AVMutableComposition and visualize it in the debugger view'

  s.homepage         = 'https://github.com/jlott1/AVCompositionDebugViewer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors           = 'Jonathan Lott and Apple Inc.'
  s.source           = { :git => 'https://github.com/jlott1/AVCompositionDebugViewer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'AVCompositionDebugViewer/Classes/**/*'
  
  s.ios.resources = ['AVCompositionDebugViewer/Assets/iOS/*.xib']
  s.osx.resources = ['AVCompositionDebugViewer/Assets/Mac/*.xib']

  #s.ios.resource_bundles = {
  #  'AVCompositionDebugViewer' => ['AVCompositionDebugViewer/Assets/iOS/*.xib']
  #}
  #s.osx.resource_bundles = {
  #    'AVCompositionDebugViewer' => ['AVCompositionDebugViewer/Assets/Mac/*.xib']
  #}

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
