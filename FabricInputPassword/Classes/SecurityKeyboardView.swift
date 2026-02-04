import UIKit
import Security

/// 安全键盘代理

@objc
protocol SecurityKeyboardViewDelegate: AnyObject {
    func securityKeyboardView(_ view: SecurityKeyboardView, didTapNumber number: Int)
    func securityKeyboardViewDidTapDelete(_ view: SecurityKeyboardView)
    func securityKeyboardViewDidTapClear(_ view: SecurityKeyboardView)
    
    // 新增：RSA加密回调
    @objc optional
    func securityKeyboardView(_ view: SecurityKeyboardView, didTapEncryptedNumber encrypted: String)
}

/// 安全数字键盘 - 防监听、防记录
class SecurityKeyboardView: UIView {
    
    // MARK: - 属性
    
    weak var delegate: SecurityKeyboardViewDelegate?
    
    // 数字集合
    private let numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    
    // 按钮数组
    private var numberButtons: [UIButton] = []
    private var deleteButton: UIButton?
    private var lastNumberButton: UIButton?
    
    // 当前随机布局
    private var currentLayout: [String] = []
    
    // RSA加密相关
    private var rsaPublicKey: SecKey?
    private var rsaConfiguration: RSACrypto.Configuration = .default
    
    // MARK: - 安全特性
    
    /// 是否启用随机键盘布局
    public var enableRandomLayout: Bool = false
    
    /// 是否启用触摸点混淆
    public var enableTouchObfuscation: Bool = false
    
    /// 是否启用点击后重新随机
    public var enableReshuffleOnTap: Bool = false
    
    /// 是否启用RSA加密
    public var enableRSAEncryption: Bool = false
    
