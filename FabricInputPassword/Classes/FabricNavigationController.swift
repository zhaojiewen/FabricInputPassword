//
//  FabricNavigationController.swift
//  Pods
//
//  Created by 徐海青 on 2026/1/29.
//


class FabricNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
}
