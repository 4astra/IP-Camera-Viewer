//
//  ViewController.swift
//  IP Camera
//
//  Created by Brian Ha on 8/2/17.
//  Copyright © 2017 Hockey Run. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	@IBOutlet weak var ibVideoImage: UIImageView!
	@IBOutlet weak var ibActivityView: UIActivityIndicatorView!
	var camURLProtocol: CamURLProtocol! {
		didSet {
			camURLProtocol.showAlert = { [weak self] info in
				guard let strong = self else {
					return
				}
				let alert = UIAlertController(title: info.0, message: info.1, preferredStyle: .alert)
				let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
				let retry = UIAlertAction(title: "Retry", style: UIAlertActionStyle.destructive, handler: { (action) in
					strong.camURLProtocol.startLoading()
				})
				alert.addAction(retry)
				alert.addAction(ok)
				strong.show(alert, sender: self)
			}
			
			camURLProtocol.showActivityView = { [weak self] status in
				guard let strong = self else {
					return
				}
				if status {
					strong.ibActivityView.isHidden = false
					strong.ibActivityView.startAnimating()
				}
				else {
					strong.ibActivityView.isHidden = true
					strong.ibActivityView.stopAnimating()
				}
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		var cam = Cam()
		cam.url = "27.74.244.142"
		cam.port = 8484
		cam.videoFolder = "axis-cgi/mjpg"
		cam.videoName = "video.cgi"
		cam.username = ""
		cam.password = ""
		cam.videoParams = ""
		let urlString = "http://217.197.157.7:7070/axis-cgi/mjpg/video.cgi"
		camURLProtocol = CamURLProtocol()
		camURLProtocol.setUp(with: cam, url: URLRequest(url: URL(string: urlString)!), videoImage: ibVideoImage)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		camURLProtocol.startLoading()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
}
