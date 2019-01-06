<img src="https://github.com/GeekTree0101/VEditorKit/blob/master/screenshots/logo.png" />

[![CI Status](https://img.shields.io/travis/Geektree0101/VEditorKit.svg?style=flat)](https://travis-ci.org/Geektree0101/VEditorKit)
[![Version](https://img.shields.io/cocoapods/v/VEditorKit.svg?style=flat)](https://cocoapods.org/pods/VEditorKit)
[![License](https://img.shields.io/cocoapods/l/VEditorKit.svg?style=flat)](https://cocoapods.org/pods/VEditorKit)
[![Platform](https://img.shields.io/cocoapods/p/VEditorKit.svg?style=flat)](https://cocoapods.org/pods/VEditorKit)

Lightweight and Powerful Editor Kit built on Texture(AsyncDisplayKit)
https://github.com/texturegroup/texture. 
</br>
VEditorKit provides the most core functionality needed for the editor.
Unfortunately, When combined words are entered then UITextView selectedRange will changed and typingAttribute will cleared. So, In combined words case, Users can't continue typing the style they want.
</br>
#### TypingAttributes Spec
When the text view’s selection changes, the contents of the dictionary are cleared automatically. 
https://developer.apple.com/documentation/uikit/uitextview/1618629-typingattributes 

#### Basic spec list
- Advanced EditableTextView (Support Combined words such as Korean)
- Default Image, Video, Og-Object(Link Preview) UI Components
- XML Parser & Builder
- Editor Rule Base Development

## Example<table>
  <tr>
    <td align="center">XML Parse & Build</td>
    <td align="center">Delete Media Content & Merge TextViews</td>
    <td align="center">Bi-direction attribute binding</td>
    <td align="center">Combined Words TypingAttribute</td>
  </tr>
  <tr>
    <th rowspan="9"><img src="https://github.com/GeekTree0101/VEditorKit/blob/master/screenshots/test4.gif"></th>
    <th rowspan="9"><img src="https://github.com/GeekTree0101/VEditorKit/blob/master/screenshots/test3.gif"></th>
    <th rowspan="9"><img src="https://github.com/GeekTree0101/VEditorKit/blob/master/screenshots/english.gif"></th>
    <th rowspan="9"><img src="https://github.com/GeekTree0101/VEditorKit/blob/master/screenshots/korean.gif"></th>
  </tr>
  <tr>
</table>

## Usage
- Quick Start
- What is Editor Rule?
- How to use VEditorNode?
- How to use VEditorTextNode?
- Under construction :)

## Requirements
- Xcode <~ 9.0
- Swift 4.2
- iOS <~ 9.3

## Installation

VEditorKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'VEditorKit'
```

## Author

Geektree0101, h2s1880@gmail.com

## License

VEditorKit is available under the MIT license. See the LICENSE file for more info.
