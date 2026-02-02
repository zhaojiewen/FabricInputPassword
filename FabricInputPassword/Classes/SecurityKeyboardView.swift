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
    
    // 数字集合
    private let numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    // 按钮数组
    private var numberButtons: [UIButton] = []
    private var deleteButton: UIButton?
    private var clearButton: UIButton?
    private var lastNumberButton: UIButton?
    
    // 当前随机布局
    private var currentLayout: [String] = []
    
    // MARK: - 安全特性
    
    /// 是否启用随机键盘布局
    public var enableRandomLayout: Bool = true
    
    /// 是否启用触摸点混淆
    public var enableTouchObfuscation: Bool = true
    
    /// 是否启用点击后重新随机
    public var enableReshuffleOnTap: Bool = false
    
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
        backgroundColor = .clear
        
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
        clearButton?.removeFromSuperview()
        lastNumberButton?.removeFromSuperview()
        
        numberButtons.removeAll()
        
        // 创建前9个数字按钮（九宫格）
        for i in 0..<9 {
            let number = currentLayout[i]
            let button = createNumberButton(with: number, index: i)
            numberButtons.append(button)
            addSubview(button)
        }
        
        // 创建最后一个数字按钮（放在清除和删除中间）
        let lastNumber = currentLayout[9]
        lastNumberButton = createNumberButton(with: lastNumber, index: 9)
        if let lastNumberButton = lastNumberButton {
            addSubview(lastNumberButton)
        }
        
        // 创建控制按钮
        deleteButton = createControlButton(with: "删除", isDelete: true)
        clearButton = createControlButton(with: "清除", isDelete: false)
        
        if let deleteButton = deleteButton {
            addSubview(deleteButton)
        }
        
        if let clearButton = clearButton {
            addSubview(clearButton)
        }
    }
    
    private func createNumberButton(with number: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        
        // 设置标题
        button.setTitle(number, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        button.setTitleColor(.black, for: .normal)
        
        // 设置样式
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2
        
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
    
    private func createControlButton(with title: String, isDelete: Bool) -> UIButton {
        let button = UIButton(type: .system)
        
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        
        // 设置样式
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
        if isDelete {
            button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        }
        
        // 添加触摸效果
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        return button
    }
    
    private func setupConstraints() {
        let buttonHeight: CGFloat = 60
        let buttonSpacing: CGFloat = 12
        let rowSpacing: CGFloat = 12
        
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
        
        // 最后一行布局：清除 + 最后一个数字 + 删除
        if let clearButton = clearButton, 
           let lastNumberButton = lastNumberButton,
           let deleteButton = deleteButton {
            
            let lastRowButton = numberButtons[8] // 九宫格的最后一个按钮
            
            NSLayoutConstraint.activate([
                // 高度约束
                clearButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                lastNumberButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                deleteButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                
                // 宽度约束（等宽，与数字按钮相同）
                clearButton.widthAnchor.constraint(equalTo: numberButtons[0].widthAnchor),
                lastNumberButton.widthAnchor.constraint(equalTo: numberButtons[0].widthAnchor),
                deleteButton.widthAnchor.constraint(equalTo: numberButtons[0].widthAnchor),
                
                // 顶部约束（在九宫格下方）
                clearButton.topAnchor.constraint(equalTo: lastRowButton.bottomAnchor, constant: rowSpacing),
                lastNumberButton.topAnchor.constraint(equalTo: lastRowButton.bottomAnchor, constant: rowSpacing),
                deleteButton.topAnchor.constraint(equalTo: lastRowButton.bottomAnchor, constant: rowSpacing),
                
                // 底部约束
                clearButton.bottomAnchor.constraint(equalTo: bottomAnchor),
                lastNumberButton.bottomAnchor.constraint(equalTo: bottomAnchor),
                deleteButton.bottomAnchor.constraint(equalTo: bottomAnchor),
                
                // 水平布局：清除 | 最后一个数字 | 删除
                clearButton.leadingAnchor.constraint(equalTo: leadingAnchor),
                clearButton.trailingAnchor.constraint(equalTo: lastNumberButton.leadingAnchor, constant: -buttonSpacing),
                
                lastNumberButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                
                deleteButton.leadingAnchor.constraint(equalTo: lastNumberButton.trailingAnchor, constant: buttonSpacing),
                deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }
    }
    
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
        
        // 每次点击后重新随机布局（可选）
        if enableRandomLayout && enableReshuffleOnTap {
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
        reshuffleOnTap: Bool? = nil
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
        
        if randomLayout != nil {
            reshuffleLayout()
        }
    }
    
    /// 获取当前布局信息
    public func getCurrentLayout() -> [String] {
        return currentLayout
    }
    
}
