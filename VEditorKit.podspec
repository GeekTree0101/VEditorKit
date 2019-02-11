Pod::Spec.new do |s|
    
  s.name             = 'VEditorKit'
  s.version          = '1.3.8'
  s.summary          = 'Lightweight and Powerful Editor Kit'
  
  s.description      = 'Lightweight and Powerful Editor Kit built on Texture(AsyncDisplayKit)'
  s.homepage         = 'https://github.com/Geektree0101/VEditorKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Geektree0101' => 'h2s1880@gmail.com' }
  s.source           = { :git => 'https://github.com/Geektree0101/VEditorKit.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '9.0'
  s.requires_arc = true

  s.source_files = 'VEditorKit/**/*'
  s.dependency 'Texture', '~> 2.7'
  s.dependency 'BonMot'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
end
