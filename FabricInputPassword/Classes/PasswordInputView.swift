import UIKit

/// 密码输入视图代理
protocol PasswordInputViewDelegate: AnyObject {
    func passwordInputView(_ view: PasswordInputView, didEnterPassword password: [Int])
    func passwordInputViewDidBeginEditing(_ view: PasswordInputView)
    func passwordInputViewDidChange(_ view: PasswordInputView, password: [Int])
}

/// 密码输入视图（6个格子）- 使用数字数组存储密码
class PasswordInputView: UIView {
    
    // MARK: - 属性
    
    private let length: Int
    private var password: [Int] = []  // 使用数字数组而不是字符串
    private var digitViews: [UIView] = []
    private var cursorLayer: CALayer?
    private var cursorTimer: Timer?
    
    weak var delegate: PasswordInputViewDelegate?
    
    // MARK: - 初始化
    
    init(length: Int = 6) {
        self.length = length
        super.init(frame: .zero)
        setupUI()
        setupGesture()
        setupCursor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cursorTimer?.invalidate()
        // 安全清理密码数据
        secureClearPassword()
    }
    
    // MARK: - UI设置
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // 创建数字格子
        for _ in 0..<length {
            let digitContainer = createDigitContainer()
            digitViews.append(digitContainer)
            addSubview(digitContainer)
        }
        
        setupConstraints()
    }
    
    private func createDigitContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.lightGray.cgColor
        container.layer.cornerRadius = 8
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加圆点标签
        let dotLabel = UILabel()
        dotLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        dotLabel.textColor = .black
        dotLabel.textAlignment = .center
        dotLabel.isHidden = true
        dotLabel.tag = 100 // 用于标识
        container.addSubview(dotLabel)
        
        // 圆点标签约束
        dotLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dotLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dotLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func setupConstraints() {
        for (index, digitView) in digitViews.enumerated() {
            NSLayoutConstraint.activate([
                digitView.topAnchor.constraint(equalTo: topAnchor),
                digitView.bottomAnchor.constraint(equalTo: bottomAnchor),
                digitView.widthAnchor.constraint(equalToConstant: 44),
                digitView.heightAnchor.constraint(equalToConstant: 44),
            ])
            
            if index == 0 {
                digitView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                digitView.leadingAnchor.constraint(equalTo: digitViews[index - 1].trailingAnchor, constant: 12).isActive = true
            }
            
            if index == length - 1 {
                digitView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
        }
    }
    
    // MARK: - 光标设置
    
    private func setupCursor() {
        cursorLayer = CALayer()
        cursorLayer?.backgroundColor = UIColor.systemBlue.cgColor
        cursorLayer?.cornerRadius = 1
        cursorLayer?.isHidden = true
        
        if let cursorLayer = cursorLayer {
            layer.addSublayer(cursorLayer)
        }
        
        // 启动光标闪烁定时器
        startCursorBlinking()
    }
    
    private func updateCursorPosition() {
        let currentIndex = password.count
        guard currentIndex < digitViews.count else {
            cursorLayer?.isHidden = true
            return
        }
        
        let digitView = digitViews[currentIndex]
        let cursorWidth: CGFloat = 2
        let cursorHeight: CGFloat = 24
        
        cursorLayer?.frame = CGRect(
            x: digitView.frame.midX - cursorWidth / 2,
            y: digitView.frame.midY - cursorHeight / 2,
            width: cursorWidth,
            height: cursorHeight
        )
        cursorLayer?.isHidden = false
    }
    
    private func startCursorBlinking() {
        cursorTimer?.invalidate()
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let cursorLayer = self.cursorLayer else { return }
            
            if self.isFirstResponder && self.password.count < self.length {
                cursorLayer.isHidden = !cursorLayer.isHidden
            } else {
                cursorLayer.isHidden = true
            }
        }
    }
    
    // MARK: - 手势设置
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func viewTapped() {
        becomeFirstResponder()
    }
    
    // MARK: - 密码操作（使用数字数组）
    
    func appendNumber(_ number: Int) {
        guard password.count < length else { return }
        
        password.append(number)
        updateDigitViews()
        updateCursorPosition()
        delegate?.passwordInputViewDidChange(self, password: password)
        
        if password.count == length {
            let securityCopyPassword = Array(password)
            /// 输入完成后立马清除
            secureClearPassword()
            
            delegate?.passwordInputView(self, didEnterPassword: securityCopyPassword)
        }
    }
    
    func deleteLastNumber() {
        guard !password.isEmpty else { return }
        
        // 安全删除最后一个数字
        let lastIndex = password.count - 1
        password[lastIndex] = 0  // 先清零
        password.removeLast()    // 再移除
        
        updateDigitViews()
        updateCursorPosition()
        delegate?.passwordInputViewDidChange(self, password: password)
    }
    
    func clearPassword() {
        secureClearPassword()
        updateDigitViews()
        updateCursorPosition()
        delegate?.passwordInputViewDidChange(self, password: password)
    }
    
    /// 安全清理密码数据
    private func secureClearPassword() {
        // 先将所有元素清零
        for i in 0..<password.count {
            password[i] = 0
        }
        // 再清空数组
        password.removeAll()
    }
    
    /// 安全验证密码（避免在内存中创建字符串）
    func validatePassword(validator: ([Int]) -> Bool) -> Bool {
        return validator(password)
    }
    
    private func updateDigitViews() {
        for (index, digitView) in digitViews.enumerated() {
            // 获取圆点标签
            guard let dotLabel = digitView.viewWithTag(100) as? UILabel else { continue }
            
            if index < password.count {
                // 显示圆点而不是实际数字（为了安全）
                dotLabel.text = "•"
                dotLabel.isHidden = false
                digitView.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                dotLabel.text = ""
                dotLabel.isHidden = true
                digitView.layer.borderColor = UIColor.lightGray.cgColor
            }
        }
    }
    
    // MARK: - 第一响应者
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        delegate?.passwordInputViewDidBeginEditing(self)
        updateCursorPosition()
        startCursorBlinking()
        return super.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        cursorLayer?.isHidden = true
        return super.resignFirstResponder()
    }
    
    // MARK: - 布局
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCursorPosition()
    }
    
    // MARK: - 内存安全
    
    /// 重写 removeFromSuperview 以确保安全清理
    override func removeFromSuperview() {
        secureClearPassword()
        super.removeFromSuperview()
    }
    
}
