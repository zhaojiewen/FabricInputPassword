import UIKit

/// 异步密码验证回调
public typealias AsyncPasswordValidator = (String, @escaping (Bool, String?) -> Void) -> Void
/// 忘记密码点击回调
public typealias ForgotPasswordHandler = () -> Void
/// 关闭按钮点击回调
public typealias CloseButtonHandler = () -> Void
/// 背景点击回调
public typealias BackgroundTapHandler = () -> Void

/// 密码输入视图控制器
public class PasswordInputViewController: UIViewController {
    
    // MARK: - 属性
    
    private let passwordLength: Int
    private let titleText: String?
    private let subtitleText: String?
    
    public var asyncValidator: AsyncPasswordValidator?
    public var forgotPasswordHandler: ForgotPasswordHandler?
    public var closeButtonHandler: CloseButtonHandler?
    public var backgroundTapHandler: BackgroundTapHandler?
    
    private var passwordInputView: PasswordInputView!
    private var keyboardView: SecurityKeyboardView!
    private var isVerifying = false {
        didSet {
            /// 验证过程中，静止操作键盘
            keyboardView.isUserInteractionEnabled = !isVerifying
        }
    }
    
    // MARK: - 窗口显示相关属性
    private var customWindow: UIWindow?
    private var isPresentedInWindow = false
    
    // MARK: - UI组件
    
    private lazy var containerView: UIView = {
        let view = self.securityView
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // 只圆角顶部两个角
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let securityView: UIView  = {
        let field = UITextField()
        field.isSecureTextEntry = true
        guard let view = field.subviews.first else {
            return UIView()
        }
        view.subviews.forEach { $0.removeFromSuperview() }
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.isHidden = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "xmark"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        button.tintColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .red
        label.textAlignment = .center
        label.numberOfLines = 1
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("忘记密码？", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - 窗口显示方法
    
    /// 在新窗口中显示密码输入界面
    /// - Parameters:
    ///   - windowLevel: 窗口层级，默认为 .alert + 1，确保在最上层
    ///   - completion: 完成回调
    public func showInNewWindow(windowLevel: UIWindow.Level = UIWindowLevelStatusBar + 1, completion: (() -> Void)? = nil) {
        guard customWindow == nil else {
            print("PasswordInputViewController is already shown in a window")
            return
        }
        
        // 创建 FabricNavigationController
        let navi = FabricNavigationController(rootViewController: self)
        
        // 创建新窗口
        if #available(iOS 13.0, *) {
            // iOS 13+ 使用场景
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                customWindow = UIWindow(windowScene: windowScene)
            } else {
                customWindow = UIWindow(frame: UIScreen.main.bounds)
            }
        } else {
            // iOS 12 及以下
            customWindow = UIWindow(frame: UIScreen.main.bounds)
        }
        
        guard let window = customWindow else { return }
        
        // 配置窗口
        window.windowLevel = windowLevel
        window.backgroundColor = .clear
        window.rootViewController = navi
        window.isHidden = false
        window.makeKeyAndVisible()
        
        isPresentedInWindow = true
        
        completion?()
    }
    
    
    // MARK: - 初始化
    
    /// 初始化密码输入视图控制器
    /// - Parameters:
    ///   - passwordLength: 密码长度，默认为6
    ///   - title: 标题
    ///   - subtitle: 副标题
    ///   - completion: 完成回调，返回输入的密码和验证结果
    public init(passwordLength: Int = 6,
                title: String? = "请输入密码",
                subtitle: String? = nil) {
        self.passwordLength = passwordLength
        self.titleText = title
        self.subtitleText = subtitle
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命周期
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 初始位置：在屏幕下方
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        
        // 背景初始透明
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 执行从下到上的动画
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            // 容器视图从下方滑入
            self.containerView.transform = .identity
            
            // 背景渐变显示
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        } completion: { _ in
            // 动画完成后，让密码输入视图成为第一响应者
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.passwordInputView.becomeFirstResponder()
            }
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 执行从上到下的消失动画
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            // 容器视图滑出到屏幕下方
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            
            // 背景渐变消失
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        }
        
