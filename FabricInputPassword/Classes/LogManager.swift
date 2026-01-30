import Foundation

/// 日志管理器
public class LogManager {
    
    /// 单例实例
    public static let shared = LogManager()
    
    /// 日志开关
    public var isLogEnabled: Bool = true
    
    /// 日志前缀
    private let logPrefix = "[hnapay]"
    
    private init() {}
    
    /// 打印信息日志
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isLogEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("\(logPrefix) [INFO] [\(fileName):\(line) \(function)] \(message)")
    }
    
    /// 打印调试日志
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isLogEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("\(logPrefix) [DEBUG] [\(fileName):\(line) \(function)] \(message)")
    }
    
    /// 打印警告日志
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isLogEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("\(logPrefix) [WARNING] [\(fileName):\(line) \(function)] \(message)")
    }
    
    /// 打印错误日志
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isLogEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("\(logPrefix) [ERROR] [\(fileName):\(line) \(function)] \(message)")
    }
    
    /// 打印网络请求日志
    public func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isLogEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("\(logPrefix) [NETWORK] [\(fileName):\(line) \(function)] \(message)")
    }
    
    /// 打印加密相关日志
    public func crypto(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isLogEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("\(logPrefix) [CRYPTO] [\(fileName):\(line) \(function)] \(message)")
    }
    
    /// 打印业务日志
    public func business(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isLogEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("\(logPrefix) [BUSINESS] [\(fileName):\(line) \(function)] \(message)")
    }
}

// MARK: - 便捷方法
extension LogManager {
    
    /// 启用/禁用所有日志
    public func setLogEnabled(_ enabled: Bool) {
        isLogEnabled = enabled
    }
    
    /// 获取当前日志状态
    public var logStatus: String {
        return isLogEnabled ? "已启用" : "已禁用"
    }
}
