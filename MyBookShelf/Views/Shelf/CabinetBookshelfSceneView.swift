//
//  CabinetBookshelfSceneView.swift
//  MyBookShelf
//

import CoreData
import SceneKit
import SwiftUI
import UIKit

/// 3D cabinet with wooden shelves and book volumes (cover on front face). Pan vertically to browse many rows.
struct CabinetBookshelfSceneView: UIViewRepresentable {
    let slots: [Book?]
    /// When returning from book detail (`0`), scene rebuilds so pulled books reset. While `> 0`, scene is kept for the pull animation.
    var navigationDepth: Int = 0
    let onSelectBook: (Book) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectBook: onSelectBook)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isPlaying = true
        view.antialiasingMode = .multisampling4X
        view.autoenablesDefaultLighting = false
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)

        context.coordinator.attach(view: view)
        context.coordinator.navigationDepth = navigationDepth
        context.coordinator.rebuildScene(slots: slots)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onSelectBook = onSelectBook
        context.coordinator.navigationDepth = navigationDepth
        context.coordinator.rebuildScene(slots: slots)
    }

    final class Coordinator: NSObject {
        var onSelectBook: (Book) -> Void
        private weak var scnView: SCNView?
        private let context = PersistenceController.shared.container.viewContext

        private var lastSlotsHash: Int?
        private var lastNavigationDepth: Int = 0
        var navigationDepth: Int = 0
        private var cameraBaseY: Float = -0.12
        private var cameraYOffset: Float = 0
        private var lastRowCount: Int = 0

        init(onSelectBook: @escaping (Book) -> Void) {
            self.onSelectBook = onSelectBook
        }

        func attach(view: SCNView) {
            scnView = view
        }

        func rebuildScene(slots: [Book?]) {
            guard let view = scnView else { return }
            var hasher = Hasher()
            hasher.combine(slots.count)
            for s in slots {
                switch s {
                case nil: hasher.combine(0)
                case let b?: hasher.combine(b.objectID)
                }
            }
            let h = hasher.finalize()
            let poppedFromDetail = lastNavigationDepth > 0 && navigationDepth == 0
            if let prev = lastSlotsHash, prev == h, !poppedFromDetail, view.scene != nil {
                lastNavigationDepth = navigationDepth
                return
            }
            lastSlotsHash = h
            lastNavigationDepth = navigationDepth

            let scene = CabinetShelfSceneFactory.buildScene(slots: slots)
            view.scene = scene
            view.pointOfView = scene.rootNode.childNode(withName: "cameraNode", recursively: true)

            Task { await Self.refreshRemoteCovers(slots: slots, scene: scene) }

            let rows = max(1, (slots.count + 2) / 3)
            lastRowCount = rows
            let extra = Float(max(0, rows - 3))
            cameraYOffset = min(extra * 0.22, 1.6)
            if let cam = view.pointOfView {
                cam.position.y = cameraBaseY + cameraYOffset
            }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let view = scnView, g.state == .ended else { return }
            let p = g.location(in: view)
            let hits = view.hitTest(p, options: [
                SCNHitTestOption.searchMode: NSNumber(value: SCNHitTestSearchMode.closest.rawValue),
                SCNHitTestOption.boundingBoxOnly: NSNumber(value: false),
            ])
            guard let node = hits.first?.node else { return }

            var bookRoot: SCNNode?
            var selectedBook: Book?
            var walk: SCNNode? = node
            while let c = walk {
                if let name = c.name {
                    let parts = name.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
                    if parts.count == 3, parts[0] == "shelfBook",
                       let url = URL(string: String(parts[2])),
                       let oid = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
                       let book = try? context.existingObject(with: oid) as? Book {
                        bookRoot = c
                        selectedBook = book
                        break
                    }
                }
                walk = c.parent
            }
            guard let bn = bookRoot, let book = selectedBook else { return }

            HapticsService.shared.light()
            let pull = SCNAction.moveBy(x: 0, y: 0, z: 0.78, duration: 0.44)
            pull.timingMode = .easeOut
            let grow = SCNAction.scale(to: 1.14, duration: 0.44)
            grow.timingMode = .easeOut
            let turn = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 0.12, z: 0, duration: 0.4)
            turn.timingMode = .easeOut
            let group = SCNAction.group([pull, grow, turn])
            bn.runAction(group) {
                DispatchQueue.main.async {
                    self.onSelectBook(book)
                }
            }
        }

        private static func refreshRemoteCovers(slots: [Book?], scene: SCNScene) async {
            for (index, slot) in slots.enumerated() {
                guard let book = slot else { continue }
                let uri = book.objectID.uriRepresentation().absoluteString
                let nodeName = "shelfBook|\(index)|\(uri)"
                let img = await BookCoverUIImageLoader.loadAsync(for: book) ?? CabinetShelfSceneFactory.standardCoverImage(for: book)
                await MainActor.run {
                    guard let bookNode = scene.rootNode.childNode(withName: nodeName, recursively: true),
                          let planeNode = bookNode.childNode(withName: "coverPlane", recursively: false),
                          let plane = planeNode.geometry as? SCNPlane else { return }
                    let m = SCNMaterial()
                    m.lightingModel = .constant
                    m.diffuse.contents = img
                    m.isDoubleSided = true
                    m.diffuse.magnificationFilter = .linear
                    m.diffuse.minificationFilter = .linear
                    plane.materials = [m]
                }
            }
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let view = scnView, let cam = view.pointOfView else { return }
            let dy = Float(g.translation(in: view).y)
            g.setTranslation(.zero, in: view)
            let rows = max(1, lastRowCount)
            let maxShift = min(Float(rows - 1) * 0.24, 2.4)
            cameraYOffset = max(0, min(maxShift, cameraYOffset + dy * 0.004))
            cam.position.y = cameraBaseY + cameraYOffset
        }
    }
}

