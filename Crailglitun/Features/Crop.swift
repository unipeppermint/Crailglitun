import UIKit

final class CropController: UIViewController, UIScrollViewDelegate {
    let image: UIImage
    let original: CropRegion?
    let scroll = UIScrollView()
    let imageView: UIImageView
    var onSave: ((CropRegion) -> Void)?
    var positioned = false
    init(image: UIImage,region: CropRegion?) { self.image = image; self.original = region; imageView = UIImageView(image: image); super.init(nibName: nil,bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Adjust Crop"; view.backgroundColor = Palette.background
        let note = label("Drag to reposition. Pinch to zoom.\nYour original photo is preserved.",14,.regular,Palette.secondary); note.textAlignment = .center
        scroll.delegate = self; scroll.clipsToBounds = true; scroll.showsVerticalScrollIndicator = false; scroll.showsHorizontalScrollIndicator = false; scroll.backgroundColor = Palette.line
        imageView.frame = CGRect(origin: .zero,size: image.size); scroll.addSubview(imageView); scroll.contentSize = image.size
        let save = button("Apply Crop",icon: "checkmark",filled: true) { [weak self] in self?.save() }
        [note,scroll,save].forEach { view.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([note.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 24),note.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 24),note.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -24),scroll.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,constant: 24),scroll.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor,constant: -24),scroll.topAnchor.constraint(equalTo: note.bottomAnchor,constant: 28),scroll.heightAnchor.constraint(equalTo: scroll.widthAnchor),scroll.centerXAnchor.constraint(equalTo: view.centerXAnchor),save.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 24),save.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -24),save.topAnchor.constraint(equalTo: scroll.bottomAnchor,constant: 28),save.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,constant: -24)])
        let width = scroll.widthAnchor.constraint(equalTo: view.widthAnchor,constant: -48); width.priority = .defaultHigh; width.isActive = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset",style: .plain,target: self,action: #selector(reset))
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); guard !positioned,scroll.bounds.width > 0 else { return }; positioned = true; reset(); if let r = original { scroll.zoomScale = max(scroll.minimumZoomScale,min(scroll.maximumZoomScale,scroll.bounds.width/(image.size.width * r.width))); scroll.contentOffset = CGPoint(x: r.x * image.size.width * scroll.zoomScale,y: r.y * image.size.height * scroll.zoomScale) } }
    @objc func reset() {
        let scale = max(scroll.bounds.width/image.size.width,scroll.bounds.height/image.size.height)
        scroll.minimumZoomScale = scale; scroll.maximumZoomScale = scale*6; scroll.zoomScale = scale
        scroll.contentOffset = CGPoint(x: max(0,(image.size.width*scale-scroll.bounds.width)/2),y: max(0,(image.size.height*scale-scroll.bounds.height)/2))
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    func save() {
        let w = image.size.width*scroll.zoomScale,h = image.size.height*scroll.zoomScale
        let region = CropRegion(x: max(0,min(1-scroll.bounds.width/w,scroll.contentOffset.x/w)),y: max(0,min(1-scroll.bounds.height/h,scroll.contentOffset.y/h)),width: min(1,scroll.bounds.width/w),height: min(1,scroll.bounds.height/h))
        onSave?(region); navigationController?.popViewController(animated: true)
    }
}
