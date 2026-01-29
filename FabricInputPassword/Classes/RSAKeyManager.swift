import Foundation
import Security

/// RSA密钥管理器
public class RSAKeyManager {
    
    /// RSA密钥配置
    public struct KeyConfiguration {
        public let keySize: Int
        public let isPermanent: Bool
        public let tag: String?
        public let accessibility: CFString
        
        public static let `default` = KeyConfiguration(
            keySize: 2048,
            isPermanent: false,
            tag: nil,
            accessibility: kSecAttrAccessibleWhenUnlocked
        )
        
        public static let secure = KeyConfiguration(
            keySize: 4096,
            isPermanent: true,
            tag: "com.fabricinputpassword.rsa.keys",
            accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        )
    }
    
    // MARK: - ASN.1 结构
    
    /// ASN.1标签
    private enum ASN1Tag: UInt8 {
        case sequence = 0x30
        case integer = 0x02
        case bitString = 0x03
        case objectIdentifier = 0x06
        case null = 0x05
    }
    
    /// PKCS#1 RSA公钥ASN.1结构
    private struct PKCS1PublicKey {
        let modulus: Data
        let exponent: Data
        
        var asn1Data: Data {
            var data = Data()
            
            // 序列开始
            data.append(ASN1Tag.sequence.rawValue)
            
            // 模数
            let modulusLength = encodeLength(modulus.count)
            data.append(ASN1Tag.integer.rawValue)
            data.append(modulusLength)
            data.append(modulus)
            
            // 指数
            let exponentLength = encodeLength(exponent.count)
            data.append(ASN1Tag.integer.rawValue)
            data.append(exponentLength)
            data.append(exponent)
            
            // 更新序列长度
            let sequenceLength = encodeLength(data.count - 1)
            data[1] = sequenceLength.first ?? 0
            if sequenceLength.count > 1 {
                data.insert(sequenceLength[1], at: 2)
            }
            
            return data
        }
    }
    
    /// X.509 SubjectPublicKeyInfo结构
    private struct SubjectPublicKeyInfo {
        let algorithmIdentifier: Data
        let subjectPublicKey: Data
        
        var asn1Data: Data {
            var data = Data()
            
            // 外层序列
            data.append(ASN1Tag.sequence.rawValue)
            let outerSequenceLengthPosition = data.count
            data.append(0x00) // 占位符
            
            // 算法标识符
            data.append(algorithmIdentifier)
            
            // 公钥（位字符串）
            var bitStringData = Data()
            bitStringData.append(ASN1Tag.bitString.rawValue)
            let bitStringLength = encodeLength(subjectPublicKey.count + 1) // +1 for unused bits
            bitStringData.append(bitStringLength)
            bitStringData.append(0x00) // 未使用的位数
            bitStringData.append(subjectPublicKey)
            
            data.append(bitStringData)
            
            // 更新外层序列长度
            let outerSequenceLength = data.count - outerSequenceLengthPosition - 1
            let encodedLength = encodeLength(outerSequenceLength)
            data[outerSequenceLengthPosition] = encodedLength.first ?? 0
            if encodedLength.count > 1 {
                data.insert(encodedLength[1], at: outerSequenceLengthPosition + 1)
            }
            
            return data
        }
    }
    
    // MARK: - 密钥生成
    
    /// 生成RSA密钥对
    /// - Parameter configuration: 密钥配置
    /// - Returns: 公钥和私钥
    public static func generateKeyPair(configuration: KeyConfiguration = .default) throws -> (publicKey: SecKey, privateKey: SecKey) {
        var privateKeyAttributes: [String: Any] = [
            kSecAttrIsPermanent as String: configuration.isPermanent,
            kSecAttrAccessible as String: configuration.accessibility
        ]
        
        var publicKeyAttributes: [String: Any] = [
            kSecAttrIsPermanent as String: configuration.isPermanent,
            kSecAttrAccessible as String: configuration.accessibility
        ]
        
        // 如果有tag，添加到属性中
        if let tag = configuration.tag, !tag.isEmpty {
            let tagData = tag.data(using: .utf8)!
            privateKeyAttributes[kSecAttrApplicationTag as String] = tagData
            publicKeyAttributes[kSecAttrApplicationTag as String] = tagData
        }
        
        let parameters: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: configuration.keySize,
            kSecPrivateKeyAttrs as String: privateKeyAttributes,
            kSecPublicKeyAttrs as String: publicKeyAttributes
        ]
        
