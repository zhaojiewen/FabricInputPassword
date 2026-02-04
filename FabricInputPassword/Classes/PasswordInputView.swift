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
        
        // 只设置下边框
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1).cgColor
        bottomBorder.frame = CGRect(x: 0, y: 43, width: 44, height: 2) // 初始值，会在layoutSubviews中更新
        bottomBorder.name = "bottomBorder"
        container.layer.addSublayer(bottomBorder)
        
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加数字标签（用于显示输入的数字）
        let numberLabel = UILabel()
        numberLabel.font = UIFont.systemFont(ofSize: 30, weight: .semibold)
        numberLabel.textColor = .black
        numberLabel.textAlignment = .center
        numberLabel.isHidden = true
        numberLabel.tag = 101 // 用于标识数字标签
        container.addSubview(numberLabel)
        
        // 添加圆点标签（用于代替数字）
        let dotLabel = UILabel()
        dotLabel.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        dotLabel.textColor = .black
        dotLabel.textAlignment = .center
        dotLabel.isHidden = true
        dotLabel.tag = 100 // 用于标识圆点标签
        container.addSubview(dotLabel)
        
        // 数字标签约束
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            numberLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        // 圆点标签约束
        dotLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dotLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dotLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func setupConstraints() {
        // 设置间距
        let spacing: CGFloat = 21
        
        for (index, digitView) in digitViews.enumerated() {
            NSLayoutConstraint.activate([
                // 高度等于父视图高度
                digitView.topAnchor.constraint(equalTo: topAnchor),
                digitView.bottomAnchor.constraint(equalTo: bottomAnchor),
                digitView.heightAnchor.constraint(equalTo: heightAnchor),
            ])
            
            if index == 0 {
                // 第一个视图：左对齐
                digitView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                // 其他视图：与前一个视图保持间距
                digitView.leadingAnchor.constraint(equalTo: digitViews[index - 1].trailingAnchor, constant: spacing).isActive = true
            }
            
            if index == length - 1 {
                // 最后一个视图：右对齐
                digitView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
            
            // 所有视图等宽
            if index > 0 {
                digitView.widthAnchor.constraint(equalTo: digitViews[0].widthAnchor).isActive = true
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
        
        // 获取当前输入的位置
        let currentIndex = password.count
        
        password.append(number)
        updateDigitViewsForInput(at: currentIndex)
        updateCursorPosition()
        delegate?.passwordInputViewDidChange(self, password: password)
        
        // 当前输入的位置边框变为黑色
        updateBorderColorForIndex(currentIndex, isActive: true)
        
        if password.count == length {
            // 所有位置都输入完成后，延迟一小段时间后回调
            let securityCopyPassword = Array(password)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.delegate?.passwordInputView(self, didEnterPassword: securityCopyPassword)
            }
        }
    }
    
    func deleteLastNumber() {
        guard !password.isEmpty else { return }
        
        // 获取要删除的位置
        let deleteIndex = password.count - 1
        
        // 安全删除最后一个数字
        password[deleteIndex] = 0  // 先清零
        password.removeLast()    // 再移除
        
        // 删除操作：直接清空显示，不显示数字
        updateDigitViewsForDelete(at: deleteIndex)
        updateCursorPosition()
        delegate?.passwordInputViewDidChange(self, password: password)
        
        // 删除后，该位置的边框恢复为浅灰色
        updateBorderColorForIndex(deleteIndex, isActive: false)
    }
    
    func clearPassword() {
        // 将所有位置的边框恢复为浅灰色
        for i in 0..<password.count {
            updateBorderColorForIndex(i, isActive: false)
        }
        
        secureClearPassword()
        updateDigitViewsForClear()
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
    
    /// 更新数字显示 - 用于输入操作
    private func updateDigitViewsForInput(at index: Int) {
        guard index >= 0 && index < digitViews.count else { return }
        
        // 更新之前所有已输入的位置为圆点
        for i in 0..<index {
            updateDigitViewForIndex(i, showNumber: false)
        }
        
        // 当前输入的位置：先显示数字，然后变成圆点
        updateDigitViewForIndex(index, showNumber: true)
    }
    
    /// 更新数字显示 - 用于删除操作
    private func updateDigitViewsForDelete(at index: Int) {
        guard index >= 0 && index < digitViews.count else { return }
        
        // 删除的位置：直接清空，不显示数字
        updateDigitViewForIndex(index, showNumber: false, clearImmediately: true)
    }
    
    /// 更新数字显示 - 用于清除操作
    private func updateDigitViewsForClear() {
        // 所有位置都清空
        for i in 0..<digitViews.count {
            updateDigitViewForIndex(i, showNumber: false, clearImmediately: true)
        }
    }
    
    /// 更新指定位置的显示
    private func updateDigitViewForIndex(_ index: Int, showNumber: Bool, clearImmediately: Bool = false) {
        guard index >= 0 && index < digitViews.count else { return }
        
        let digitView = digitViews[index]
        guard let numberLabel = digitView.viewWithTag(101) as? UILabel,
              let dotLabel = digitView.viewWithTag(100) as? UILabel else { return }
        
        if index < password.count {
            if showNumber && index == password.count - 1 {
                // 输入操作：显示数字然后变成圆点
                let number = password[index]
                numberLabel.text = "\(number)"
                numberLabel.isHidden = false
                dotLabel.isHidden = true
                
                // 延迟0.1秒后显示圆点
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 再次检查是否还是当前这个位置
                    if index < self.password.count && index == self.password.count - 1 {
                        numberLabel.isHidden = true
                        dotLabel.text = "•"
                        dotLabel.isHidden = false
                    }
                }
            } else {
                // 其他情况：直接显示圆点或清空
                if clearImmediately {
                    // 删除或清除操作：直接清空
                    numberLabel.text = ""
                    numberLabel.isHidden = true
                    dotLabel.text = ""
                    dotLabel.isHidden = true
                } else {
                    // 之前已输入的位置：显示圆点
                    numberLabel.isHidden = true
                    dotLabel.text = "•"
                    dotLabel.isHidden = false
                }
            }
        } else {
            // 未输入的位置：清空显示
            numberLabel.text = ""
            numberLabel.isHidden = true
            dotLabel.text = ""
            dotLabel.isHidden = true
        }
    }
    
    /// 更新指定位置的边框颜色
    private func updateBorderColorForIndex(_ index: Int, isActive: Bool) {
        guard index >= 0 && index < digitViews.count else { return }
        
        let digitView = digitViews[index]
        if let sublayers = digitView.layer.sublayers {
            for layer in sublayers where layer.name == "bottomBorder" {
                layer.backgroundColor = isActive ? 
                    UIColor.black.cgColor : 
                    UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1).cgColor
            }
        }
    }
    
    /// 更新边框颜色为正常状态（浅灰色）
    private func updateBorderColorsForNormalState() {
        for digitView in digitViews {
            if let sublayers = digitView.layer.sublayers {
                for layer in sublayers where layer.name == "bottomBorder" {
                    layer.backgroundColor = UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1).cgColor
                }
            }
        }
    }
    
    /// 更新边框颜色为完成状态（黑色）
    private func updateBorderColorsForCompletedState() {
        for digitView in digitViews {
            if let sublayers = digitView.layer.sublayers {
                for layer in sublayers where layer.name == "bottomBorder" {
                    layer.backgroundColor = UIColor.black.cgColor
                }
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
        
        // 更新边框位置
        for digitView in digitViews {
            if let sublayers = digitView.layer.sublayers {
                for layer in sublayers where layer.name == "bottomBorder" {
                    layer.frame = CGRect(x: 0, y: digitView.bounds.height - 2, width: digitView.bounds.width, height: 2)
                }
            }
        }
    }
    
    // MARK: - 内存安全
    
    /// 重写 removeFromSuperview 以确保安全清理
    override func removeFromSuperview() {
        clearPassword()
        super.removeFromSuperview()
    }
    
}
