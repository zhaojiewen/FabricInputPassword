//
//  ViewController.swift
//  FabricInputPassword
//
//  Created by haiqing.xu on 01/27/2026.
//  Copyright (c) 2026 haiqing.xu. All rights reserved.
//

import UIKit
import FabricInputPassword
import SwiftyRSA

class ViewController: UIViewController {
    
    // MARK: - UI组件
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "FabricInputPassword 示例"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
 
    private let asyncButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("异步验证（密码：888888）", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let windowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("使用新Window验证（密码：888888）", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let rsaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("RSA 加解密", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "等待测试..."
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - 生命周期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateResultLabel("点击按钮开始测试")
    }
    
    // MARK: - UI设置
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加标题
        view.addSubview(titleLabel)
        
        // 配置堆栈视图
        stackView.addArrangedSubview(asyncButton)
        stackView.addArrangedSubview(windowButton)
        stackView.addArrangedSubview(rsaButton)
        view.addSubview(stackView)
        
        // 添加结果标签
        view.addSubview(resultLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            asyncButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            windowButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            rsaButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            resultLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    // MARK: - 动作设置
    
    private func setupActions() {
        asyncButton.addTarget(self, action: #selector(asyncButtonTapped), for: .touchUpInside)
        windowButton.addTarget(self, action: #selector(windowButtonTapped), for: .touchUpInside)
        rsaButton.addTarget(self, action: #selector(rsaButtonTapped), for: .touchUpInside)

    }
    
    // MARK: - 按钮动作
  
    
    @objc private func asyncButtonTapped() {
        updateResultLabel("正在显示异步验证密码输入框...")
        
        FabricInputPassword.showPasswordInput(
            from: self,
            passwordLength: 6,
            title: "验证密码",
            subtitle: "请输入6位数字密码\n（测试密码：888888）",
            asyncValidator: { password, callback in
                // 模拟网络请求延迟
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // 模拟服务器验证
                    let isValid = password == "888888"
                    callback(isValid)
                }
            }
        ) { [weak self] password, isValid in
            if isValid {
                self?.updateResultLabel("✅ 异步验证成功！\n密码：\(password)", color: .systemGreen)
            } else {
                self?.updateResultLabel("❌ 异步验证失败！\n输入的密码：\(password)", color: .systemRed)
            }
        }
    }
    
    
    @objc private func windowButtonTapped() {
        updateResultLabel("正在显示新Window验证密码输入框...")
        FabricInputPassword.showInNewWindow(passwordLength: 6,
                                            title: "验证密码",
                                            subtitle: "请输入6位数字密码\n（测试密码：888888）",
                                            asyncValidator: { password, callback in
                                                // 模拟网络请求延迟
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                    // 模拟服务器验证
                                                    let isValid = password == "888888"
                                                    callback(isValid)
                                                }
                                            }
                                        ) { [weak self] password, isValid in
                                            if isValid {
                                                self?.updateResultLabel("✅ 异步验证成功！\n密码：\(password)", color: .systemGreen)
                                            } else {
                                                self?.updateResultLabel("❌ 异步验证失败！\n输入的密码：\(password)", color: .systemRed)
                                            }
                                        }
    }
    

    

    
    // MARK: - 辅助方法
    
    private func updateResultLabel(_ text: String, color: UIColor = .darkGray) {
        resultLabel.text = text
        resultLabel.textColor = color
        
        // 添加动画效果
        UIView.animate(withDuration: 0.2, animations: {
            self.resultLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.resultLabel.transform = .identity
            }
        }
    }
    
    
    @objc func rsaButtonTapped() {
        swiftRSA(content: "Hello, World!")
    }
    
    
    let pemPublic = """
        -----BEGIN PUBLIC KEY-----
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2yAwQj9J6QY5Q9SFnc7l
        Rs/LbUwgPZLgLl7WOiPGEXzmwimSPyoM4p3hNgac4yCQJLopvnHXdW1ytsMtKZe2
        UNtxthk946xLEh4on2oEzm7jLg0dyzvSMTDY29e9Oc6eQ+nTYX8HMTki54Cyn9qv
        VkEcMfJhTOXdPhgEjkviLUMaNCglD5UKVvUzxkDJEVCxAWKnayTxtwJQ5teNiS8k
        hWTgnQXpxaUYT9Xkm+6R6ColZ1URjOEGV61ika2BYF8avyBCwyhB/oKqM4Kv/i2z
        9awqvh9N0ehKJ9jFOOn7mhUb/4zyaTBat/yMBC9W2sf7QyyYMXSOQs3haK+38EXD
        DwIDAQAB
        -----END PUBLIC KEY-----
        """
    
    let pemPrivate = """
        -----BEGIN PRIVATE KEY-----
        MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDbIDBCP0npBjlD
        1IWdzuVGz8ttTCA9kuAuXtY6I8YRfObCKZI/KgzineE2BpzjIJAkuim+cdd1bXK2
        wy0pl7ZQ23G2GT3jrEsSHiifagTObuMuDR3LO9IxMNjb1705zp5D6dNhfwcxOSLn
        gLKf2q9WQRwx8mFM5d0+GASOS+ItQxo0KCUPlQpW9TPGQMkRULEBYqdrJPG3AlDm
        142JLySFZOCdBenFpRhP1eSb7pHoKiVnVRGM4QZXrWKRrYFgXxq/IELDKEH+gqoz
        gq/+LbP1rCq+H03R6Eon2MU46fuaFRv/jPJpMFq3/IwEL1bax/tDLJgxdI5CzeFo
        r7fwRcMPAgMBAAECggEASrwfuXh8bM2Cmm/RYpE+AXi9mPltxZJig241An9Q/oXq
        7i3fg0uEOYY/WX3H5G8mumAD/MA3DAXYKh1HOfhUZh9yGPli8lPBBtziXfx6xy1q
        rjoq/zXX6o8OZ2ydTSn7MI5/WbFJcrBaBzsNsReU1YY/Z4mTRfbgDl2CsEWRTn4C
        wK6MLkMkSvZGHYs1J8f4dgSu3LuchSAzv/rj1T2RvmU8z8KJNaBnE0OaLkWT2o0F
        JLGNfOCi83N680Tx8pnoFqcCOFdNYc7iKrb7d06uJ4+zMGaSKHQAdX3PcYhMxFGQ
        /K9T19qwZLWna3eG2qFLi4vmbHekYZrEW7crdnyzAQKBgQDz7HW/souTOY873LIi
        8NTDfGid8yRpn7zP/YeHb9mTCSDYk02/neLRdNmG4Q4RKwJKHD5UQc70iz02p9HM
        iseNDruVtqxqHNf8/nULleG0eoLvln/IynbWVjD8DpaBQzlnjhT/wvo5FIe7FKvy
        ce3iwODvTAAo+vKFkyM37aWNKQKBgQDl+W8t4BF/v9Hj5PX4jhm0AIURVRCNNqUO
        7Yr8kYey4hKb3QOPlQyH3fqQGittfwYkY+8h6lYOovM2pd+tmeZpZi/7Tct9zS98
        uCfGsdjawnhFmU86F1C7XGU1qCFJc0fx2hnAW0dyF5FDoxwyLKcU4VEienV8Q6bh
        iETEY6eddwKBgGQD+OP5WbGsUEbDX2dkSFk/kcXyBGQq00iVNBUcj6HyhD1JaP/A
        xVgNCYR8k0AG2pF4szXpJeqvjRH0DdpIrTnxaIkitd9spENgMq3lbv6JnVaP5yV1
        nvSTstInSR8HaWpEn+efEuqEuILFHxvyCxCG9bQo/YfQHdEXW8F69/7BAoGAbTLu
        rtrZlE5yDIN4pGhdHhKtHNjGfjc3UwpKV7mGtNMSQP5GJZSBmbY2ttwmSNzq/raR
        IwqRiGupjwZeWqFcPinumKaM/JREezU6deeW7/EtiObOLuhJRl4OFNdbzvO1csq8
        NZFiMHOuX26BAfYf9BM1ImkBhlrdT/QTqykiuusCgYAxSR/OsCCkhXpJ24sa9bk9
        6CltRHp7HXaOS6/CYR4WTWXDHFPMA/yIEsB3ggr7EU6Jyud7xwui6zP8vBr++ZKM
        GrStDJgncC4LWrBzh5U25BbNpagMccm0vQJ2VWf/ZKhyZ/BUk4kQRYpajG4E75Te
        f700sltzlQFnT5CODvgpzg==
        -----END PRIVATE KEY-----
        """
    
    
        let result = "GIMgpBPG+ue3ZoIfDQbQ7eHFlMmk3BNb8STXR9be4nahbQ+hW4Hw1oSfv7vXtP50V7yfRpaAFrRCAyrrnu87TikzIBKdM6nRlUkDHHGgDOu7I1gK4/bEReUHEFr1vshIe0CSW/aBntl5BnLO7WkTbiEMJBqvpwHhBmdn8v4wgjQbfivzE/ShC/IbBNHlFWicLghuGgmRDQkOoNe7kkYjTnle3lbWey50uIb42oKFKjd2IZNPT+D1cd4RceOfSXhK82T7nU6EmphllHwzO2j766h3FVyKF8D3OnorU5kZZT/FBOajfeCnU4I9VehSn+1IorJjW3/7+kHbf5VuFzLk8Q=="
    func rsaEnc(content: String) {
        
        
        do {
            let pubkey = try RSAKeyManager.importPublicKeyFromPEM(pemPublic)
            let encStr = try RSACrypto.smartEncrypt(content, publicKey: pubkey)
            updateResultLabel("加解密结果:\(result == encStr)")
        } catch let error {
            updateResultLabel("加解密错误：\(error)")
        }
        
                
    }
    
    func swiftRSA(content: String) {
        do {
            let pubkey = try RSAKeyManager.importPublicKeyFromPEM(pemPublic)
            let encStr = try RSACrypto.smartEncrypt(content, publicKey: pubkey)

            let base64String = encStr
            print(base64String)
            
            let privateKey = try PrivateKey(pemEncoded: pemPrivate)
            let re = try EncryptedMessage(base64Encoded: base64String)
            let clearP = try re.decrypted(with: privateKey, padding: .PKCS1)

            // Then you can use:
            let stringp = try clearP.string(encoding: .utf8)
            updateResultLabel("加解密结果:\(stringp == content)")


        } catch let error {
            updateResultLabel("加解密错误：\(error)")
        }
    }
}
