//
//  FabricBundle.swift
//  Pods
//
//  Created by 徐海青 on 2026/2/4.
//

import Foundation

class FabricBundle {
    /// 获取 framework resource Bundle
        /// - Parameters:
        ///   - class: framework 中的一个类
        ///   - forResource: resource名称
        /// - Returns: 返回Bundle
    public static func bundle(for class: AnyClass = FabricInputPassword.self, forResource: String = "FabricInputPassword") -> Bundle {
            let frameworkBundle = Bundle(for: `class`)
            if let path = frameworkBundle.path(forResource: forResource, ofType: "bundle"),let bundle = Bundle(path: path) {
                return bundle
            }else if let bundle = Bundle(identifier: "org.cocoapods.\(forResource)") {
                return bundle
            }
            
            return Bundle.main
    }
    
    
    public static func loadImage(named: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage(named: named, in: FabricBundle.bundle(), with: nil)
        } else {
            return UIImage(named: named, in: FabricBundle.bundle(), compatibleWith: nil)
        }
    }

}