// MARK: - Scene factory

private enum CabinetShelfSceneFactory {
    private static let shelfPitch: Float = 0.9
    private static let firstShelfY: Float = -0.55
    private static let bookW: CGFloat = 0.5
    private static let bookH: CGFloat = 0.78
    private static let bookT: CGFloat = 0.11
    private static let colX: [Float] = [-0.82, 0, 0.82]
    private static let bookZ: Float = -1.48

    static func buildScene(slots: [Book?]) -> SCNScene {
        let scene = SCNScene()
        let root = scene.rootNode

        let woodDark = woodMaterial(UIColor(red: 0.14, green: 0.09, blue: 0.055, alpha: 1))
        let woodMid = woodMaterial(UIColor(red: 0.24, green: 0.15, blue: 0.09, alpha: 1))
        let woodShelf = woodMaterial(UIColor(red: 0.3, green: 0.19, blue: 0.1, alpha: 1))

        let back = SCNBox(width: 7, height: 6.5, length: 0.12, chamferRadius: 0.02)
        back.materials = [woodDark]
        let backNode = SCNNode(geometry: back)
        backNode.position = SCNVector3(0, 0.35, -2.95)
        root.addChildNode(backNode)

        let left = SCNBox(width: 0.14, height: 6.2, length: 3.4, chamferRadius: 0.02)
        left.materials = [woodMid]
        let leftNode = SCNNode(geometry: left)
        leftNode.position = SCNVector3(-3.25, 0.2, -1.1)
        leftNode.eulerAngles = SCNVector3(0, Float(0.1), 0)
        root.addChildNode(leftNode)

        let right = SCNBox(width: 0.14, height: 6.2, length: 3.4, chamferRadius: 0.02)
        right.materials = [woodMid]
        let rightNode = SCNNode(geometry: right)
        rightNode.position = SCNVector3(3.25, 0.2, -1.1)
        rightNode.eulerAngles = SCNVector3(0, Float(-0.1), 0)
        root.addChildNode(rightNode)

        let floor = SCNBox(width: 6.8, height: 0.12, length: 3, chamferRadius: 0.02)
        floor.materials = [woodDark]
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -2.65, -0.15)
        root.addChildNode(floorNode)

        let numRows = max(1, (slots.count + 2) / 3)

