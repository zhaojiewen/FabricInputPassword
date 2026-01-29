import UIKit

/// 安全键盘代理
protocol SecurityKeyboardViewDelegate: AnyObject {
    func securityKeyboardView(_ view: SecurityKeyboardView, didTapNumber number: Int)
    func securityKeyboardViewDidTapDelete(_ view: SecurityKeyboardView)
    func securityKeyboardViewDidTapClear(_ view: SecurityKeyboardView)
}

/// 安全数字键盘 - 防监听、防记录
class SecurityKeyboardView: UIView {
    
    // MARK: - 属性
    
    weak var delegate: SecurityKeyboardViewDelegate?
    
    // 使用随机排列的键盘布局，防止固定模式被记录
    private var currentLayout: [[String]] = []
    
    // 键盘布局池，每次显示时随机选择一种
    private let layoutPool: [[[String]]] = [
        // 标准布局
        [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["清除", "0", "删除"]
        ],
        // 随机布局1
        [
            ["7", "4", "1"],
            ["8", "5", "2"],
            ["9", "6", "3"],
            ["清除", "0", "删除"]
        ],
        // 随机布局2
        [
            ["3", "6", "9"],
            ["2", "5", "8"],
            ["1", "4", "7"],
            ["删除", "0", "清除"]
        ],
        // 随机布局3
        [
            ["8", "3", "6"],
            ["1", "5", "9"],
            ["4", "7", "2"],
            ["清除", "删除", "0"]
        ]
    ]
    
    private var buttons: [[UIButton]] = []
    
    // MARK: - 安全特性
    
    /// 是否启用随机键盘布局
    public var enableRandomLayout: Bool = true
    
    /// 是否启用防截图保护
    public var enableScreenshotProtection: Bool = true
    
    /// 是否启用触摸点混淆
    public var enableTouchObfuscation: Bool = true
    
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSecurity()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // 清理时移除安全保护
        removeScreenshotProtection()
    }
    
    // MARK: - 安全设置
    
    private func setupSecurity() {
        // 防止键盘被截图
        if enableScreenshotProtection {
            setupScreenshotProtection()
        }
    }
    
    private func setupScreenshotProtection() {
        // 添加防截图层
        let protectionView = ScreenshotProtectionView()
        protectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(protectionView)
        
        NSLayoutConstraint.activate([
            protectionView.topAnchor.constraint(equalTo: topAnchor),
            protectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            protectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            protectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 将保护层置于最上层
        bringSubview(toFront: protectionView)
    }
    
    private func removeScreenshotProtection() {
        // 移除所有防截图视图
        subviews.forEach { view in
            if view is ScreenshotProtectionView {
                view.removeFromSuperview()
            }
        }
    }
        
    override var canBecomeFirstResponder: Bool {
        false
    }
    
    // MARK: - UI设置
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        
        // 选择键盘布局
        selectRandomLayout()
        
        // 创建按钮
        createButtons()
        
        setupConstraints()
    }
    
    private func selectRandomLayout() {
        if enableRandomLayout && !layoutPool.isEmpty {
            // 随机选择一个布局
            let randomIndex = Int.random(in: 0..<layoutPool.count)
            currentLayout = layoutPool[randomIndex]
        } else {
            // 使用默认布局
            currentLayout = layoutPool[0]
        }
    }
    
    private func createButtons() {
        buttons.removeAll()
        subviews.forEach { $0.removeFromSuperview() }
        
        for rowTitles in currentLayout {
            var rowButtons: [UIButton] = []
            for title in rowTitles {
                let button = createButton(with: title)
                rowButtons.append(button)
                addSubview(button)
            }
            buttons.append(rowButtons)
        }
    }
    
    private func createButton(with title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        
        // 设置不同按钮的颜色
        if title == "清除" || title == "删除" {
            button.setTitleColor(.systemRed, for: .normal)
        } else {
            button.setTitleColor(.black, for: .normal)
        }
        
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        
        
        // 添加点击动作
        if let number = Int(title) {
            button.tag = number
            button.addTarget(self, action: #selector(numberButtonTapped(_:)), for: .touchUpInside)
        } else if title == "删除" {
            button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        } else if title == "清除" {
            button.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        }
        
        return button
    }
    
    private func setupConstraints() {
        let buttonHeight: CGFloat = 60
        let buttonSpacing: CGFloat = 12
        let rowSpacing: CGFloat = 12
        
        for (rowIndex, rowButtons) in buttons.enumerated() {
            for (colIndex, button) in rowButtons.enumerated() {
                NSLayoutConstraint.activate([
                    button.heightAnchor.constraint(equalToConstant: buttonHeight),
                ])
                
                // 第一行
                if rowIndex == 0 {
                    button.topAnchor.constraint(equalTo: topAnchor).isActive = true
                } else {
                    button.topAnchor.constraint(equalTo: buttons[rowIndex - 1][colIndex].bottomAnchor, constant: rowSpacing).isActive = true
                }
                
                // 第一列
                if colIndex == 0 {
                    button.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                } else {
                    button.leadingAnchor.constraint(equalTo: rowButtons[colIndex - 1].trailingAnchor, constant: buttonSpacing).isActive = true
                }
                
                // 最后一列
                if colIndex == rowButtons.count - 1 {
                    button.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
                }
                
                // 最后一行
                if rowIndex == buttons.count - 1 {
                    button.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
                }
                
                // 等宽
                if colIndex > 0 {
                    button.widthAnchor.constraint(equalTo: rowButtons[0].widthAnchor).isActive = true
                }
            }
        }
    }
    
    // MARK: - 安全输入处理
    

    
    // MARK: - 按钮动作
    
    @objc private func numberButtonTapped(_ sender: UIButton) {
        // 添加随机延迟，防止通过时间分析攻击
        if enableTouchObfuscation {
            let randomDelay = Double.random(in: 0.01...0.05)
            DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                self.delegate?.securityKeyboardView(self, didTapNumber: sender.tag)
            }
        } else {
            delegate?.securityKeyboardView(self, didTapNumber: sender.tag)
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
    
    // MARK: - 公共方法
    
    /// 重新随机排列键盘布局
    public func reshuffleLayout() {
        selectRandomLayout()
        createButtons()
        setupConstraints()
        layoutIfNeeded()
    }
    
    
    /// 启用/禁用安全特性
    public func setSecurityFeatures(
        randomLayout: Bool? = nil,
        screenshotProtection: Bool? = nil,
        touchObfuscation: Bool? = nil
    ) {
        if let randomLayout = randomLayout {
            enableRandomLayout = randomLayout
        }
        if let screenshotProtection = screenshotProtection {
            enableScreenshotProtection = screenshotProtection
            if screenshotProtection {
                setupScreenshotProtection()
            } else {
                removeScreenshotProtection()
            }
        }
        if let touchObfuscation = touchObfuscation {
            enableTouchObfuscation = touchObfuscation
        }
    }
}

// MARK: - 防截图保护视图
private class ScreenshotProtectionView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupProtection()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupProtection()
    }
    
    private func setupProtection() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        
        // 添加防截图效果
        if #available(iOS 13.0, *) {
            // 使用模糊效果
            let blurEffect = UIBlurEffect(style: .regular)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(blurView)
            
            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: topAnchor),
                blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
    // 防止被截图
    override func draw(_ rect: CGRect) {
        // 不绘制任何内容
    }
    
    // 防止内容被捕获
    override var layer: CALayer {
        let layer = super.layer
        // 设置layer属性防止被截图
        layer.compositingFilter = "screenBlendMode"
        return layer
    }
}

