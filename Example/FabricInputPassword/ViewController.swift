//
//  ViewController.swift
//  FabricInputPassword
//
//  Created by haiqing.xu on 01/27/2026.
//  Copyright (c) 2026 haiqing.xu. All rights reserved.
//

import UIKit
import FabricInputPassword

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
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 输入字段
    private let merIdTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "商户ID (merId)"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let merSysIdTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "商户系统ID (merSysId)"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let merUserIdTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "商户用户ID (merUserId)"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let merOrderIdTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "商户订单ID (merOrderId)"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .default
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let tranAmtTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "交易金额 (tranAmt)"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    
    private let customTestButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("自定义参数验证", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let fillDefaultButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("填充默认测试数据", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.setTitleColor(.systemBlue, for: .normal)
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
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - 生命周期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupTapGesture()
        fillDefaultData()
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
        
        // 添加滚动视图
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 配置堆栈视图
        contentView.addSubview(stackView)
        
        // 添加输入字段到堆栈视图
        let inputFields = [
            createInputFieldWithLabel("商户ID:", textField: merIdTextField),
            createInputFieldWithLabel("商户系统ID:", textField: merSysIdTextField),
            createInputFieldWithLabel("商户用户ID:", textField: merUserIdTextField),
            createInputFieldWithLabel("商户订单ID:", textField: merOrderIdTextField),
            createInputFieldWithLabel("交易金额:", textField: tranAmtTextField)
        ]
        
        for field in inputFields {
            stackView.addArrangedSubview(field)
        }
        
        // 添加填充默认数据按钮
        stackView.addArrangedSubview(fillDefaultButton)
        
        // 添加按钮
        stackView.addArrangedSubview(customTestButton)
        
        // 添加结果标签
        contentView.addSubview(resultLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 标题
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 滚动视图
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // 内容视图
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // 堆栈视图
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 按钮宽度
            customTestButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 结果标签
            resultLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 30),
            resultLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            resultLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createInputFieldWithLabel(_ labelText: String, textField: UITextField) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        
        let label = UILabel()
        label.text = labelText
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .darkGray
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(textField)
        
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return stackView
    }
    
    // MARK: - 动作设置
    
    private func setupActions() {
        customTestButton.addTarget(self, action: #selector(customTestButtonTapped), for: .touchUpInside)
        fillDefaultButton.addTarget(self, action: #selector(fillDefaultButtonTapped), for: .touchUpInside)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - 按钮动作
    
    @objc func customTestButtonTapped() {
        dismissKeyboard()
        
        // 获取用户输入的参数
        guard let merId = merIdTextField.text, !merId.isEmpty else {
            showAlert("请输入商户ID")
            return
        }
        
        guard let merSysId = merSysIdTextField.text, !merSysId.isEmpty else {
            showAlert("请输入商户系统ID")
            return
        }
        
        guard let merUserId = merUserIdTextField.text, !merUserId.isEmpty else {
            showAlert("请输入商户用户ID")
            return
        }
        
        guard let merOrderId = merOrderIdTextField.text, !merOrderId.isEmpty else {
            showAlert("请输入商户订单ID")
            return
        }
        
        guard let tranAmt = tranAmtTextField.text, !tranAmt.isEmpty else {
            showAlert("请输入交易金额")
            return
        }
        
        // 验证交易金额格式
        if Double(tranAmt) == nil {
            showAlert("交易金额格式不正确")
            return
        }
        
        updateResultLabel("正在使用自定义参数验证...")
        
        FabricInputPassword.verify(merId: merId,
                                   merSysId: merSysId,
                                   merUserId: merUserId,
                                   merOrderId: merOrderId,
                                   tranAmt: tranAmt) { token in
            DispatchQueue.main.async {
                self.updateResultLabel("✅ 验证成功！\nToken: \(token)", color: .systemGreen)
            }
        }
    }
    
    @objc func fillDefaultButtonTapped() {
        fillDefaultData()
        updateResultLabel("已填充默认测试数据")
    }
    
    // MARK: - 辅助方法
    
    private func fillDefaultData() {
        merIdTextField.text = "11000001234"
        merSysIdTextField.text = "sys001"
        merUserIdTextField.text = "user001"
        merOrderIdTextField.text = "T2026012913141234"
        tranAmtTextField.text = "8.88"
    }
    
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
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
