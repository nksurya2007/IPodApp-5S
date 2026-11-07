import UIKit
import MediaPlayer

struct Row {
    let title: String
    var detail: String? = nil
    var arrow = false
    let action: () -> Void
}

struct Menu {
    let title: String
    var rows: [Row]
    var sel = 0
}

struct Theme {
    let name: String
    let body: UIColor
    let screen: UIColor
    let border: UIColor
    let bar: UIColor
    let barText: UIColor
    let text: UIColor
    let subtext: UIColor
    let selBg: UIColor
    let selText: UIColor
    let dark: Bool

    static let all: [Theme] = [
        Theme(name: "Classic",
              body: UIColor(white: 0.93, alpha: 1),
              screen: .white,
              border: .darkGray,
              bar: UIColor(white: 0.82, alpha: 1),
              barText: .black,
              text: .black,
              subtext: .gray,
              selBg: UIColor(red: 0.10, green: 0.45, blue: 0.82, alpha: 1),
              selText: .white,
              dark: false),
        Theme(name: "Dark",
              body: UIColor(white: 0.10, alpha: 1),
              screen: UIColor(white: 0.07, alpha: 1),
              border: UIColor(white: 0.35, alpha: 1),
              bar: UIColor(white: 0.20, alpha: 1),
              barText: .white,
              text: .white,
              subtext: UIColor(white: 0.60, alpha: 1),
              selBg: UIColor(red: 0.10, green: 0.55, blue: 0.95, alpha: 1),
              selText: .white,
              dark: true),
        Theme(name: "Green",
              body: UIColor(red: 0.85, green: 0.93, blue: 0.85, alpha: 1),
              screen: UIColor(red: 0.93, green: 0.98, blue: 0.93, alpha: 1),
              border: UIColor(red: 0.20, green: 0.40, blue: 0.20, alpha: 1),
              bar: UIColor(red: 0.70, green: 0.86, blue: 0.70, alpha: 1),
              barText: UIColor(red: 0.05, green: 0.20, blue: 0.05, alpha: 1),
              text: UIColor(red: 0.05, green: 0.20, blue: 0.05, alpha: 1),
              subtext: UIColor(red: 0.30, green: 0.45, blue: 0.30, alpha: 1),
              selBg: UIColor(red: 0.15, green: 0.55, blue: 0.25, alpha: 1),
              selText: .white,
              dark: false),
        Theme(name: "Rose",
              body: UIColor(red: 0.98, green: 0.90, blue: 0.92, alpha: 1),
              screen: UIColor(red: 1.00, green: 0.97, blue: 0.98, alpha: 1),
              border: UIColor(red: 0.60, green: 0.30, blue: 0.40, alpha: 1),
              bar: UIColor(red: 0.95, green: 0.75, blue: 0.82, alpha: 1),
              barText: UIColor(red: 0.25, green: 0.05, blue: 0.12, alpha: 1),
              text: UIColor(red: 0.25, green: 0.05, blue: 0.12, alpha: 1),
              subtext: UIColor(red: 0.55, green: 0.35, blue: 0.42, alpha: 1),
              selBg: UIColor(red: 0.85, green: 0.25, blue: 0.45, alpha: 1),
              selText: .white,
              dark: false)
    ]
}

final class iPodViewController: UIViewController, UITableViewDataSource {
    private let player = MPMusicPlayerController.systemMusicPlayer
    private var stack: [Menu] = []
    private var inNowPlaying = false

    private var themeIndex: Int = min(max(UserDefaults.standard.integer(forKey: "themeIndex"), 0),
                                      Theme.all.count - 1)
    private var wheelIndex: Int = min(max(UserDefaults.standard.integer(forKey: "wheelIndex"), 0),
                                      WheelStyle.all.count - 1)
    private var theme: Theme { return Theme.all[themeIndex] }

    private let screen = UIView()
    private let bar = UIView()
    private let titleLabel = UILabel()
    private let indicator = UILabel()
    private let table = UITableView()
    private let npView = UIView()
    private let art = UIImageView()
    private let npTitle = UILabel()
    private let npArtist = UILabel()
    private let progress = UIProgressView(progressViewStyle: .default)
    private let t1 = UILabel()
    private let t2 = UILabel()
    private let wheel = ClickWheel()
    private var timer: Timer?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.dark ? .lightContent : .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        applyTheme()
        wireWheel()
        wheel.style = WheelStyle.all[wheelIndex]

