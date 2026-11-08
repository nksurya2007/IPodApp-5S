import UIKit
import MediaPlayer
import AVFoundation
import AudioToolbox

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

private func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
    return UIColor(red: r, green: g, blue: b, alpha: 1)
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
              dark: false),
        Theme(name: "Ocean",
              body: rgb(0.80, 0.91, 0.97), screen: rgb(0.92, 0.97, 1.00),
              border: rgb(0.10, 0.30, 0.50), bar: rgb(0.65, 0.82, 0.93),
              barText: rgb(0.03, 0.15, 0.30), text: rgb(0.03, 0.15, 0.30),
              subtext: rgb(0.30, 0.45, 0.58), selBg: rgb(0.05, 0.45, 0.75),
              selText: .white, dark: false),
        Theme(name: "Sunset",
              body: rgb(1.00, 0.90, 0.80), screen: rgb(1.00, 0.97, 0.92),
              border: rgb(0.65, 0.30, 0.10), bar: rgb(0.99, 0.78, 0.55),
              barText: rgb(0.35, 0.12, 0.02), text: rgb(0.35, 0.12, 0.02),
              subtext: rgb(0.60, 0.40, 0.25), selBg: rgb(0.95, 0.45, 0.10),
              selText: .white, dark: false),
        Theme(name: "Purple",
              body: rgb(0.90, 0.86, 0.96), screen: rgb(0.97, 0.95, 1.00),
              border: rgb(0.35, 0.20, 0.55), bar: rgb(0.78, 0.70, 0.92),
              barText: rgb(0.15, 0.07, 0.30), text: rgb(0.15, 0.07, 0.30),
              subtext: rgb(0.45, 0.35, 0.60), selBg: rgb(0.50, 0.25, 0.80),
              selText: .white, dark: false),
        Theme(name: "Gold",
              body: rgb(0.96, 0.92, 0.78), screen: rgb(1.00, 0.99, 0.93),
              border: rgb(0.55, 0.45, 0.10), bar: rgb(0.90, 0.82, 0.50),
              barText: rgb(0.30, 0.23, 0.02), text: rgb(0.30, 0.23, 0.02),
              subtext: rgb(0.55, 0.47, 0.20), selBg: rgb(0.78, 0.60, 0.05),
              selText: .white, dark: false),
        Theme(name: "U2 Red",
              body: rgb(0.05, 0.05, 0.05), screen: rgb(0.08, 0.08, 0.08),
              border: rgb(0.75, 0.05, 0.10), bar: rgb(0.55, 0.05, 0.08),
              barText: .white, text: .white,
              subtext: rgb(0.65, 0.65, 0.65), selBg: rgb(0.85, 0.10, 0.15),
              selText: .white, dark: true),
        Theme(name: "Matrix",
              body: rgb(0.02, 0.06, 0.02), screen: rgb(0.00, 0.04, 0.00),
              border: rgb(0.00, 0.50, 0.10), bar: rgb(0.00, 0.20, 0.05),
              barText: rgb(0.30, 1.00, 0.40), text: rgb(0.30, 1.00, 0.40),
              subtext: rgb(0.10, 0.60, 0.20), selBg: rgb(0.10, 0.70, 0.25),
              selText: .black, dark: true)
    ]
}

final class iPodViewController: UIViewController, UITableViewDataSource {
    private let player = MPMusicPlayerController.applicationMusicPlayer
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
    private let statusLabel = UILabel()   // clock + battery %
    private let clockFormat: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()
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