        let plankHalfHeight: Float = 0.035
        let plankCenterYOffset: Float = -0.42

        for r in 0..<numRows {
            let yShelf = firstShelfY + Float(r) * shelfPitch
            let plank = SCNBox(width: 5.4, height: 0.07, length: 0.42, chamferRadius: 0.015)
            plank.materials = [woodShelf]
            let plankNode = SCNNode(geometry: plank)
            let plankCenterY = yShelf + plankCenterYOffset
            plankNode.position = SCNVector3(0, plankCenterY, bookZ + 0.02)
            plankNode.eulerAngles = SCNVector3(Float(-0.035), 0, 0)
            root.addChildNode(plankNode)
        }

        for (index, slot) in slots.enumerated() {
            let slotRow = index / 3
            let plankRow = numRows - 1 - slotRow
            let c = index % 3
            let yShelf = firstShelfY + Float(plankRow) * shelfPitch
            let plankCenterY = yShelf + plankCenterYOffset
            let shelfTopY = plankCenterY + plankHalfHeight
            let yBook = shelfTopY + Float(bookH) / 2 + 0.02
            let x = colX[c]

            if let book = slot {
                let box = bookBoxGeometry()
                applyBookBlockMaterials(to: box, book: book)
                let node = SCNNode(geometry: box)
                node.position = SCNVector3(x, yBook, bookZ)
                let uri = book.objectID.uriRepresentation().absoluteString
                node.name = "shelfBook|\(index)|\(uri)"
                addCoverPlane(to: node, book: book)
                root.addChildNode(node)
            }
        }

        let cam = SCNNode()
        cam.name = "cameraNode"
        cam.camera = SCNCamera()
        cam.camera?.fieldOfView = 38
        cam.camera?.zNear = 0.05
        cam.camera?.zFar = 80
        cam.camera?.wantsHDR = false
        cam.position = SCNVector3(0, 0.02, 6)
        cam.eulerAngles = SCNVector3(Float(-0.048), 0, 0)
        root.addChildNode(cam)

