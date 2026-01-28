import UIKit

/// FabricInputPassword 主类
@objc
public class FabricInputPassword: NSObject {
    
    
    /// 显示密码输入页面（带异步验证）
    /// - Parameters:
    ///   - viewController: 要present的视图控制器
    ///   - passwordLength: 密码长度，默认为6
    ///   - title: 标题
    ///   - subtitle: 副标题
    ///   - asyncValidator: 异步验证闭包
    ///   - completion: 完成回调，返回输入的密码和验证结果
    @objc public static func showPasswordInput(from viewController: UIViewController,
                                              passwordLength: Int = 6,
                                              title: String? = "请输入密码",
                                              subtitle: String? = nil,
                                              asyncValidator: @escaping (String, @escaping (Bool) -> Void) -> Void,
                                              completion: @escaping (String, Bool) -> Void) {
        let passwordVC = PasswordInputViewController(
            passwordLength: passwordLength,
            title: title,
            subtitle: subtitle,
            completion: completion
        )
        
        // 设置异步验证器
        passwordVC.asyncValidator = asyncValidator
        viewController.present(passwordVC, animated: true, completion: nil)
    }
    
}
