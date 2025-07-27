import UIKit

class IntroViewController: UIViewController {
    
    let startButton = UIButton(type: .system)
    var badges: [Badge] = [
        Badge(percent: 10, emoji: "10%", earned: false),
        Badge(percent: 25, emoji: "25%", earned: false),
        Badge(percent: 50, emoji: "50%", earned: false),
        Badge(percent: 75, emoji: "75%", earned: false),
        Badge(percent: 100, emoji: "100%", earned: false)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupStartButton()
        addWelcomeTitle()
        displayEarnedBadges()
    }
    
    func addWelcomeTitle() {
        let titleLabel = UILabel()
        titleLabel.text = "Welcome to Central Park Explorer"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .blue
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 300)
        ])
    }

    func setupStartButton() {
        startButton.setTitle("Start Exploring", for: .normal)
        startButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
            startButton.widthAnchor.constraint(equalToConstant: 220),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func displayEarnedBadges() {
        let earnedPercents = UserDefaults.standard.array(forKey: "earnedMilestones") as? [Int] ?? []
        let earnedBadges = badges.filter { earnedPercents.contains($0.percent) }
        
        let badgeStack = UIStackView()
        badgeStack.axis = .horizontal
        badgeStack.spacing = 10
        badgeStack.distribution = .equalSpacing
        badgeStack.translatesAutoresizingMaskIntoConstraints = false
        
        for badge in earnedBadges {
            let label = UILabel()
            label.text = badge.emoji
            label.font = .systemFont(ofSize: 40)
            badgeStack.addArrangedSubview(label)
        }
        
        view.addSubview(badgeStack)
        NSLayoutConstraint.activate([
            badgeStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            badgeStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30)
        ])
    }

    @objc func startTapped() {
        let vc = ViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
