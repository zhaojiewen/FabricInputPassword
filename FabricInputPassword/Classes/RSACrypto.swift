import Foundation
import Security

/// RSA错误类型
public enum RSAError: Error, LocalizedError {
    case invalidKey
    case encryptionFailed
    case decryptionFailed
    case signingFailed
    case verificationFailed
    case invalidBase64
    case invalidUTF8
    case keyGenerationFailed
    case unsupportedAlgorithm
    case invalidKeyFormat
    case keyImportFailed
    case dataTooLarge
    
    public var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "无效的RSA密钥"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        case .signingFailed:
            return "签名失败"
        case .verificationFailed:
            return "验证签名失败"
        case .invalidBase64:
            return "无效的Base64编码"
        case .invalidUTF8:
            return "无效的UTF-8编码"
        case .keyGenerationFailed:
            return "密钥生成失败"
        case .unsupportedAlgorithm:
            return "不支持的算法"
        case .invalidKeyFormat:
            return "无效的密钥格式"
        case .keyImportFailed:
            return "密钥导入失败"
        case .dataTooLarge:
            return "数据太大，超过RSA密钥支持的最大长度"
        }
    }
}

/// RSA密钥格式
public enum KeyFormat {
    case pem
    case der
    case base64
    case modulusExponent
}

/// RSA加解密管理器
public class RSACrypto {
    
    // MARK: - 配置
    
    /// RSA配置
    public struct Configuration {
        public let keySize: Int
        public let encryptionAlgorithm: SecKeyAlgorithm
        public let signatureAlgorithm: SecKeyAlgorithm
        public let padding: SecPadding
        
        public static let `default` = Configuration(
            keySize: 2048,
            encryptionAlgorithm: .rsaEncryptionPKCS1,
            signatureAlgorithm: .rsaSignatureMessagePKCS1v15SHA256,
            padding: .PKCS1
        )
        
        public static let oaep = Configuration(
            keySize: 2048,
            encryptionAlgorithm: .rsaEncryptionOAEPSHA256,
            signatureAlgorithm: .rsaSignatureMessagePKCS1v15SHA256,
            padding: .OAEP
        )
    }
    
    // MARK: - 智能加密（自动分块）
    
    /// 智能加密：自动处理数据分块
    /// - Parameters:
    ///   - data: 要加密的数据
    ///   - publicKey: 公钥
    ///   - configuration: 配置
    /// - Returns: 加密后的数据
    public static func smartEncrypt(_ data: Data,
                                   publicKey: SecKey,
                                   configuration: Configuration = .default) throws -> Data {
        let maxChunkSize = try getMaxEncryptionChunkSize(for: publicKey, configuration: configuration)
        
        // 如果数据小于等于最大块大小，直接加密
        if data.count <= maxChunkSize {
            return try encryptChunk(data, publicKey: publicKey, configuration: configuration)
        }
        
        // 否则进行分块加密
        var encryptedChunks: [Data] = []
        
        for i in stride(from: 0, to: data.count, by: maxChunkSize) {
            let end = min(i + maxChunkSize, data.count)
            let chunk = data.subdata(in: i..<end)
            
            let encryptedChunk = try encryptChunk(chunk, publicKey: publicKey, configuration: configuration)
            encryptedChunks.append(encryptedChunk)
        }
        
        // 组合所有加密块
        return combineEncryptedChunks(encryptedChunks)
    }
    
