import UIKit
import MediaPlayer

/// Classic iPod "Cover Flow": albums as 3D flipping artwork.
final class CoverFlowView: UIView {
    private(set) var index = 0
    private var albums: [MPMediaItemCollection] = []
    private var covers: [Int: UIView] = [:]
    private var images: [Int: UIImage] = [:]
    private let stage = UIView()
    private let titleLabel = UILabel()
    private let subLabel = UILabel()
    private var coverSize: CGFloat = 0
    enum Kind { case album, song, artist, playlist }
    private(set) var kind: Kind = .album
    var songMode: Bool { return kind == .song }

    var current: MPMediaItemCollection? {
        return albums.indices.contains(index) ? albums[index] : nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
        var m = CATransform3DIdentity
        m.m34 = -1.0 / 450.0
        stage.layer.sublayerTransform = m
        addSubview(stage)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 12)
        titleLabel.textColor = .white
        subLabel.font = UIFont.systemFont(ofSize: 10)
        subLabel.textColor = UIColor(white: 0.65, alpha: 1)
        titleLabel.textAlignment = .center
        subLabel.textAlignment = .center
        addSubview(titleLabel)
        addSubview(subLabel)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setAlbums(_ a: [MPMediaItemCollection]) { setCollections(a, kind: .album) }

    func setCollections(_ a: [MPMediaItemCollection], kind k: Kind) {
        kind = k
        load(a)
    }

    func setSongs(_ items: [MPMediaItem]) {
        kind = .song
        load(items.map { MPMediaItemCollection(items: [$0]) })
    }

    private func load(_ a: [MPMediaItemCollection]) {
        albums = a
        index = 0
        covers.values.forEach { $0.removeFromSuperview() }
        covers.removeAll()
        images.removeAll()
        layoutCovers(animated: false)
        updateLabels()
    }

    func move(_ d: Int) {
        guard !albums.isEmpty else { return }
        let n = max(0, min(albums.count - 1, index + d))
        guard n != index else { return }
        index = n
        layoutCovers(animated: true)
        updateLabels()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width, h = bounds.height
        stage.frame = CGRect(x: 0, y: 0, width: w, height: max(0, h - 40))
        titleLabel.frame = CGRect(x: 6, y: h - 38, width: w - 12, height: 18)
        subLabel.frame = CGRect(x: 6, y: h - 20, width: w - 12, height: 16)
        let size = max(40, min(w * 0.46, stage.bounds.height * 0.60))
        if abs(size - coverSize) > 0.5 {
            coverSize = size
            covers.values.forEach { $0.removeFromSuperview() }
            covers.removeAll()
            images.removeAll()
        }
        layoutCovers(animated: false)
        updateLabels()
    }

    private func layoutCovers(animated: Bool) {
        guard !albums.isEmpty, coverSize > 0 else { return }
        let lo = max(0, index - 5), hi = min(albums.count - 1, index + 5)
        for (k, v) in Array(covers) where k < lo || k > hi {
            v.removeFromSuperview()
            covers[k] = nil
            images[k] = nil
        }
        for i in lo...hi where covers[i] == nil {
            let v = makeCover(i)
            stage.addSubview(v)
            covers[i] = v
            place(v, offset: i - index)
        }
        UIView.animate(withDuration: animated ? 0.22 : 0, delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState]) {
            for (k, v) in self.covers { self.place(v, offset: k - self.index) }
        }
    }

    private func place(_ v: UIView, offset off: Int) {
        let midX = stage.bounds.midX
        let midY = stage.bounds.midY - coverSize * 0.12
        let spacing = coverSize * 0.30
        var x = midX + CGFloat(off) * spacing
        if off != 0 { x += (off > 0 ? 1 : -1) * coverSize * 0.38 }
        v.center = CGPoint(x: x, y: midY)
        v.layer.zPosition = CGFloat(-abs(off))
        var t = CATransform3DIdentity
        if off != 0 {
            t = CATransform3DMakeTranslation(0, 0, -coverSize * 0.35)
            t = CATransform3DRotate(t, off < 0 ? 1.0 : -1.0, 0, 1, 0)
        }
        v.layer.transform = t
    }

    private func makeCover(_ i: Int) -> UIView {
        let size = coverSize
        let img = image(for: i)
        let v = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))

        let iv = UIImageView(image: img)
        iv.frame = v.bounds
        iv.layer.borderColor = UIColor(white: 1, alpha: 0.25).cgColor
        iv.layer.borderWidth = 0.5
        v.addSubview(iv)

        let rf = UIImageView(image: img)
        rf.frame = CGRect(x: 0, y: size + 2, width: size, height: size)
        rf.transform = CGAffineTransform(scaleX: 1, y: -1)
        let mask = CAGradientLayer()
        mask.frame = rf.bounds
        mask.colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor(white: 1, alpha: 0.35).cgColor]
        mask.startPoint = CGPoint(x: 0.5, y: 0.55)
        mask.endPoint = CGPoint(x: 0.5, y: 1.0)
        rf.layer.mask = mask
        v.addSubview(rf)
        return v
    }

    private func image(for i: Int) -> UIImage {
        if let im = images[i] { return im }
        let sz = CGSize(width: coverSize, height: coverSize)
        let im = albums[i].representativeItem?.artwork?.image(at: sz) ?? placeholder(sz)
        images[i] = im
        return im
    }

    private func placeholder(_ sz: CGSize) -> UIImage {
        let r = UIGraphicsImageRenderer(size: sz)
        return r.image { ctx in
            UIColor(white: 0.22, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: sz))
            let s = "\u{266A}" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: sz.width * 0.5),
                .foregroundColor: UIColor(white: 0.5, alpha: 1)
            ]
            let ts = s.size(withAttributes: attrs)
            s.draw(at: CGPoint(x: (sz.width - ts.width) / 2, y: (sz.height - ts.height) / 2),
                   withAttributes: attrs)
        }
    }

    private func updateLabels() {
        guard let c = current else {
            switch kind {
            case .song: titleLabel.text = "No songs"
            case .artist: titleLabel.text = "No artists"
            case .playlist: titleLabel.text = "No playlists"
            case .album: titleLabel.text = "No albums"
            }
            subLabel.text = nil
            return
        }
        let it = c.representativeItem
        switch kind {
        case .song:
            titleLabel.text = it?.title ?? "Unknown"
            subLabel.text = it?.artist ?? ""
        case .artist:
            titleLabel.text = it?.albumArtist ?? it?.artist ?? "Unknown Artist"
            subLabel.text = "\(c.count) songs"
        case .playlist:
            titleLabel.text = (c as? MPMediaPlaylist)?.name ?? "Playlist"
            subLabel.text = "\(c.count) songs"
        case .album:
            titleLabel.text = it?.albumTitle ?? "Unknown Album"
            subLabel.text = it?.albumArtist ?? it?.artist ?? ""
        }
    }
}
