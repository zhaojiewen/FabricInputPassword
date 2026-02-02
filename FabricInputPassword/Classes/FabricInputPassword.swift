import UIKit

/// FabricInputPassword 主类
@objc
public class FabricInputPassword: NSObject {
    
    
    /// 校验密码：在新窗口中显示密码输入页面
    /// - Parameters:
    ///   - windowLevel: 新Window的等级
    ///   - merId: 商户编号
    ///   - merSysId: 会员体系ID
    ///   - merUserId: 会员用户ID
    ///   - merOrderId: 支付订单号
    ///   - tranAmt: 订单金额（单位：分）
    ///   - forgotPasswordHandler: 忘记密码处理闭包， 需要跳转WebView
    ///   - success: 密码验证成功回调，返回Token
    @objc public static func verify(windowLevel: UIWindow.Level = UIWindowLevelStatusBar + 1,
                                    environment: Environment = .release,
                                    merId: String,
                                    merSysId: String,
                                    merUserId: String,
                                    merOrderId: String,
                                    tranAmt: String,
                                    forgotPasswordHandler: ForgotPasswordHandler? = nil,
                                    success: @escaping (String) -> Void){
        
        
        // 创建验证器配置
        guard let configuration = PaymentPasswordValidator.Configuration(
            environment: environment,
            merId: merId,
            merSysId: merSysId,
            merUserId: merUserId,
            merOrderId: merOrderId,
            tranAmt: tranAmt
        ) else {
            return
        }
        
        
        // 创建异步验证器闭包
        let asyncValidator = PaymentPasswordValidator.createAsyncValidator(configuration, success: success)

        // 显示密码输入界面
        showInNewWindow(windowLevel: windowLevel,
                       forgotPasswordHandler: forgotPasswordHandler,
                       asyncValidator: asyncValidator)
    }
        
    /// 显示密码输入页面
    /// - Parameters:
    ///   - windowLevel: 新Window的等级
    ///   - passwordLength: 密码长度，默认为6
    ///   - title: 标题
    ///   - subtitle: 副标题
    ///   - asyncValidator: 异步验证闭包
    @objc public static func showInNewWindow(windowLevel: UIWindow.Level = UIWindowLevelStatusBar + 1,
                                             passwordLength: Int = 6,
                                             title: String? = "请输入密码",
                                             subtitle: String? = nil,
                                             forgotPasswordHandler: ForgotPasswordHandler? = nil,
                                             asyncValidator: @escaping AsyncPasswordValidator,) {
        let passwordVC = PasswordInputViewController(
            passwordLength: passwordLength,
            title: title,
            subtitle: subtitle,
        )
        
        passwordVC.asyncValidator = asyncValidator
        passwordVC.forgotPasswordHandler = forgotPasswordHandler
        passwordVC.showInNewWindow(windowLevel: windowLevel, completion: nil)
    }
    
}