    /// 智能加密字符串
    public static func smartEncrypt(_ string: String,
                                   publicKey: SecKey,
                                   configuration: Configuration = .default) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw RSAError.invalidUTF8
        }
        let encryptedData = try smartEncrypt(data, publicKey: publicKey, configuration: configuration)
        return encryptedData.base64EncodedString()
    }
    
    /// 智能解密：自动处理数据分块
    public static func smartDecrypt(_ data: Data,
                                   privateKey: SecKey,
                                   configuration: Configuration = .default) throws -> Data {
        let keySize = SecKeyGetBlockSize(privateKey)
        
        // 检查是否是分块加密的数据
        if data.count <= keySize {
            // 单块数据，直接解密
            return try decryptChunk(data, privateKey: privateKey, configuration: configuration)
        }
        
        // 分块数据，需要分割解密
        var decryptedChunks: [Data] = []
        
        for i in stride(from: 0, to: data.count, by: keySize) {
            let end = min(i + keySize, data.count)
            let chunk = data.subdata(in: i..<end)
            
            let decryptedChunk = try decryptChunk(chunk, privateKey: privateKey, configuration: configuration)
            decryptedChunks.append(decryptedChunk)
        }
        
        // 组合所有解密块
        return combineDecryptedChunks(decryptedChunks)
    }
    
    /// 智能解密Base64字符串
    public static func smartDecrypt(_ base64String: String,
                                   privateKey: SecKey,
                                   configuration: Configuration = .default) throws -> String {
        guard let data = Data(base64Encoded: base64String) else {
            throw RSAError.invalidBase64
        }
        let decryptedData = try smartDecrypt(data, privateKey: privateKey, configuration: configuration)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw RSAError.invalidUTF8
        }
        return string
    }
    
    // MARK: - 核心加密/解密方法
    
    /// 加密单个数据块
    private static func encryptChunk(_ data: Data,
                                    publicKey: SecKey,
                                    configuration: Configuration) throws -> Data {
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, configuration.encryptionAlgorithm) else {
            throw RSAError.unsupportedAlgorithm
        }
        
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(publicKey,
                                                           configuration.encryptionAlgorithm,
                                                           data as CFData,
                                                           &error) as Data? else {
            throw error?.takeRetainedValue() as Error? ?? RSAError.encryptionFailed
        }
        
        return encryptedData
    }
    
    /// 解密单个数据块
    private static func decryptChunk(_ data: Data,
                                    privateKey: SecKey,
                                    configuration: Configuration) throws -> Data {
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, configuration.encryptionAlgorithm) else {
            throw RSAError.unsupportedAlgorithm
        }
        
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(privateKey,
                                                           configuration.encryptionAlgorithm,
                                                           data as CFData,
                                                           &error) as Data? else {
            throw error?.takeRetainedValue() as Error? ?? RSAError.decryptionFailed
        }
        
        return decryptedData
    }
    
    // MARK: - 辅助方法
    
    /// 获取最大加密块大小
    private static func getMaxEncryptionChunkSize(for key: SecKey, configuration: Configuration) throws -> Int {
        let keySizeInBits = SecKeyGetBlockSize(key) * 8
        
        // 根据填充方案计算最大数据大小
        switch configuration.padding {
        case .PKCS1:
            // PKCS#1 v1.5 填充占用 11 字节
            return (keySizeInBits / 8) - 11
        case .OAEP:
            // OAEP 填充占用更多空间
            // 对于SHA256，大约占用 66 字节
            return (keySizeInBits / 8) - 66
        default:
            throw RSAError.unsupportedAlgorithm
        }
    }
    
    /// 组合加密块
    private static func combineEncryptedChunks(_ chunks: [Data]) -> Data {
        return chunks.reduce(Data(), +)
    }
    
    /// 组合解密块
    private static func combineDecryptedChunks(_ chunks: [Data]) -> Data {
        return chunks.reduce(Data(), +)
    }
    
    // MARK: - 向后兼容的原始方法
    
    /// 原始加密方法（保持向后兼容）
    public static func encrypt(_ data: Data,
                              publicKey: SecKey,
                              configuration: Configuration = .default) throws -> Data {
        return try smartEncrypt(data, publicKey: publicKey, configuration: configuration)
    }
    
    /// 原始加密字符串方法
    public static func encrypt(_ string: String,
                              publicKey: SecKey,
                              configuration: Configuration = .default) throws -> String {
        return try smartEncrypt(string, publicKey: publicKey, configuration: configuration)
    }
    
}

// MARK: - 签名和验证
extension RSACrypto {
    
    /// 使用私钥签名数据
    public static func sign(_ data: Data,
                           privateKey: SecKey,
                           algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256) throws -> Data {
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw RSAError.unsupportedAlgorithm
        }
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey,
                                                   algorithm,
                                                   data as CFData,
                                                   &error) as Data? else {
            throw error?.takeRetainedValue() as Error? ?? RSAError.signingFailed
        }
        
        return signature
    }
    
    /// 使用私钥签名字符串
    public static func sign(_ string: String,
                           privateKey: SecKey,
                           algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw RSAError.invalidUTF8
        }
        let signature = try sign(data, privateKey: privateKey, algorithm: algorithm)
        return signature.base64EncodedString()
    }
    
    /// 使用公钥验证签名
    public static func verify(_ data: Data,
                             signature: Data,
                             publicKey: SecKey,
                             algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256) throws -> Bool {
        guard SecKeyIsAlgorithmSupported(publicKey, .verify, algorithm) else {
            throw RSAError.unsupportedAlgorithm
        }
        
        var error: Unmanaged<CFError>?
        let isValid = SecKeyVerifySignature(publicKey,
                                           algorithm,
                                           data as CFData,
                                           signature as CFData,
                                           &error)
        
        if let error = error {
            throw error.takeRetainedValue()
        }
        
        return isValid
    }
    
    /// 验证字符串签名
    public static func verify(_ string: String,
                             signatureBase64: String,
                             publicKey: SecKey,
                             algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256) throws -> Bool {
        guard let data = string.data(using: .utf8) else {
            throw RSAError.invalidUTF8
        }
        guard let signature = Data(base64Encoded: signatureBase64) else {
            throw RSAError.invalidBase64
        }
        
        return try verify(data, signature: signature, publicKey: publicKey, algorithm: algorithm)
    }
}

// MARK: - 异步操作
extension RSACrypto {
    
    /// 异步智能加密
    public static func smartEncryptAsync(_ data: Data,
                                        publicKey: SecKey,
                                        configuration: Configuration = .default,
                                        completion: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try smartEncrypt(data, publicKey: publicKey, configuration: configuration)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
}