    /// 是否启用加密后重新随机布局
    public var enableReshuffleAfterEncryption: Bool = false
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        false
    }
    
    // MARK: - UI设置
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 236 / 255.0, green: 237 / 255.0, blue: 239 / 255.0, alpha: 1)
        
        // 生成随机布局
        generateRandomLayout()
        
        // 创建按钮
        createButtons()
        
        setupConstraints()
    }
    
    private func generateRandomLayout() {
        currentLayout.removeAll()
        
        if enableRandomLayout {
            // 完全随机打乱数字顺序
            currentLayout = numbers.shuffled()
        } else {
            // 使用标准顺序
            currentLayout = numbers
        }
    }
    
    private func createButtons() {
        // 移除所有现有按钮
        numberButtons.forEach { $0.removeFromSuperview() }
        deleteButton?.removeFromSuperview()
        lastNumberButton?.removeFromSuperview()
        
        numberButtons.removeAll()
        
        // 创建前9个数字按钮（九宫格）
        for i in 0..<9 {
            let number = currentLayout[i]
            let button = createNumberButton(with: number, index: i)
            numberButtons.append(button)
            addSubview(button)
        }
        
        // 创建最后一个数字按钮（占用两格位置）
        let lastNumber = currentLayout[9]
        lastNumberButton = createNumberButton(with: lastNumber, index: 9)
        if let lastNumberButton = lastNumberButton {
            addSubview(lastNumberButton)
        }
        
        // 创建删除按钮
        deleteButton = createDeleteButton()
        
        if let deleteButton = deleteButton {
            addSubview(deleteButton)
        }
    }
    
    private func createNumberButton(with number: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        
        // 设置标题
        button.setTitle(number, for: .normal)
        button.titleLabel?.font = UIFont(name: "DIN Alternate Bold", size: 28)
        button.setTitleColor(UIColor(red: 64 / 255.0, green: 66 / 255.0, blue: 70 / 255.0, alpha: 1), for: .normal)
        
        // 设置样式
        button.backgroundColor = .white
        button.layer.cornerRadius = 6
        
        // 存储真实值
        if let value = Int(number) {
            button.tag = value
        }
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击动作
        button.addTarget(self, action: #selector(numberButtonTapped(_:)), for: .touchUpInside)
        
        // 添加触摸效果
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        return button
    }
    
    private func createDeleteButton() -> UIButton {
        let button = UIButton(type: .system)
        
        // 设置删除图标
        button.setImage(FabricBundle.loadImage(named: "delete"), for: .normal)
        
        button.tintColor = UIColor(red: 64 / 255.0, green: 66 / 255.0, blue: 70 / 255.0, alpha: 1)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        // 设置样式
        button.backgroundColor = .white
        button.layer.cornerRadius = 6
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击动作
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // 添加触摸效果
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        return button
    }
    
    private func setupConstraints() {
        let buttonHeight: CGFloat = 54.5
        let buttonSpacing: CGFloat = 7
        let rowSpacing: CGFloat = 7
        
        // 前9个数字按钮布局 (3x3 九宫格)
        for (index, button) in numberButtons.enumerated() {
            let row = index / 3
            let col = index % 3
            
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: buttonHeight),
            ])
            
            // 第一行
            if row == 0 {
                button.topAnchor.constraint(equalTo: topAnchor).isActive = true
            } else {
                let previousRowButton = numberButtons[(row - 1) * 3 + col]
                button.topAnchor.constraint(equalTo: previousRowButton.bottomAnchor, constant: rowSpacing).isActive = true
            }
            
            // 第一列
            if col == 0 {
                button.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                let previousButton = numberButtons[row * 3 + (col - 1)]
                button.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor, constant: buttonSpacing).isActive = true
            }
            
            // 最后一列
            if col == 2 {
                button.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
            
            // 等宽约束（所有按钮等宽）
            if index > 0 {
                button.widthAnchor.constraint(equalTo: numberButtons[0].widthAnchor).isActive = true
            }
        }
        
        // 最后一行布局：最后一个数字（占用两格位置）+ 删除
        if let lastNumberButton = lastNumberButton,
           let deleteButton = deleteButton {
            
            let lastRowButton = numberButtons[8] // 九宫格的最后一个按钮
            
            NSLayoutConstraint.activate([
                // 高度约束
                lastNumberButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                deleteButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                
                // 宽度约束
                // 最后一个数字按钮宽度 = 数字按钮宽度 * 2 + 间距
                lastNumberButton.widthAnchor.constraint(equalTo: numberButtons[0].widthAnchor, multiplier: 2.0, constant: buttonSpacing),
                deleteButton.widthAnchor.constraint(equalTo: numberButtons[0].widthAnchor),
                
                // 顶部约束（在九宫格下方）
                lastNumberButton.topAnchor.constraint(equalTo: lastRowButton.bottomAnchor, constant: rowSpacing),
                deleteButton.topAnchor.constraint(equalTo: lastRowButton.bottomAnchor, constant: rowSpacing),
                
                // 底部约束
                lastNumberButton.bottomAnchor.constraint(equalTo: bottomAnchor),
                deleteButton.bottomAnchor.constraint(equalTo: bottomAnchor),
                
                // 水平布局：最后一个数字（左对齐）| 删除（右对齐）
                lastNumberButton.leadingAnchor.constraint(equalTo: leadingAnchor),
                deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                
                // 删除按钮与最后一个数字按钮之间的间距
                deleteButton.leadingAnchor.constraint(equalTo: lastNumberButton.trailingAnchor, constant: buttonSpacing),
            ])
        }
    }
    
    // MARK: - 按钮动作
    
    @objc private func numberButtonTapped(_ sender: UIButton) {
        // 获取真实值
        let realValue = sender.tag
        
        // 如果启用了RSA加密，先加密再回调
        if enableRSAEncryption, let publicKey = rsaPublicKey {
            encryptAndSendNumber(realValue, with: publicKey)
        } else {
            // 未启用加密，直接回调
            sendNumberWithDelay(realValue)
        }
        
        // 每次点击后重新随机布局（可选）
        if enableRandomLayout && enableReshuffleOnTap {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.reshuffleLayout()
            }
        }
        
        // 加密后重新随机布局（可选）
        if enableRSAEncryption && enableReshuffleAfterEncryption {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.reshuffleLayout()
            }
        }
    }
    
    @objc private func deleteButtonTapped() {
        delegate?.securityKeyboardViewDidTapDelete(self)
    }
    
    @objc private func clearButtonTapped() {
        delegate?.securityKeyboardViewDidTapClear(self)
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = .white
            sender.transform = .identity
        }
    }
    
    // MARK: - RSA加密方法
    
    /// 启用RSA加密
    /// - Parameters:
    ///   - publicKey: 公钥
    ///   - configuration: 配置（可选）
    public func enableRSAEncryption(with publicKey: SecKey, configuration: RSACrypto.Configuration = .default) {
        self.rsaPublicKey = publicKey
        self.rsaConfiguration = configuration
        self.enableRSAEncryption = true
    }
    
    /// 加密并发送数字
    private func encryptAndSendNumber(_ number: Int, with publicKey: SecKey) {
        // 将数字转换为字符串
        let numberString = "\(number)"
        
        do {
            
            // 使用RSACrypto进行加密
            let encryptedStr = try RSACrypto.smartEncrypt(numberString, publicKey: publicKey, configuration: rsaConfiguration)
            
            // 添加随机延迟，防止通过时间分析攻击
            if enableTouchObfuscation {
                let randomDelay = Double.random(in: 0.01...0.05)
                DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                    // 回调加密数据
                    self.delegate?.securityKeyboardView?(self, didTapEncryptedNumber: encryptedStr)
                }
            } else {
                // 回调加密数据
                delegate?.securityKeyboardView?(self, didTapEncryptedNumber: encryptedStr)
            }
            
        } catch {
            print("RSA加密失败: \(error)")
            // 加密失败时，发送原始数字
            sendNumberWithDelay(number)
        }
    }
    
    /// 发送数字（带延迟）
    private func sendNumberWithDelay(_ number: Int) {
        // 添加随机延迟，防止通过时间分析攻击
        if enableTouchObfuscation {
            let randomDelay = Double.random(in: 0.01...0.05)
            DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                self.delegate?.securityKeyboardView(self, didTapNumber: number)
            }
        } else {
            delegate?.securityKeyboardView(self, didTapNumber: number)
        }
    }
    
    
    // MARK: - 公共方法
    
    /// 重新随机排列键盘布局
    public func reshuffleLayout() {
        generateRandomLayout()
        createButtons()
        setupConstraints()
        layoutIfNeeded()
    }
    
    /// 启用/禁用安全特性
    public func setSecurityFeatures(
        randomLayout: Bool? = nil,
        touchObfuscation: Bool? = nil,
        reshuffleOnTap: Bool? = nil,
        rsaEncryption: Bool? = nil,
        reshuffleAfterEncryption: Bool? = nil
    ) {
        if let randomLayout = randomLayout {
            enableRandomLayout = randomLayout
        }
        if let touchObfuscation = touchObfuscation {
            enableTouchObfuscation = touchObfuscation
        }
        if let reshuffleOnTap = reshuffleOnTap {
            enableReshuffleOnTap = reshuffleOnTap
        }
        if let rsaEncryption = rsaEncryption {
            enableRSAEncryption = rsaEncryption
        }
        if let reshuffleAfterEncryption = reshuffleAfterEncryption {
            enableReshuffleAfterEncryption = reshuffleAfterEncryption
        }
        
        if randomLayout != nil {
            reshuffleLayout()
        }
    }
    
    /// 获取当前布局信息
    public func getCurrentLayout() -> [String] {
        return currentLayout
    }
    
}
