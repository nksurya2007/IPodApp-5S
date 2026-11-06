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

final class iPodViewController: UIViewController, UITableViewDataSource {
    private let player = MPMusicPlayerController.systemMusicPlayer
    private var stack: [Menu] = []
    private var inNowPlaying = false

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.93, alpha: 1)
        buildUI()
        wireWheel()

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
                        Row(title: "Allow Music access", detail: "Settings", action: {})])]
                }
                self.render()
            }
        }
    }

    // MARK: UI
    private func buildUI() {
        let g = view.safeAreaLayoutGuide
        [screen, wheel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        screen.backgroundColor = .white
        screen.layer.borderColor = UIColor.darkGray.cgColor
        screen.layer.borderWidth = 3
        screen.layer.cornerRadius = 8
        screen.clipsToBounds = true

        bar.backgroundColor = UIColor(white: 0.82, alpha: 1)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        indicator.font = UIFont.boldSystemFont(ofSize: 12)
        indicator.textAlignment = .right
        table.dataSource = self
        table.rowHeight = 26
        table.isUserInteractionEnabled = false
        table.separatorStyle = .none
        table.tableFooterView = UIView()
        npView.backgroundColor = .white
        npView.isHidden = true

        art.contentMode = .scaleAspectFit
        art.backgroundColor = UIColor(white: 0.9, alpha: 1)
        npTitle.font = UIFont.boldSystemFont(ofSize: 16)
        npArtist.font = UIFont.systemFont(ofSize: 13)
        npArtist.textColor = .darkGray
        [npTitle, npArtist].forEach { $0.textAlignment = .center }
        [t1, t2].forEach { $0.font = UIFont.systemFont(ofSize: 11) }
        t2.textAlignment = .right
        progress.trackTintColor = UIColor(white: 0.85, alpha: 1)
        progress.progressTintColor = UIColor(red: 0.1, green: 0.45, blue: 0.82, alpha: 1)

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
            Row(title: "Shuffle Songs") { [weak self] in self?.shuffleAll() }
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
        let row = m.rows[ip.row]
        let sel = ip.row == m.sel
        cell.textLabel?.text = row.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.detailTextLabel?.text = row.arrow ? "\u{203A}" : row.detail
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12)
        cell.textLabel?.textColor = sel ? .white : .black
        cell.detailTextLabel?.textColor = sel ? .white : .gray
        cell.backgroundColor = sel ? UIColor(red: 0.1, green: 0.45, blue: 0.82, alpha: 1) : .white
        cell.selectionStyle = .none
        return cell
    }
}
