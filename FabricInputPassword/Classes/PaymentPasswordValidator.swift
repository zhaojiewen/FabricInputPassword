import Foundation

/// 异步密码验证回调
public typealias PasswordValidatorComplete = (String?, String?) -> Void

/// 支付密码验证响应码
struct ResultCode {
    /// 成功
    static let success = "0000"
}

/// 支付密码验证响应
public struct PaymentPasswordResponse: Codable {
    public let resultCode: String
    public let resultMsg: String
    public let pwdToken: String?
    public let signValue: String?
    
    private enum CodingKeys: String, CodingKey {
        case resultCode
        case resultMsg
        case pwdToken
        case signValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 处理可能的字符串或数字类型的resultCode
        if let stringValue = try? container.decode(String.self, forKey: .resultCode) {
            resultCode = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .resultCode) {
            resultCode = "\(intValue)"
        } else {
            resultCode = ""
        }
        
        resultMsg = try container.decode(String.self, forKey: .resultMsg)
        pwdToken = try container.decodeIfPresent(String.self, forKey: .pwdToken)
        signValue = try container.decodeIfPresent(String.self, forKey: .signValue)
    }
}

/// 业务参数
public struct BusinessParameters: Codable {
    public let tranCode: String          // 交易代码
    public let merId: String            // 商户编号
    public let merSysId: String         // 会员体系ID
    public let merUserId: String        // 会员用户ID
    public let merOrderId: String       // 支付订单号
    public let tranAmt: String          // 订单金额（单位：分）
    public let payPwd: String           // 支付密码
    
    public init(tranCode: String,
                merId: String,
                merSysId: String,
                merUserId: String,
                merOrderId: String,
                tranAmt: String,
                payPwd: String) {
        self.tranCode = tranCode
        self.merId = merId
        self.merSysId = merSysId
        self.merUserId = merUserId
        self.merOrderId = merOrderId
        self.tranAmt = tranAmt
        self.payPwd = payPwd
    }
    
    /// 转换为JSON字符串
    public func toJSONString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys // 确保键按字母顺序排序
        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw RSAError.invalidUTF8
        }
        return jsonString
    }
}

@objc
public enum Environment: Int {
    case release
    case dev
    
    var apiURL: URL? {
        switch self {
        case .release:
            return URL(string: "https://gateway.hnapay.com/wallet/sdk.do")
        case .dev:
            return URL(string: "https://gateway.hnapay.com/wallet/sdk.do")
        }
    }
    
    var publicKey: SecKey? {
        var publicKeyPEM = ""
        
        switch self {
        case .release:
            publicKeyPEM = ""
        case .dev:
            publicKeyPEM = ""
        }
        
        // 导入公钥
        return try? RSAKeyManager.importPublicKeyFromPEM(publicKeyPEM)
    }
    
    var tranCode: String {
        "SDK01"
    }
}


/// 支付密码验证器
public class PaymentPasswordValidator {
    
    /// 配置
    public struct Configuration {
        public let environment: Environment
        public let tranCode: String          // 交易代码
        public let merId: String            // 商户编号
        public let merSysId: String         // 会员体系ID
        public let merUserId: String        // 会员用户ID
        public let merOrderId: String       // 支付订单号
        public let tranAmt: String          // 订单金额（单位：分）
        
        let apiURL: URL
        let publicKey: SecKey
        
        public init?(environment: Environment,
                     merId: String,
                     merSysId: String,
                     merUserId: String,
                     merOrderId: String,
                     tranAmt: String) {
            guard let apiURL = environment.apiURL else {
                LogManager.shared.error("无效apiURL")
                return nil
            }
            self.apiURL = apiURL
            
            guard let publicKey = environment.publicKey else {
                LogManager.shared.error("无效公钥")
                return nil
            }
            self.publicKey = publicKey
    
            self.environment = environment
            self.tranCode = environment.tranCode
            self.merId = merId
            self.merSysId = merSysId
            self.merUserId = merUserId
            self.merOrderId = merOrderId
            self.tranAmt = tranAmt
        }
    }
    
    
    /// 验证支付密码
    /// - Parameters:
    ///   - password: 支付密码
    ///   - completion: 完成回调，返回验证结果
    public static func validate(_ configuration: Configuration, password: String, completion: @escaping PasswordValidatorComplete) {
                
        // 创建业务参数
        let businessParams = BusinessParameters(
            tranCode: configuration.tranCode,
            merId: configuration.merId,
            merSysId: configuration.merSysId,
            merUserId: configuration.merUserId,
            merOrderId: configuration.merOrderId,
            tranAmt: configuration.tranAmt,
            payPwd: password
        )
        
        do {
            // 1. 将业务参数转换为JSON字符串
            let jsonString = try businessParams.toJSONString()
            LogManager.shared.business("业务参数JSON: \(jsonString)")
            
            // 2. 使用RSA加密JSON字符串
            let encryptedBase64 = try RSACrypto.smartEncrypt(jsonString, publicKey: configuration.publicKey)
            LogManager.shared.crypto("RSA加密完成，Base64: \(encryptedBase64)")
            
            // 3. 准备请求参数
            let requestParameters = ["enc": encryptedBase64]
            
            // 4. 发送网络请求
            NetworkManager.shared.post(url: configuration.apiURL,
                                      parameters: requestParameters) { (result: Result<PaymentPasswordResponse, NetworkError>) in
                switch result {
                case .success(let response):
                    // 5. 验证响应
                    validateResponse(configuration, response: response, completion: completion)
                    
                case .failure(let error):
                    completion(nil, error.localizedDescription)
                }
            }
            
        } catch {
            completion(nil, error.localizedDescription)
        }
    }
    
    /// 验证服务器响应
    private static func validateResponse(_ configuration: Configuration, response: PaymentPasswordResponse, completion: @escaping PasswordValidatorComplete) {
        // 检查resultCode
        guard response.resultCode == ResultCode.success else {
            completion(nil, response.resultMsg)
            return
        }
        
        // 检查是否有签名值
        guard let signValue = response.signValue,
              let pwdToken = response.pwdToken else {
            completion(nil, "响应缺少签名或token")
            return
        }
        
        do {
            // 6. 验证签名
            let signString = "resultCode=\(response.resultCode)&resultMsg=\(response.resultMsg)&pwdToken=\(pwdToken)"
            LogManager.shared.crypto("待验证签名串: \(signString)")
            
            // 将签名值从Base64解码
            guard let signatureData = Data(base64Encoded: signValue) else {
                throw RSAError.invalidBase64
            }
            
            // 验证签名
            let isValid = try RSACrypto.verify(signString.data(using: .utf8) ?? Data(),
                                              signature: signatureData,
                                              publicKey: configuration.publicKey)
            
            if isValid {
                completion(pwdToken, nil)
            } else {
                completion(nil, "签名验证失败")
            }
            
        } catch {
            completion(nil, error.localizedDescription)
        }
    }
}

// MARK: - 便捷扩展
extension PaymentPasswordValidator {
    
    /// 创建异步验证器闭包
    /// - Returns: 符合AsyncPasswordValidator类型的闭包
    public static func createAsyncValidator(_ configuration: Configuration, success: @escaping (String) -> Void) -> AsyncPasswordValidator {
        return { password, callback in
            
            validate(configuration, password: password) { token, message in
                
                /// 修改密码页面状态
                callback(token != nil, message)
                LogManager.shared.info(message ?? "")
                if let token = token {
                    
                    /// 只有成功才传Token
                    success(token)
                }
            }
        }
    }
}