        player.beginGeneratingPlaybackNotifications()
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(updateNP),
                       name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        nc.addObserver(self, selector: #selector(updateNP),
                       name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player)
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateNP),
                                     userInfo: nil, repeats: true)

        MPMediaLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if status == .authorized {
                    self.stack = [self.mainMenu()]
                } else {
                    self.stack = [Menu(title: "iPod", rows: [
                        Row(title: "Allow Music access", detail: "Settings") { [weak self] in
                            self?.openSystemSettings()
                        },
                        Row(title: "Settings", arrow: true) { [weak self] in
                            guard let self = self else { return }
                            self.push(self.settingsMenu())
                        }])]
                }
                self.render()
            }
        }
    }

    // MARK: UI
    private func buildUI() {
        let g = view.safeAreaLayoutGuide
        [screen, wheel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        screen.layer.borderWidth = 3
        screen.layer.cornerRadius = 8
        screen.clipsToBounds = true

        titleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        indicator.font = UIFont.boldSystemFont(ofSize: 12)
        indicator.textAlignment = .right
        table.dataSource = self
        table.rowHeight = 26
        table.isUserInteractionEnabled = false
        table.separatorStyle = .none
        table.tableFooterView = UIView()
        npView.isHidden = true

        art.contentMode = .scaleAspectFit
        npTitle.font = UIFont.boldSystemFont(ofSize: 16)
        npArtist.font = UIFont.systemFont(ofSize: 13)
        [npTitle, npArtist].forEach { $0.textAlignment = .center }
        [t1, t2].forEach { $0.font = UIFont.systemFont(ofSize: 11) }
        t2.textAlignment = .right

        let times = UIStackView(arrangedSubviews: [t1, t2])
        times.distribution = .fillEqually
        let col = UIStackView(arrangedSubviews: [art, npTitle, npArtist, progress, times])
        col.axis = .vertical
        col.spacing = 5
        col.translatesAutoresizingMaskIntoConstraints = false
        npView.addSubview(col)

        [bar, table, npView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; screen.addSubview($0) }
        [titleLabel, indicator].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; bar.addSubview($0) }

        NSLayoutConstraint.activate([
            screen.topAnchor.constraint(equalTo: g.topAnchor, constant: 12),
            screen.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 16),
            screen.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -16),
            screen.heightAnchor.constraint(equalToConstant: 232),

            bar.topAnchor.constraint(equalTo: screen.topAnchor),
            bar.leadingAnchor.constraint(equalTo: screen.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: screen.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            indicator.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -8),
            indicator.centerYAnchor.constraint(equalTo: bar.centerYAnchor),

            table.topAnchor.constraint(equalTo: bar.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: screen.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: screen.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: screen.bottomAnchor),
            npView.topAnchor.constraint(equalTo: bar.bottomAnchor),
            npView.leadingAnchor.constraint(equalTo: screen.leadingAnchor),
            npView.trailingAnchor.constraint(equalTo: screen.trailingAnchor),
            npView.bottomAnchor.constraint(equalTo: screen.bottomAnchor),
            col.topAnchor.constraint(equalTo: npView.topAnchor, constant: 6),
            col.leadingAnchor.constraint(equalTo: npView.leadingAnchor, constant: 10),
            col.trailingAnchor.constraint(equalTo: npView.trailingAnchor, constant: -10),
            art.heightAnchor.constraint(equalToConstant: 100),

            wheel.widthAnchor.constraint(equalToConstant: 250),
            wheel.heightAnchor.constraint(equalToConstant: 250),
            wheel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wheel.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -20)
        ])
    }

    private func applyTheme() {
        let t = theme
        view.backgroundColor = t.body
        screen.backgroundColor = t.screen
        screen.layer.borderColor = t.border.cgColor
        bar.backgroundColor = t.bar
        titleLabel.textColor = t.barText
        indicator.textColor = t.barText
        table.backgroundColor = t.screen
        npView.backgroundColor = t.screen
        art.backgroundColor = t.bar
        npTitle.textColor = t.text
        npArtist.textColor = t.subtext
        t1.textColor = t.subtext
        t2.textColor = t.subtext
        progress.trackTintColor = t.bar
        progress.progressTintColor = t.selBg
        setNeedsStatusBarAppearanceUpdate()
        table.reloadData()
    }

    private func wireWheel() {
        wheel.onStep = { [weak self] s in self?.step(s) }
        wheel.onCenter = { [weak self] in self?.center() }
        wheel.onMenu = { [weak self] in self?.menuButton() }
        wheel.onPlay = { [weak self] in self?.toggle() }
        wheel.onNext = { [weak self] in self?.player.skipToNextItem() }
        wheel.onPrev = { [weak self] in
            guard let self = self else { return }
            if self.player.currentPlaybackTime > 3 { self.player.skipToBeginning() }
            else { self.player.skipToPreviousItem() }
        }
    }

    // MARK: Menus
    private func mainMenu() -> Menu {
        return Menu(title: "iPod", rows: [
            Row(title: "Playlists", arrow: true) { [weak self] in
                guard let self = self else { return }
                let cols = MPMediaQuery.playlists().collections ?? []
                self.push(self.collectionsMenu("Playlists", cols) { ($0 as? MPMediaPlaylist)?.name ?? "Playlist" })
            },
            Row(title: "Artists", arrow: true) { [weak self] in
                guard let self = self else { return }
                let cols = MPMediaQuery.artists().collections ?? []
                self.push(self.collectionsMenu("Artists", cols) { $0.representativeItem?.artist ?? "Unknown" })
            },
            Row(title: "Albums", arrow: true) { [weak self] in
                guard let self = self else { return }
                let cols = MPMediaQuery.albums().collections ?? []
                self.push(self.collectionsMenu("Albums", cols) { $0.representativeItem?.albumTitle ?? "Unknown" })
            },
            Row(title: "Songs", arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.songsMenu("Songs", MPMediaQuery.songs().items ?? []))
            },
            Row(title: "Now Playing", arrow: true) { [weak self] in self?.showNP() },
            Row(title: "Shuffle Songs") { [weak self] in self?.shuffleAll() },
            Row(title: "Settings", arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.settingsMenu())
            }
        ])
    }

    private func collectionsMenu(_ title: String, _ cols: [MPMediaItemCollection],
                                 _ name: @escaping (MPMediaItemCollection) -> String) -> Menu {
        let rows = cols.map { c in
            Row(title: name(c), arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.songsMenu(name(c), c.items))
            }
        }
        return Menu(title: title, rows: rows.isEmpty ? [Row(title: "Empty", action: {})] : rows)
    }

    private func songsMenu(_ title: String, _ items: [MPMediaItem]) -> Menu {
        var rows: [Row] = []
        for (i, it) in items.enumerated() {
            rows.append(Row(title: it.title ?? "Unknown", detail: it.artist) { [weak self] in
                self?.play(items, at: i)
            })
        }
        return Menu(title: title, rows: rows.isEmpty ? [Row(title: "No songs", action: {})] : rows)
    }

    // MARK: Settings menus
    private func settingsMenu() -> Menu {
        return Menu(title: "Settings", rows: [
            Row(title: "Theme", arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.themeMenu())
            },
            Row(title: "Controller Style", arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.controllerMenu())
            },
            Row(title: "About", arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.aboutMenu())
            }
        ])
    }

    private func themeMenu() -> Menu {
        let rows = Theme.all.enumerated().map { (i, t) -> Row in
            Row(title: t.name, detail: i == themeIndex ? "\u{2713}" : nil) { [weak self] in
                guard let self = self else { return }
                self.themeIndex = i
                UserDefaults.standard.set(i, forKey: "themeIndex")
                self.applyTheme()
                self.refreshTop(self.themeMenu())
            }
        }
        return Menu(title: "Theme", rows: rows, sel: themeIndex)
    }

    private func controllerMenu() -> Menu {
        let rows = WheelStyle.all.enumerated().map { (i, s) -> Row in
            Row(title: s.name, detail: i == wheelIndex ? "\u{2713}" : nil) { [weak self] in
                guard let self = self else { return }
                self.wheelIndex = i
                UserDefaults.standard.set(i, forKey: "wheelIndex")
                self.wheel.style = WheelStyle.all[i]
                self.refreshTop(self.controllerMenu())
            }
        }
        return Menu(title: "Controller Style", rows: rows, sel: wheelIndex)
    }

    private func aboutMenu() -> Menu {
        let songs = MPMediaQuery.songs().items?.count ?? 0
        let artists = MPMediaQuery.artists().collections?.count ?? 0
        let albums = MPMediaQuery.albums().collections?.count ?? 0
        var version = "1.0"
        if let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, !v.isEmpty {
            version = v
        }
        let info: [(String, String)] = [
            ("Songs", "\(songs)"),
            ("Artists", "\(artists)"),
            ("Albums", "\(albums)"),
            ("Version", version),
            ("Software", "iOS " + UIDevice.current.systemVersion),
            ("Model", UIDevice.current.model)
        ]
        let rows = info.map { Row(title: $0.0, detail: $0.1, action: {}) }
        return Menu(title: "About", rows: rows)
    }

    /// Replaces the top menu (to refresh checkmarks) while keeping the highlighted row.
    private func refreshTop(_ m: Menu) {
        guard !stack.isEmpty else { return }
        var n = m
        n.sel = stack[stack.count - 1].sel
        stack[stack.count - 1] = n
        render()
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // MARK: Playback
    private func play(_ items: [MPMediaItem], at i: Int) {
        guard i < items.count else { return }
        player.shuffleMode = .off
        player.setQueue(with: MPMediaItemCollection(items: items))
        player.nowPlayingItem = items[i]
        player.play()
        showNP()
    }

    private func shuffleAll() {
        let items = MPMediaQuery.songs().items ?? []
        guard !items.isEmpty else { return }
        player.setQueue(with: MPMediaItemCollection(items: items))
        player.shuffleMode = .songs
        player.play()
        showNP()
    }

    private func toggle() {
        if player.playbackState == .playing { player.pause() } else { player.play() }
    }

    // MARK: Navigation
    private func push(_ m: Menu) { stack.append(m); render() }

    private func menuButton() {
        if inNowPlaying { inNowPlaying = false } else if stack.count > 1 { stack.removeLast() }
        render()
    }

    private func showNP() {
        inNowPlaying = true
        render()
    }

    private func step(_ s: Int) {
        if inNowPlaying {
            let d = player.nowPlayingItem?.playbackDuration ?? 0
            player.currentPlaybackTime = max(0, min(d, player.currentPlaybackTime + Double(s) * 5))
            updateNP()
        } else if !stack.isEmpty {
            let i = stack.count - 1
            stack[i].sel = max(0, min(stack[i].rows.count - 1, stack[i].sel + s))
            render()
        }
    }

    private func center() {
        if inNowPlaying { toggle(); return }
        guard let m = stack.last, m.sel < m.rows.count else { return }
        m.rows[m.sel].action()
    }

    // MARK: Render
    private func render() {
        table.isHidden = inNowPlaying
        npView.isHidden = !inNowPlaying
        titleLabel.text = inNowPlaying ? "Now Playing" : (stack.last?.title ?? "iPod")
        if inNowPlaying { updateNP() }
        else {
            table.reloadData()
            if let m = stack.last, !m.rows.isEmpty {
                table.scrollToRow(at: IndexPath(row: m.sel, section: 0), at: .none, animated: false)
            }
        }
    }

    @objc private func updateNP() {
        indicator.text = player.playbackState == .playing ? "\u{25B6}\u{FE0E}" : "\u{2758}\u{2758}"
        guard inNowPlaying else { return }
        let item = player.nowPlayingItem
        npTitle.text = item?.title ?? "Nothing Playing"
        npArtist.text = [item?.artist, item?.albumTitle].compactMap { $0 }.joined(separator: " - ")
        art.image = item?.artwork?.image(at: CGSize(width: 100, height: 100))
        let d = item?.playbackDuration ?? 0
        var c = player.currentPlaybackTime
        if !c.isFinite { c = 0 }
        progress.progress = d > 0 ? Float(min(1, c / d)) : 0
        t1.text = fmt(c)
        t2.text = "-" + fmt(max(0, d - c))
    }

    private func fmt(_ t: TimeInterval) -> String {
        guard t.isFinite, t >= 0 else { return "0:00" }
        let s = Int(t)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: Table
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stack.last?.rows.count ?? 0
    }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "c") ?? UITableViewCell(style: .value1, reuseIdentifier: "c")
        guard let m = stack.last else { return cell }
        let t = theme
        let row = m.rows[ip.row]
        let sel = ip.row == m.sel
        cell.textLabel?.text = row.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.detailTextLabel?.text = row.arrow ? "\u{203A}" : row.detail
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12)
        cell.textLabel?.textColor = sel ? t.selText : t.text
        cell.detailTextLabel?.textColor = sel ? t.selText : t.subtext
        cell.backgroundColor = sel ? t.selBg : t.screen
        cell.selectionStyle = .none
        return cell
    }
}