    // Volume
    private let volumeView = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 10, height: 10))
    private let volBar = UIProgressView(progressViewStyle: .default)
    private let volLabel = UILabel()
    private let modeLabel = UILabel()
    private var scrubMode = false
    private var volume: Float = AVAudioSession.sharedInstance().outputVolume
    private var lastVolChange = Date.distantPast

    // Cover Flow, game, songs view
    private let coverFlow = CoverFlowView()
    private let game = BrickGameView()
    private var inCoverFlow = false
    private var inGame = false
    private var coverSongs: [MPMediaItem] = []

    private var clickSoundOn: Bool {
        return UserDefaults.standard.object(forKey: "clickSound") as? Bool ?? true
    }
    // Per-list view (0 = In Line, 1 = Cover Flow) and one sort for all lists
    // (0 = A-Z, 1 = Z-A, 2 = Recently Added)
    private enum ListKind: String {
        case songs, artists, albums, playlists
        var title: String { return rawValue.capitalized }
    }
    private func viewMode(_ k: ListKind) -> Int {
        return UserDefaults.standard.integer(forKey: "view_" + k.rawValue)
    }
    private var songSort: Int { return UserDefaults.standard.integer(forKey: "songSort") }
    private let songSortNames = ["A-Z", "Z-A", "Recently Added"]
    private var coverTitle = "Cover Flow"

    override var prefersStatusBarHidden: Bool { return true }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.dark ? .lightContent : .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.isBatteryMonitoringEnabled = true
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
        [screen, wheel, volumeView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        screen.layer.borderWidth = 3
        screen.layer.cornerRadius = 8
        screen.clipsToBounds = true

        titleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        indicator.font = UIFont.boldSystemFont(ofSize: 12)
        indicator.textAlignment = .right
        statusLabel.font = UIFont.boldSystemFont(ofSize: 11)
        statusLabel.textAlignment = .right
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        table.dataSource = self
        table.rowHeight = 30
        table.isUserInteractionEnabled = false
        table.separatorStyle = .none
        table.tableFooterView = UIView()
        npView.isHidden = true
        coverFlow.isHidden = true
        game.isHidden = true

        art.contentMode = .scaleAspectFit
        npTitle.font = UIFont.boldSystemFont(ofSize: 16)
        npArtist.font = UIFont.systemFont(ofSize: 13)
        [npTitle, npArtist].forEach { $0.textAlignment = .center }
        [t1, t2].forEach { $0.font = UIFont.systemFont(ofSize: 11) }
        t2.textAlignment = .right

        let times = UIStackView(arrangedSubviews: [t1, t2])
        times.distribution = .fillEqually
        volLabel.text = "Volume"
        volLabel.font = UIFont.systemFont(ofSize: 10)
        modeLabel.font = UIFont.boldSystemFont(ofSize: 10)
        modeLabel.textAlignment = .right
        let volRow = UIStackView(arrangedSubviews: [volLabel, modeLabel])
        volRow.distribution = .fillEqually
        let col = UIStackView(arrangedSubviews: [art, npTitle, npArtist, progress, times, volRow, volBar])
        col.axis = .vertical
        col.spacing = 5
        col.translatesAutoresizingMaskIntoConstraints = false
        npView.addSubview(col)

        [bar, table, npView, coverFlow, game].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; screen.addSubview($0) }
        [titleLabel, indicator, statusLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; bar.addSubview($0) }

        NSLayoutConstraint.activate([
            screen.topAnchor.constraint(equalTo: g.topAnchor, constant: 12),
            screen.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 16),
            screen.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -16),
            screen.bottomAnchor.constraint(equalTo: wheel.topAnchor, constant: -16),

            bar.topAnchor.constraint(equalTo: screen.topAnchor),
            bar.leadingAnchor.constraint(equalTo: screen.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: screen.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            indicator.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -8),
            indicator.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: indicator.leadingAnchor, constant: -8),
            statusLabel.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -6),

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
            art.heightAnchor.constraint(equalToConstant: 90),

            coverFlow.topAnchor.constraint(equalTo: bar.bottomAnchor),
            coverFlow.leadingAnchor.constraint(equalTo: screen.leadingAnchor),
            coverFlow.trailingAnchor.constraint(equalTo: screen.trailingAnchor),
            coverFlow.bottomAnchor.constraint(equalTo: screen.bottomAnchor),
            game.topAnchor.constraint(equalTo: bar.bottomAnchor),
            game.leadingAnchor.constraint(equalTo: screen.leadingAnchor),
            game.trailingAnchor.constraint(equalTo: screen.trailingAnchor),
            game.bottomAnchor.constraint(equalTo: screen.bottomAnchor),

            wheel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.76),
            wheel.heightAnchor.constraint(equalTo: wheel.widthAnchor),
            wheel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wheel.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -16)
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
        statusLabel.textColor = t.barText
        table.backgroundColor = t.screen
        npView.backgroundColor = t.screen
        art.backgroundColor = t.bar
        npTitle.textColor = t.text
        npArtist.textColor = t.subtext
        t1.textColor = t.subtext
        t2.textColor = t.subtext
        volLabel.textColor = t.subtext
        modeLabel.textColor = t.selBg
        volBar.trackTintColor = t.bar
        volBar.progressTintColor = t.selBg
        progress.trackTintColor = t.bar
        progress.progressTintColor = t.selBg
        setNeedsStatusBarAppearanceUpdate()
        table.reloadData()
    }

    private func wireWheel() {
        wheel.onStep = { [weak self] s in self?.step(s) }
        wheel.onCenter = { [weak self] in self?.center() }
        wheel.onRotate = { [weak self] d in
            guard let self = self, self.inGame, !self.inNowPlaying else { return }
            self.game.rotate(d)
        }
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
            Row(title: "Playlists", arrow: true) { [weak self] in self?.openList(.playlists) },
            Row(title: "Artists", arrow: true) { [weak self] in self?.openList(.artists) },
            Row(title: "Albums", arrow: true) { [weak self] in self?.openList(.albums) },
            Row(title: "Songs", arrow: true) { [weak self] in self?.openList(.songs) },
            Row(title: "Now Playing", arrow: true) { [weak self] in self?.showNP() },
            Row(title: "Shuffle Songs") { [weak self] in self?.shuffleAll() },
            Row(title: "Extras", arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.extrasMenu())
            },
            Row(title: "Settings", arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.settingsMenu())
            }
        ])
    }

    /// Every audio item in the library (music, podcasts, audiobooks, imported audio, iCloud items),
    /// not just the "music" type that MPMediaQuery.songs() returns.
    private func allSongs() -> [MPMediaItem] {
        let items = MPMediaQuery().items ?? []
        return items
            .filter { $0.mediaType.rawValue & MPMediaType.anyAudio.rawValue != 0 }
            .sorted { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending }
    }

    /// Songs ordered by the chosen sort (A-Z, Z-A, Recently Added).
    private func sortedSongs() -> [MPMediaItem] {
        let a = allSongs()   // already A-Z
        switch songSort {
        case 1:  return Array(a.reversed())
        case 2:  return a.sorted { $0.dateAdded > $1.dateAdded }
        default: return a
        }
    }

    private func collName(_ k: ListKind, _ c: MPMediaItemCollection) -> String {
        switch k {
        case .playlists: return (c as? MPMediaPlaylist)?.name ?? "Playlist"
        case .artists:   return c.representativeItem?.albumArtist ?? c.representativeItem?.artist ?? "Unknown Artist"
        default:         return c.representativeItem?.albumTitle ?? "Unknown Album"
        }
    }

    private func sortedCollections(_ k: ListKind) -> [MPMediaItemCollection] {
        var cols: [MPMediaItemCollection]
        switch k {
        case .playlists: cols = MPMediaQuery.playlists().collections ?? []
        case .artists:   cols = grouped { $0.albumArtist ?? $0.artist ?? "Unknown Artist" }
        default:         cols = grouped { $0.albumTitle ?? "Unknown Album" }
        }
        func az(_ a: MPMediaItemCollection, _ b: MPMediaItemCollection) -> Bool {
            return collName(k, a).localizedCaseInsensitiveCompare(collName(k, b)) == .orderedAscending
        }
        func newest(_ c: MPMediaItemCollection) -> Date {
            return c.items.map { $0.dateAdded }.max() ?? Date.distantPast
        }
        switch songSort {
        case 1:  cols.sort { az($1, $0) }
        case 2:  cols.sort { newest($0) > newest($1) }
        default: cols.sort(by: az)
        }
        return cols
    }

    /// Opens Songs / Artists / Albums / Playlists as a line list or Cover Flow, per Settings.
    private func openList(_ k: ListKind) {
        let coverFlowOn = viewMode(k) == 1
        if k == .songs {
            let items = sortedSongs()
            if coverFlowOn {
                coverSongs = items
                coverFlow.setSongs(items)
                coverTitle = k.title
                inCoverFlow = true
                render()
            } else {
                push(songsMenu(k.title, items))
            }
            return
        }
        let cols = sortedCollections(k)
        if coverFlowOn {
            let ck: CoverFlowView.Kind = (k == .artists) ? .artist : (k == .playlists ? .playlist : .album)
            coverFlow.setCollections(cols, kind: ck)
            coverTitle = k.title
            inCoverFlow = true
            render()
        } else {
            push(collectionsMenu(k.title, cols) { [weak self] c in self?.collName(k, c) ?? "" })
        }
    }

    private func grouped(_ key: (MPMediaItem) -> String) -> [MPMediaItemCollection] {
        let dict = Dictionary(grouping: allSongs(), by: key)
        return dict.keys
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            .map { k in
                let sorted = (dict[k] ?? []).sorted {
                    if $0.albumTitle != $1.albumTitle {
                        return ($0.albumTitle ?? "").localizedCaseInsensitiveCompare($1.albumTitle ?? "") == .orderedAscending
                    }
                    if $0.discNumber != $1.discNumber { return $0.discNumber < $1.discNumber }
                    return $0.albumTrackNumber < $1.albumTrackNumber
                }
                return MPMediaItemCollection(items: sorted)
            }
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
            Row(title: "Cover Flow", arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.coverFlowSettingsMenu())
            },
            Row(title: "Sort", arrow: true) { [weak self] in
                guard let self = self else { return }
                self.push(self.sortMenu())
            },
            Row(title: "Click Sound", detail: clickSoundOn ? "On" : "Off") { [weak self] in
                guard let self = self else { return }
                let on = !self.clickSoundOn
                UserDefaults.standard.set(on, forKey: "clickSound")
                self.refreshTop(self.settingsMenu())
                if on { AudioServicesPlaySystemSound(1104) }
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

    /// Press center on a row to switch it between In Line and Cover Flow.
    private func coverFlowSettingsMenu() -> Menu {
        let kinds: [ListKind] = [.songs, .artists, .albums, .playlists]
        let rows = kinds.map { k -> Row in
            Row(title: k.title, detail: viewMode(k) == 1 ? "Cover Flow" : "In Line") { [weak self] in
                guard let self = self else { return }
                UserDefaults.standard.set(self.viewMode(k) == 1 ? 0 : 1, forKey: "view_" + k.rawValue)
                self.refreshTop(self.coverFlowSettingsMenu())
            }
        }
        return Menu(title: "Cover Flow", rows: rows)
    }

    private func sortMenu() -> Menu {
        let rows = songSortNames.enumerated().map { (i, n) -> Row in
            Row(title: n, detail: i == songSort ? "\u{2713}" : nil) { [weak self] in
                guard let self = self else { return }
                UserDefaults.standard.set(i, forKey: "songSort")
                self.refreshTop(self.sortMenu())
            }
        }
        return Menu(title: "Sort", rows: rows, sel: songSort)
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
        let songs = allSongs().count
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
            ("Model", UIDevice.current.model),
            ("Made by", "SN STUDIO \u{1F499}")
        ]
        let rows = info.map { Row(title: $0.0, detail: $0.1, action: {}) }
        return Menu(title: "About", rows: rows)
    }

    private func extrasMenu() -> Menu {
        return Menu(title: "Extras", rows: [
            Row(title: "Brick Game") { [weak self] in
                guard let self = self else { return }
                self.inGame = true
                self.game.newGame()
                self.render()
            }
        ])
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

    // MARK: Volume
    private var volumeSlider: UISlider? {
        return volumeView.subviews.compactMap { $0 as? UISlider }.first
    }

    private func setVolume(_ v: Float) {
        volume = max(0, min(1, v))
        lastVolChange = Date()
        volumeSlider?.value = volume
    }

    /// Stops playback and tears everything down (called when the app is closed).
    func shutdown() {
        timer?.invalidate()
        timer = nil
        game.stop()
        player.stop()
        player.endGeneratingPlaybackNotifications()
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
        let items = allSongs()
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
        if inNowPlaying {
            inNowPlaying = false
        } else if inGame {
            inGame = false
        } else if inCoverFlow {
            inCoverFlow = false
        } else if stack.count > 1 {
            stack.removeLast()
        }
        render()
    }

    private func showNP() {
        inNowPlaying = true
        render()
    }

    private func step(_ s: Int) {
        if inGame && !inNowPlaying { return }
        if clickSoundOn { AudioServicesPlaySystemSound(1104) }
        if inNowPlaying {
            if scrubMode {
                let d = player.nowPlayingItem?.playbackDuration ?? 0
                player.currentPlaybackTime = max(0, min(d, player.currentPlaybackTime + Double(s) * 5))
            } else {
                setVolume(volume + Float(s) / 16)
            }
            updateNP()
        } else if inCoverFlow {
            coverFlow.move(s)
        } else if !stack.isEmpty {
            let i = stack.count - 1
            stack[i].sel = max(0, min(stack[i].rows.count - 1, stack[i].sel + s))
            render()
        }
    }

    private func center() {
        if inNowPlaying { scrubMode.toggle(); updateNP(); return }
        if inGame { game.press(); return }
        if inCoverFlow {
            if coverFlow.songMode {
                play(coverSongs, at: coverFlow.index)
            } else if let c = coverFlow.current {
                play(c.items, at: 0)
            }
            return
        }
        guard let m = stack.last, m.sel < m.rows.count else { return }
        m.rows[m.sel].action()
    }

    // MARK: Render
    private func render() {
        let showTable = !inNowPlaying && !inGame && !inCoverFlow
        table.isHidden = !showTable
        npView.isHidden = !inNowPlaying
        coverFlow.isHidden = !(inCoverFlow && !inNowPlaying)
        game.isHidden = !(inGame && !inNowPlaying)
        if inGame { game.start() } else { game.stop() }
        if inNowPlaying { titleLabel.text = "Now Playing" }
        else if inGame { titleLabel.text = "Brick Game" }
        else if inCoverFlow { titleLabel.text = coverTitle }
        else { titleLabel.text = stack.last?.title ?? "iPod" }
        if inNowPlaying { updateNP() }
        else if showTable {
            table.reloadData()
            if let m = stack.last, !m.rows.isEmpty {
                table.scrollToRow(at: IndexPath(row: m.sel, section: 0), at: .none, animated: false)
            }
        }
    }

    private func updateStatus() {
        let lvl = UIDevice.current.batteryLevel
        let pct = lvl >= 0 ? "\(Int(round(lvl * 100)))%" : "--%"
        let st = UIDevice.current.batteryState
        let chg = (st == .charging || st == .full) ? "\u{26A1}\u{FE0E}" : ""
        statusLabel.text = clockFormat.string(from: Date()) + "  " + chg + pct
    }

    @objc private func updateNP() {
        updateStatus()
        indicator.text = player.playbackState == .playing ? "\u{25B6}\u{FE0E}" : "\u{2758}\u{2758}"
        guard inNowPlaying else { return }
        if Date().timeIntervalSince(lastVolChange) > 0.8 {   // pick up hardware volume button changes
            volume = AVAudioSession.sharedInstance().outputVolume
        }
        volBar.progress = volume
        modeLabel.text = scrubMode ? "Wheel: Seek (press center)" : "Wheel: Volume (press center)"
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