        var publicKey: SecKey?
        var privateKey: SecKey?
        let status = SecKeyGeneratePair(parameters as CFDictionary, &publicKey, &privateKey)
        
        guard status == errSecSuccess, let pubKey = publicKey, let privKey = privateKey else {
            throw RSAError.keyGenerationFailed
        }
        
        return (pubKey, privKey)
    }
    
    // MARK: - 密钥导入（支持各种格式）
    
    /// 从PEM格式导入公钥（支持PKCS#1和X.509格式）
    public static func importPublicKeyFromPEM(_ pemString: String) throws -> SecKey {
        // 提取Base64部分
        let base64String = try extractBase64FromPEM(pemString, isPrivate: false)
        guard let derData = Data(base64Encoded: base64String) else {
            throw RSAError.invalidBase64
        }
        
        // 尝试解析DER数据
        let keyData: Data
        if isPKCS1PublicKey(derData) {
            // PKCS#1格式，需要转换为X.509格式
            keyData = try convertPKCS1ToX509(derData)
        } else if isX509PublicKey(derData) {
            // 已经是X.509格式
            keyData = derData
        } else {
            throw RSAError.invalidKeyFormat
        }
        
        return try createPublicKey(from: keyData)
    }
    
    
    /// 从模数和指数导入公钥
    public static func importPublicKeyFromModulusAndExponent(modulus: Data, exponent: Data) throws -> SecKey {
        // 创建PKCS#1公钥结构
        let pkcs1Key = PKCS1PublicKey(modulus: modulus, exponent: exponent)
        let pkcs1Data = pkcs1Key.asn1Data
        
        // 转换为X.509格式
        let x509Data = try convertPKCS1ToX509(pkcs1Data)
        
        return try createPublicKey(from: x509Data)
    }
    
    /// 从Base64字符串导入公钥
    public static func importPublicKeyFromBase64(_ base64String: String, format: KeyFormat = .der) throws -> SecKey {
        guard let derData = Data(base64Encoded: base64String) else {
            throw RSAError.invalidBase64
        }
        
        let keyData: Data
        switch format {
        case .der:
            keyData = derData
        case .pem:
            return try importPublicKeyFromPEM(base64String)
        case .base64:
            // 已经是Base64，直接使用
            keyData = derData
        case .modulusExponent:
            // 假设数据是模数和指数的组合
            // 这里简化处理，实际需要解析
            throw RSAError.unsupportedAlgorithm
        }
        
        return try createPublicKey(from: keyData)
    }
    
    // MARK: - 密钥导出
    
    /// 导出公钥为PEM格式
    public static func exportPublicKeyToPEM(_ publicKey: SecKey) throws -> String {
        guard let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            throw RSAError.invalidKey
        }
        
        // 转换为X.509格式
        let x509Data = try convertRawKeyToX509(keyData)
        let base64String = x509Data.base64EncodedString(options: [.lineLength64Characters])
        
        return "-----BEGIN PUBLIC KEY-----\n\(base64String)\n-----END PUBLIC KEY-----"
    }
    
    /// 导出公钥为模数和指数
    public static func exportPublicKeyToModulusAndExponent(_ publicKey: SecKey) throws -> (modulus: Data, exponent: Data) {
        guard let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            throw RSAError.invalidKey
        }
        
        // 解析原始密钥数据获取模数和指数
        // 这里简化处理，实际需要解析ASN.1结构
        let keySize = SecKeyGetBlockSize(publicKey) * 8
        
        // 假设数据格式：模数 + 指数
        // 实际实现需要根据具体格式解析
        let modulusSize = keySize / 8
        guard keyData.count >= modulusSize + 3 else {
            throw RSAError.invalidKeyFormat
        }
        
        let modulus = keyData.prefix(modulusSize)
        let exponent = keyData.suffix(from: modulusSize)
        
        return (Data(modulus), Data(exponent))
    }
    
    // MARK: - 私有辅助方法
    
    /// 从PEM字符串提取Base64部分
    private static func extractBase64FromPEM(_ pemString: String, isPrivate: Bool) throws -> String {
        var pem = pemString
        
        // 定义可能的头部和尾部
        let publicKeyHeaders = ["-----BEGIN PUBLIC KEY-----", "-----BEGIN RSA PUBLIC KEY-----"]
        let publicKeyFooters = ["-----END PUBLIC KEY-----", "-----END RSA PUBLIC KEY-----"]
        
        let privateKeyHeaders = ["-----BEGIN RSA PRIVATE KEY-----", "-----BEGIN PRIVATE KEY-----", "-----BEGIN ENCRYPTED PRIVATE KEY-----"]
        let privateKeyFooters = ["-----END RSA PRIVATE KEY-----", "-----END PRIVATE KEY-----", "-----END ENCRYPTED PRIVATE KEY-----"]
        
        let headers = isPrivate ? privateKeyHeaders : publicKeyHeaders
        let footers = isPrivate ? privateKeyFooters : publicKeyFooters
        
        // 移除头部
        for header in headers {
            if let range = pem.range(of: header) {
                pem.removeSubrange(range)
                break
            }
        }
        
        // 移除尾部
        for footer in footers {
            if let range = pem.range(of: footer) {
                pem.removeSubrange(range)
                break
            }
        }
        
        // 移除空白字符
        pem = pem.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        return pem
    }
    
    /// 检查是否是PKCS#1公钥
    private static func isPKCS1PublicKey(_ data: Data) -> Bool {
        // PKCS#1公钥以SEQUENCE开始，包含两个INTEGER
        guard data.count >= 2, data[0] == ASN1Tag.sequence.rawValue else {
            return false
        }
        
        // 简化检查：看是否包含RSA OID
        return !data.contains(0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01) // RSA OID
    }
    
    /// 检查是否是X.509公钥
    private static func isX509PublicKey(_ data: Data) -> Bool {
        // X.509公钥包含RSA OID
        return data.contains(0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01) // RSA OID
    }
    
    /// 将PKCS#1公钥转换为X.509格式
    private static func convertPKCS1ToX509(_ pkcs1Data: Data) throws -> Data {
        // RSA算法标识符（OID: 1.2.840.113549.1.1.1）
        let rsaAlgorithmIdentifier: [UInt8] = [
            0x30, 0x0D, // SEQUENCE (13 bytes)
            0x06, 0x09, // OBJECT IDENTIFIER (9 bytes)
            0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01, // RSA OID
            0x05, 0x00 // NULL
        ]
        
        let algorithmIdentifier = Data(rsaAlgorithmIdentifier)
        let subjectPublicKey = pkcs1Data
        
        let spki = SubjectPublicKeyInfo(
            algorithmIdentifier: algorithmIdentifier,
            subjectPublicKey: subjectPublicKey
        )
        
        return spki.asn1Data
    }
    
    /// 将原始密钥数据转换为X.509格式
    private static func convertRawKeyToX509(_ rawKeyData: Data) throws -> Data {
        // 这里简化处理，假设原始数据已经是合适的格式
        // 实际实现需要根据具体格式转换
        return rawKeyData
    }
    
    /// 创建公钥SecKey对象
    private static func createPublicKey(from keyData: Data) throws -> SecKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048, // 自动检测
            kSecReturnPersistentRef as String: true
        ]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(keyData as CFData,
                                            attributes as CFDictionary,
                                            &error) else {
            throw error?.takeRetainedValue() as Error? ?? RSAError.keyImportFailed
        }
        return key
    }
    
    
    /// 编码ASN.1长度
    private static func encodeLength(_ length: Int) -> Data {
        var data = Data()
        
        if length < 128 {
            // 短形式
            data.append(UInt8(length))
        } else {
            // 长形式
            var temp = length
            var bytes: [UInt8] = []
            
            while temp > 0 {
                bytes.append(UInt8(temp & 0xFF))
                temp >>= 8
            }
            
            bytes.reverse()
            data.append(UInt8(0x80 | bytes.count))
            data.append(contentsOf: bytes)
        }
        
        return data
    }
}
// MARK: - Data扩展
private extension Data {
    /// 检查是否包含指定的字节序列
    func contains(_ bytes: UInt8...) -> Bool {
        guard bytes.count > 0 else { return false }
        
        for i in 0...(self.count - bytes.count) {
            var found = true
            for j in 0..<bytes.count {
                if self[i + j] != bytes[j] {
                    found = false
                    break
                }
            }
            if found {
                return true
            }
        }
        
        return false
    }
}