        // 视图消失时停止光标闪烁
        passwordInputView.resignFirstResponder()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 确保键盘视图在布局变化后正确显示
        keyboardView.layoutIfNeeded()
    }
    
    // MARK: - 设置UI
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        
        // 添加容器视图
        view.addSubview(containerView)
        
        // 添加标题
        titleLabel.text = titleText
        containerView.addSubview(titleLabel)
        
        // 添加副标题
        if let subtitle = subtitleText {
            subtitleLabel.text = subtitle
            containerView.addSubview(subtitleLabel)
        }
        
        // 添加关闭按钮
        containerView.addSubview(closeButton)
        
        // 添加错误标签
        containerView.addSubview(errorLabel)
        
        // 添加忘记密码按钮
        containerView.addSubview(forgotPasswordButton)
        
        // 添加活动指示器
        containerView.addSubview(activityIndicator)
        
        // 添加密码输入视图
        passwordInputView = PasswordInputView(length: passwordLength)
        passwordInputView.delegate = self
        containerView.addSubview(passwordInputView)
        
        // 添加安全键盘
        keyboardView = SecurityKeyboardView()
        keyboardView.delegate = self
        containerView.addSubview(keyboardView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 容器视图约束 - 宽度等于屏幕宽度，高度为屏幕高度的60%
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            
            // 关闭按钮约束
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            // 标题约束
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
        ])
        
        // 根据是否有副标题调整密码输入视图的位置
        let passwordTopAnchor: NSLayoutYAxisAnchor
        if subtitleText != nil {
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32).isActive = true
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32).isActive = true
            passwordTopAnchor = subtitleLabel.bottomAnchor
        } else {
            passwordTopAnchor = titleLabel.bottomAnchor
        }
        
        NSLayoutConstraint.activate([
            // 错误标签约束
            errorLabel.topAnchor.constraint(equalTo: passwordTopAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            errorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            
            // 密码输入视图约束
            passwordInputView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16),
            passwordInputView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            passwordInputView.widthAnchor.constraint(equalToConstant: CGFloat(passwordLength * 44 + (passwordLength - 1) * 12)),
            passwordInputView.heightAnchor.constraint(equalToConstant: 44),
            
            // 忘记密码按钮约束 - 在密码输入视图右下角
            forgotPasswordButton.trailingAnchor.constraint(equalTo: passwordInputView.trailingAnchor),
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordInputView.bottomAnchor, constant: 12),
            
            // 活动指示器约束 - 在密码输入视图旁边
            activityIndicator.centerYAnchor.constraint(equalTo: passwordInputView.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: passwordInputView.centerXAnchor),

            // 键盘约束 - 使用灵活的高度约束
            keyboardView.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 16),
            keyboardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            keyboardView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            keyboardView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }
    
    // MARK: - 设置动作
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
    }
    
    // MARK: - 动作处理
    
    @objc private func closeButtonTapped() {
        if let closeHandler = closeButtonHandler {
            closeHandler()
        } else {
            hide()
        }
    }
    
    @objc private func forgotPasswordTapped() {
        if let forgotHandler = forgotPasswordHandler {
            forgotHandler()
        }
    }
    
    
    public func hide() {
        if isPresentedInWindow {
            dismissFromWindow()
        } else {
            dismissWithAnimation()
        }
    }
    
    /// 关闭窗口显示
    private func dismissFromWindow() {
        guard isPresentedInWindow, let window = customWindow else { return }
        
        dismissWithAnimation { [weak self] in
            guard let self else { return }
            window.isHidden = true
            window.rootViewController = nil
            self.customWindow = nil
            self.isPresentedInWindow = false
        }
    }
    
    private func dismissWithAnimation(complete: (() -> Void)? = nil) {
        // 执行从上到下的消失动画
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            // 容器视图滑出到屏幕下方
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            
            // 背景渐变消失
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        } completion: { _ in
            // 动画完成后真正 dismiss
            self.dismiss(animated: false, completion: nil)
            complete?()
        }
    }
    
    // MARK: - 显示错误
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        
        // 添加抖动动画
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: "linear")
        animation.duration = 0.6
        animation.values = [-10, 10, -10, 10, -5, 5, -2, 2, 0]
        passwordInputView.layer.add(animation, forKey: "shake")
        
        // 清空密码
        passwordInputView.clearPassword()
        
        // 3秒后隐藏错误信息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.errorLabel.isHidden = true
        }
    }
    
    // MARK: - 验证密码
    
    private func validatePassword(_ password: String) {
        guard !isVerifying else { return }
        
        isVerifying = true
        activityIndicator.startAnimating()
        passwordInputView.isUserInteractionEnabled = false
        keyboardView.isUserInteractionEnabled = false
        
        if let asyncValidator = asyncValidator {
            // 使用异步验证器
            asyncValidator(password) { [weak self] isValid, message in
                DispatchQueue.main.async {
                    self?.handleValidationResult(isValid: isValid, message: message)
                }
            }
        } 
    }
    
    private func handleValidationResult(isValid: Bool, message: String?) {
        isVerifying = false
        activityIndicator.stopAnimating()
        passwordInputView.isUserInteractionEnabled = true
        keyboardView.isUserInteractionEnabled = true
        
        if isValid {
            // 验证成功
            hide()
        } else {
            // 验证失败
            showError(message ?? "密码输入错误")
        }
    }
}

// MARK: - PasswordInputViewDelegate

extension PasswordInputViewController: PasswordInputViewDelegate {
    func passwordInputView(_ view: PasswordInputView, didEnterPassword password: [Int]) {
        if password.count == passwordLength {
            // 密码输入完成，开始验证
            validatePassword(getPasswordString(password))
        }
    }
    
    /// 获取密码字符串（仅在需要时转换）
    func getPasswordString(_ password: [Int]) -> String {
        return password.map { String($0) }.joined()
    }
    
    func passwordInputViewDidBeginEditing(_ view: PasswordInputView) {
        // 隐藏错误信息
        errorLabel.isHidden = true
    }
    
    func passwordInputViewDidChange(_ view: PasswordInputView, password: [Int]) {
        // 密码变化时更新UI
        // 可以在这里添加实时验证逻辑
    }
}

// MARK: - SecurityKeyboardViewDelegate

extension PasswordInputViewController: SecurityKeyboardViewDelegate {
    func securityKeyboardView(_ view: SecurityKeyboardView, didTapNumber number: Int) {
        passwordInputView.appendNumber(number)
    }
    
    func securityKeyboardViewDidTapDelete(_ view: SecurityKeyboardView) {
        passwordInputView.deleteLastNumber()
    }
    
    func securityKeyboardViewDidTapClear(_ view: SecurityKeyboardView) {
        passwordInputView.clearPassword()
    }
}


