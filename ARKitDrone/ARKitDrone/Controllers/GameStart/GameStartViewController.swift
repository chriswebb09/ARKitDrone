//
//  GameStartViewController.swift
//  Multiplayer_test
//
//  Created by Shawn Ma on 10/1/18.
//  Copyright © 2018 Shawn Ma. All rights reserved.
//

import UIKit
import Foundation
import os.log

class GameStartViewController: UIViewController {
    
    weak var delegate: GameStartViewControllerDelegate?
    
    var gameBrowser: GameBrowser?
    
    private let myself = UserDefaults.standard.myself
    
    let hostButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 78/255, green: 142/255, blue: 240/255, alpha: 1.0)
        button.setTitle("Host", for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
    }()
    
    let joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 78/255, green: 142/255, blue: 240/255, alpha: 1.0)
        button.setTitle("Join", for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
    }()
    
    let soloButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 78/255, green: 142/255, blue: 240/255, alpha: 1.0)
        button.setTitle("Solo Game", for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
    }()
    
    var browserContainerView: UIView!
    let browserController = NetworkGameBrowserViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(hostButton)
        view.addSubview(joinButton)
        view.addSubview(soloButton)
        gameBrowser = GameBrowser(myself: myself)
        browserController.browser = gameBrowser
        addChild(browserController)
        browserContainerView = browserController.view
        view.addSubview(browserContainerView)
        browserContainerView.isHidden = true
        view.backgroundColor = .white
        setupButtons()
        setupBrowserView()
    }
    
    func setupButtons() {
        hostButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hostButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            hostButton.widthAnchor.constraint(equalToConstant: 150),
            hostButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        hostButton.addTarget(self, action: #selector(hostButtonPressed), for: .touchUpInside)

        joinButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            joinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            joinButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            joinButton.widthAnchor.constraint(equalToConstant: 150),
            joinButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        joinButton.addTarget(self, action: #selector(joinButtonPressed), for: .touchUpInside)
        
        soloButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            soloButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            soloButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -250),
            soloButton.widthAnchor.constraint(equalToConstant: 150),
            soloButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        soloButton.addTarget(self, action: #selector(soloButtonPressed), for: .touchUpInside)

    }
    
    func setupBrowserView() {        
        browserContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            browserContainerView.widthAnchor.constraint(equalToConstant: 300),
            browserContainerView.heightAnchor.constraint(equalToConstant: 300),
            browserContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            browserContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func joinGame(session: NetworkSession) {
        delegate?.gameStartViewController(self, didSelect: session)
        setupOverlayVC()
    }
    
    func setupOverlayVC() {
        showViews(forSetup: true)
    }
    
    func showViews(forSetup: Bool) {
        UIView.transition(with: view, duration: 1.0, options: [.transitionCrossDissolve], animations: {
            self.joinButton.isHidden = !forSetup
            self.hostButton.isHidden = !forSetup
        }, completion: nil)
    }
    
    @objc func soloButtonPressed(button: UIButton) {
        delegate?.gameStartViewController(self, didPressStartSoloGameButton: button)
    }
    
    @objc func hostButtonPressed() {
        startGame(with: myself)
    }
    
    @objc func joinButtonPressed() {
        gameBrowser?.refresh()
        DispatchQueue.main.async {
            self.browserContainerView.isHidden = false
        }
    }
    
    func startGame(with player: Player) {
        let gameSession = NetworkSession(myself: player, asServer: true, host: myself)
        delegate?.gameStartViewController(self, didStart: gameSession)
        setupOverlayVC()
    }
    
}
