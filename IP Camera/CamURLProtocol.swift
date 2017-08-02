//
//  CamURLProtocol.swift
//  IP Camera
//
//  Created by Brian Ha on 8/2/17.
//  Copyright © 2017 Hockey Run. All rights reserved.
//

import Foundation
import UIKit

// MARK: - URLProtocol

class CamURLProtocol: URLProtocol {
	
	// Protocol
	var showAlert: ((_ title:String, _ message: String) -> Void)?
	var showActivityView: ((_ status: Bool) -> Void)?
	
	// Properties
	private var dataTask: URLSessionDataTask?
	internal var urlResponse: URLResponse?
	internal var receivedData: NSMutableData?
	internal var urlRequest: URLRequest?
	internal var ibVideoImage: UIImageView!
	private var camera: Cam?
	//NSData(bytes: [0xFF, 0xD9] as [UInt8], length: 2)
	
	class var headerSet: String {
		return "customizeHeaderSet"
	}
	
	func setUp(with cam: Cam, url: URLRequest, videoImage: UIImageView) {
		self.camera = cam
		self.urlRequest = url
		self.ibVideoImage = videoImage
	}
	var cam: Cam? {
		get {
			return self.camera
		}
	}
	
	// MARK: - URLProtocol
	override class func canInit(with request: URLRequest) -> Bool {
		guard URLProtocol.property(forKey: CamURLProtocol.headerSet, in: request) != nil else {
			return true
		}
		return false
	}
	
	override class func canonicalRequest(for request: URLRequest) -> URLRequest {
		return request
	}
	
	override func startLoading() {
		guard let request = self.urlRequest?.url else {
			return
		}
		print("Start Loading")
		showActivityView?(true)
		let muReq = NSMutableURLRequest(url: request, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
		URLProtocol.setProperty("true", forKey: CamURLProtocol.headerSet, in: muReq)
		
		let config = URLSessionConfiguration.default
		let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
		
		dataTask = session.dataTask(with: muReq as URLRequest)
		dataTask?.resume()
	}
	
	override func stopLoading() {
		self.dataTask?.cancel()
		self.dataTask = nil
		receivedData = nil
		urlResponse = nil
	}
}

// MARK: - URLSessionDataDelegate

extension CamURLProtocol: URLSessionDataDelegate {
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		
		print("Begin Response Data")
		if self.receivedData == nil {
			self.urlResponse = response
			self.receivedData = NSMutableData()
		}
		self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
		completionHandler(.allow)
	}
}

// MARK: - URLSessionTaskDelegate

extension CamURLProtocol: URLSessionTaskDelegate {
	func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		if challenge.previousFailureCount == 0 {
			guard let cam = self.cam else {
				return
			}
			print("request authentication")
			let crediatial = URLCredential(user: cam.username!, password: cam.password!, persistence: URLCredential.Persistence.forSession)
			challenge.sender?.use(crediatial, for: challenge)
		}
		else {
			print("cancel authentication")
			challenge.sender?.cancel(challenge)
		}
	}
	
	func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
		guard error == nil else {
			print("error: \(error!)")
			self.client?.urlProtocol(self, didFailWithError: error!)
			return
		}
		print("completed")
		self.client?.urlProtocolDidFinishLoading(self)
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard error == nil else {
			self.client?.urlProtocol(self, didFailWithError: error!)
			let info = (error! as NSError).userInfo["NSLocalizedDescription"] as? String
			print("error: \(info ?? "Not found error")")
			DispatchQueue.main.async(execute: { 
				self.showAlert?("", info!)
				self.showActivityView?(false)
			})
			return
		}
		self.client?.urlProtocolDidFinishLoading(self)
	}
	
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		
		print("received data")
		let endMarkerData: NSData = NSData(bytes: [0xFF, 0xD9] as [UInt8], length: 2)
		self.receivedData?.append(data)
		let endRange: NSRange = self.receivedData!.range(of: endMarkerData as Data, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, self.receivedData!.length))
		let endLocation = endRange.location + endRange.length
		
		if self.receivedData!.length >= endLocation {
			let imageData = self.receivedData!.subdata(with: NSMakeRange(0, endLocation))
			let receivedImage = UIImage(data: imageData)
			DispatchQueue.main.async {
				self.ibVideoImage.image = receivedImage
				self.showActivityView?(false)
			}
			self.receivedData = NSMutableData(data: self.receivedData!.subdata(with: NSMakeRange(endLocation, self.receivedData!.length - endLocation)))
		}
		self.client?.urlProtocol(self, didLoad: data)
	}
}
