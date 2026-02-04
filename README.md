# FabricInputPassword

[![CI Status](https://img.shields.io/travis/haiqing.xu/FabricInputPassword.svg?style=flat)](https://travis-ci.org/haiqing.xu/FabricInputPassword)
[![Version](https://img.shields.io/cocoapods/v/FabricInputPassword.svg?style=flat)](https://cocoapods.org/pods/FabricInputPassword)
[![License](https://img.shields.io/cocoapods/l/FabricInputPassword.svg?style=flat)](https://cocoapods.org/pods/FabricInputPassword)
[![Platform](https://img.shields.io/cocoapods/p/FabricInputPassword.svg?style=flat)](https://cocoapods.org/pods/FabricInputPassword)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

FabricInputPassword is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FabricInputPassword'
```

## 使用

```
        FabricInputPassword.verify(merId: "11000001234",
                                   merSysId: "sys001",
                                   merUserId: "user001",
                                   merOrderId: "T2026012913141234",
                                   tranAmt: "8.88") { token in
            // 此时密码已经验证成功，可以用token走后续支付流程
        }
        
```

        

## Author

haiqing.xu, haiqing.xu@ly.com

## License

FabricInputPassword is available under the MIT license. See the LICENSE file for more info.
