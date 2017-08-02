//
//  Cam.swift
//  IP Camera
//
//  Created by Brian Ha on 8/2/17.
//  Copyright © 2017 Hockey Run. All rights reserved.
//

import Foundation

struct Cam {
	//ip camera url
	var url: String?
	//ip camera port
	var port: Int?
	//ip camera username
	var username: String?
	//ip camera password
	var password: String?
	
	//to configure the following properties you have to refer do ipcam user manual
	//eg:cgi/mjpg
	var videoFolder: String?
	//eg:mjpg.cgi
	var videoName: String?
	//eg:camera=&resolution=680x480
	var videoParams: String?
}