        return scene
    }

    /// Cover is the wide face toward the camera: `width` (X) × `height` (Y), thin depth along Z.
    /// No chamfer — rounded corners add extra faces; with only six materials those show up white.
    private static func bookBoxGeometry() -> SCNBox {
        SCNBox(width: bookW, height: bookH, length: bookT, chamferRadius: 0)
    }

    /// `SCNBox` material order: front (−Z), right (+X), back (+Z toward camera), left (−X), top (+Y), bottom (−Y).
    private static func applyBookBlockMaterials(to box: SCNBox, book: Book) {
        let spine = spineMaterial(for: book)
        let pagesEdge = pagesEdgeMaterial()
        let topBottom = pagesEdgeMaterial()
        let backPaper = woodMaterial(UIColor(red: 0.16, green: 0.14, blue: 0.13, alpha: 1))
        let shutFace = woodMaterial(UIColor(red: 0.1, green: 0.08, blue: 0.07, alpha: 1))
        box.materials = [backPaper, pagesEdge, shutFace, spine, topBottom, topBottom]
    }

    /// Unlit plane slightly in front of the box so covers stay visible regardless of PBR / key light angle.
    private static func addCoverPlane(to parent: SCNNode, book: Book) {
        let plane = SCNPlane(width: bookW, height: bookH)
        let m = SCNMaterial()
        m.lightingModel = .constant
        let cover = BookCoverUIImageLoader.syncImage(for: book) ?? standardCoverImage(for: book)
        m.diffuse.contents = cover
        m.isDoubleSided = true
        m.diffuse.magnificationFilter = .linear
        m.diffuse.minificationFilter = .linear
        plane.materials = [m]
        let pn = SCNNode(geometry: plane)
        pn.name = "coverPlane"
        pn.position = SCNVector3(0, 0, Float(bookT) * 0.5 + 0.009)
        parent.addChildNode(pn)
    }

    private static func pagesEdgeMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = pagesStripesTexture()
        m.lightingModel = .constant
        m.diffuse.magnificationFilter = .linear
        m.diffuse.minificationFilter = .linear
        return m
    }

    private static func spineMaterial(for book: Book) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = spineTexture(shortTitle: book.title ?? "Book")
        m.lightingModel = .constant
        m.diffuse.magnificationFilter = .linear
        m.diffuse.minificationFilter = .linear
        return m
    }

    private static func pagesStripesTexture() -> UIImage {
        let s = CGSize(width: 64, height: 64)
        let r = UIGraphicsImageRenderer(size: s)
        return r.image { ctx in
            let n = 12
            for i in 0..<n {
                let c = i % 2 == 0
                    ? UIColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1)
                    : UIColor(red: 0.86, green: 0.83, blue: 0.78, alpha: 1)
                c.setFill()
                let h = s.height / CGFloat(n)
                ctx.fill(CGRect(x: 0, y: CGFloat(i) * h, width: s.width, height: h))
            }
        }
    }

    private static func spineTexture(shortTitle: String) -> UIImage {
        let s = CGSize(width: 48, height: 256)
        let r = UIGraphicsImageRenderer(size: s)
        return r.image { ctx in
            let bg = UIColor(red: 0.14, green: 0.1, blue: 0.08, alpha: 1)
            bg.setFill()
            ctx.fill(CGRect(origin: .zero, size: s))
            UIColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 1).setStroke()
            let border = UIBezierPath(rect: CGRect(x: 3, y: 3, width: s.width - 6, height: s.height - 6))
            border.lineWidth = 2
            border.stroke()

            let line = String(shortTitle.prefix(18))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor(white: 0.88, alpha: 1),
            ]
            let str = NSAttributedString(string: line, attributes: attrs)
            let t = CGRect(x: 6, y: s.height * 0.35, width: s.width - 12, height: s.height * 0.5)
            str.draw(in: t)
        }
    }

    /// When there is no cover file / URL art yet.
    static func standardCoverImage(for book: Book) -> UIImage {
        let size = CGSize(width: 320, height: 480)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            let colors = [
                UIColor(red: 0.12, green: 0.11, blue: 0.14, alpha: 1).cgColor,
                UIColor(red: 0.22, green: 0.18, blue: 0.16, alpha: 1).cgColor,
            ]
            let gr = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(
                gr,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            UIColor(red: 1, green: 0.42, blue: 0.05, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: 10))

            let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .medium)
            if let sym = UIImage(systemName: "book.closed.fill", withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                sym.draw(in: CGRect(x: (size.width - 72) / 2, y: 72, width: 72, height: 72))
            }

            let title = book.title ?? "Untitled"
            let author = book.author ?? ""
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.white,
            ]
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor(white: 0.75, alpha: 1),
            ]
            let t = title.count > 52 ? String(title.prefix(50)) + "…" : title
            (t as NSString).draw(in: CGRect(x: 28, y: 200, width: size.width - 56, height: 120), withAttributes: titleAttrs)
            if !author.isEmpty {
                let a = author.count > 40 ? String(author.prefix(38)) + "…" : author
                (a as NSString).draw(in: CGRect(x: 28, y: 310, width: size.width - 56, height: 80), withAttributes: subAttrs)
            }
            let tag = "No cover"
            let tagAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: UIColor(white: 0.55, alpha: 1),
            ]
            (tag as NSString).draw(in: CGRect(x: 28, y: size.height - 56, width: 200, height: 24), withAttributes: tagAttrs)
        }
    }

    private static func woodMaterial(_ color: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.lightingModel = .constant
        return m
    }

}

// MARK: - Cover loading

enum BookCoverUIImageLoader {
    static func syncImage(for book: Book) -> UIImage? {
        if let path = book.localCoverImagePath {
            return CacheService.shared.getImage(path: path)
        }
        if let urlStr = book.coverImageURL, !urlStr.isEmpty {
            return CacheService.shared.getImage(for: urlStr)
        }
        return nil
    }

    static func loadAsync(for book: Book) async -> UIImage? {
        if let sync = syncImage(for: book) { return sync }
        guard let urlStr = book.coverImageURL, !urlStr.isEmpty else { return nil }
        return await CoverImageLoadService.shared.image(forURLString: urlStr)
    }
}
