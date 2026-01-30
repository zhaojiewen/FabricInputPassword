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
    
    private let devButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("测试环境验证密码", for: .normal)
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
        stackView.addArrangedSubview(devButton)
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
            devButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            asyncButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            windowButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            resultLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    // MARK: - 动作设置
    
    private func setupActions() {
        devButton.addTarget(self, action: #selector(devButtonTapped), for: .touchUpInside)

        asyncButton.addTarget(self, action: #selector(asyncButtonTapped), for: .touchUpInside)
        windowButton.addTarget(self, action: #selector(windowButtonTapped), for: .touchUpInside)

    }
    
    // MARK: - 按钮动作
    
    
    @objc func devButtonTapped() {
        FabricInputPassword.verify(merId: "11000001234", merSysId: "sys001", merUserId: "user001", merOrderId: "T2026012913141234", tranAmt: "8.88") { token in
            // 此时密码已经验证成功，可以用token走后续支付流程
        }
    }
    
      
    @objc private func asyncButtonTapped() {
        updateResultLabel("正在显示验证密码输入框...")
        
        FabricInputPassword.showPasswordInput(
            from: self,
            passwordLength: 6,
            title: "验证密码",
            subtitle: "请输入6位数字密码\n（测试密码：888888）",
            asyncValidator: { [weak self] password, callback in
                // 模拟网络请求延迟
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // 模拟服务器验证
                    let isValid = password == "888888"
                    callback(isValid, nil)
                    
                    if isValid {
                        self?.updateResultLabel("✅ 验证成功！", color: .systemGreen)
                    } else {
                        self?.updateResultLabel("❌ 验证失败！", color: .systemRed)
                    }
                }
            }
        )
    }
    
    
    @objc private func windowButtonTapped() {
        updateResultLabel("正在显示验证密码输入框...")
        FabricInputPassword.showInNewWindow(passwordLength: 6,
                                            title: "验证密码",
                                            subtitle: "请输入6位数字密码\n（测试密码：888888）",
                                            asyncValidator: {[weak self]  password, callback in
                                                // 模拟网络请求延迟
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                    // 模拟服务器验证
                                                    let isValid = password == "888888"
                                                    callback(isValid, nil)

                                                    if isValid {
                                                        self?.updateResultLabel("✅ 验证成功！", color: .systemGreen)
                                                    } else {
                                                        self?.updateResultLabel("❌ 验证失败！", color: .systemRed)
                                                    }
                                                }
                                            }
                                        )
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
    
    
}
