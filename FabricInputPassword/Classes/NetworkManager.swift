import Foundation

/// 网络请求错误
public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case timeout
    case noData
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的服务器响应"
        case .httpError(let statusCode, let message):
            return "HTTP错误 \(statusCode): \(message)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .encodingError(let error):
            return "数据编码错误: \(error.localizedDescription)"
        case .timeout:
            return "请求超时"
        case .noData:
            return "服务器返回空数据"
        }
    }
}

/// 网络请求管理器
public class NetworkManager {
    
    /// 单例实例
    public static let shared = NetworkManager()
    
    /// 默认配置
    private let defaultConfiguration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = [
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json"
        ]
        return config
    }()
    
    private let session: URLSession
    
    private init() {
        session = URLSession(configuration: defaultConfiguration)
        LogManager.shared.network("网络管理器初始化完成")
    }
    
    /// 发送POST请求
    /// - Parameters:
    ///   - url: 请求URL
    ///   - parameters: 请求参数
    ///   - headers: 请求头
    ///   - completion: 完成回调
    public func post<T: Decodable>(url: URL,
                                   parameters: [String: Any],
                                   headers: [String: String]? = nil,
                                   completion: @escaping (Result<T, NetworkError>) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 设置请求头
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // 记录请求信息
        LogManager.shared.network("发送POST请求到: \(url.absoluteString)")
        LogManager.shared.network("请求头: \(request.allHTTPHeaderFields ?? [:])")
        
        // 编码参数为Form表单格式
        do {
            let formData = try encodeFormData(parameters)
            request.httpBody = formData
            LogManager.shared.network("请求参数: \(String(data: formData, encoding: .utf8) ?? "")")
        } catch {
            LogManager.shared.error("请求参数编码失败: \(error.localizedDescription)")
            completion(.failure(.encodingError(error)))
            return
        }
        
        // 发送请求
        let task = session.dataTask(with: request) { data, response, error in
            // 处理网络错误
            if let error = error {
                if (error as NSError).code == NSURLErrorTimedOut {
                    LogManager.shared.error("请求超时: \(url.absoluteString)")
                    completion(.failure(.timeout))
                } else {
                    LogManager.shared.error("网络错误: \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            // 处理HTTP响应
            guard let httpResponse = response as? HTTPURLResponse else {
                LogManager.shared.error("无效的HTTP响应")
                completion(.failure(.invalidResponse))
                return
            }
            
            // 记录响应状态码
            LogManager.shared.network("HTTP响应状态码: \(httpResponse.statusCode)")
            
            // 检查HTTP状态码
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data ?? Data(), encoding: .utf8) ?? "未知错误"
                LogManager.shared.error("HTTP错误: \(httpResponse.statusCode) - \(message)")
                completion(.failure(.httpError(statusCode: httpResponse.statusCode, message: message)))
                return
            }
            
            // 检查是否有数据
            guard let data = data else {
                LogManager.shared.error("服务器返回空数据")
                completion(.failure(.noData))
                return
            }
            
            // 记录响应数据
            if let responseString = String(data: data, encoding: .utf8) {
                LogManager.shared.network("响应数据: \(responseString)")
            }
            
            // 解析JSON数据
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(T.self, from: data)
                completion(.success(result))
            } catch {
                LogManager.shared.error("响应数据解析失败: \(error.localizedDescription)")
                completion(.failure(.decodingError(error)))
            }
        }
        
        task.resume()
    }
    
    /// 编码Form表单数据
    private func encodeFormData(_ parameters: [String: Any]) throws -> Data {
        var components = URLComponents()
        components.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }
        
        guard let queryString = components.query else {
            let error = NSError(domain: "NetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法编码表单数据"])
            throw error
        }
        
        return queryString.data(using: .utf8) ?? Data()
    }
    
}
