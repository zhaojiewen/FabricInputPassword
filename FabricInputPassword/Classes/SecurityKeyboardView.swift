import UIKit

/// 安全键盘代理
protocol SecurityKeyboardViewDelegate: AnyObject {
    func securityKeyboardView(_ view: SecurityKeyboardView, didTapNumber number: Int)
    func securityKeyboardViewDidTapDelete(_ view: SecurityKeyboardView)
    func securityKeyboardViewDidTapClear(_ view: SecurityKeyboardView)
}

/// 安全数字键盘
class SecurityKeyboardView: UIView {
    
    // MARK: - 属性
    
    weak var delegate: SecurityKeyboardViewDelegate?
    
    private let buttonTitles = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["清除", "0", "删除"]
    ]
    
    private var buttons: [[UIButton]] = []
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI设置
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        
        // 创建按钮
        for rowTitles in buttonTitles {
            var rowButtons: [UIButton] = []
            for title in rowTitles {
                let button = createButton(with: title)
                rowButtons.append(button)
                addSubview(button)
            }
            buttons.append(rowButtons)
        }
        
        setupConstraints()
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
        
        // 添加点击效果
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
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
    
    // MARK: - 按钮动作
    
    @objc private func numberButtonTapped(_ sender: UIButton) {
        delegate?.securityKeyboardView(self, didTapNumber: sender.tag)
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
}
