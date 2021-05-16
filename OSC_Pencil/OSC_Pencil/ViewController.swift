//
//  ViewController.swift
//  OSC_Pencil
//
//  Created by Gwan-Gyu Lee(frd.lee@icloud.com) on 2021/02/11.
//
//  This application contains copyrighted software under MIT License version 1.3.
//  This application contains copyrighted software under MIT License.     
//  SwiftOSC - Copyright (c) 2017 Devin Roth    
//  Colorful - Copyright (c) 2011 Ryota Hayashi

import UIKit
import SwiftOSC
import Colorful

class ViewController: UIViewController {
    
    @IBOutlet var imgView: UIImageView!
    @IBOutlet var colorPicker: ColorPicker!
    @IBOutlet var slStroke: UISlider!
    
    @IBOutlet var txtIPAddress: UITextField!
    @IBOutlet var txtPort: UITextField!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var sideView: UIView!
    @IBOutlet var viewConstraint: NSLayoutConstraint!
    @IBOutlet var btnSetUDP: UIButton!
    
    var colorSpace: HRColorSpace = .sRGB
    var rgb: String = ""
    
    var alpha: Float = 1.0
    var stroke: Float = 10.0
    
    var ipAddress = "127.0.0.1"
    var port = 8800
    var oscPattern: String = ""
    var oscMessage: String = ""
    
    var lastPoint: CGPoint!
    var lineSize: CGFloat = 10.0
    var lineColor = UIColor.red.cgColor
    
    var location: String = ""
    var force: String = ""
    var azimuthUnitVector: String = ""
    var azimuthAngle: String = ""
    var altitudeAngle: String = ""
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        colorPicker.addTarget(self, action: #selector(self.handleColorChanged(picker:)), for: .valueChanged)
        colorPicker.set(color: UIColor(displayP3Red: 1.0, green: 1.0, blue: 0, alpha: 1), colorSpace: colorSpace)
        handleColorChanged(picker: colorPicker)
        
        blurView.layer.cornerRadius = 5
        
        txtIPAddress.layer.cornerRadius = 5
        txtIPAddress.clipsToBounds = true
        txtPort.layer.cornerRadius = 5
        txtPort.clipsToBounds = true
        btnSetUDP.layer.cornerRadius = 5
        
        viewConstraint.constant = -400
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        slStroke.value = 10.0
        
        
    }
    
    @IBAction func btnOSCSetting(_ sender: UIButton) {
        if viewConstraint.constant == -400 {
            viewConstraint.constant = 0
        } else {
            viewConstraint.constant = -400
        }
    }
    
    @IBAction func btnClear(_ sender: UIButton) {
        imgView.image = nil
    }
    @IBAction func btnUDPSet(_ sender: UIButton) {
        ipAddress = txtIPAddress.text!
        port = Int(txtPort.text!) ?? 0
    }
    
    @IBAction func slChangeStroke(_ sender: UISlider) {
        stroke = slStroke.value
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func handleColorChanged(picker: ColorPicker) {
        
        rgb = picker.color.description
        let range = rgb.startIndex..<rgb.index(rgb.startIndex, offsetBy: 25)
        rgb.removeSubrange(range)
    }

    func oscSend(_ oscPattern: String, _ oscMessage: String) {
        let client = OSCClient(address: ipAddress, port: port)
        let message = OSCMessage(OSCAddressPattern(oscPattern), oscMessage)
        //let bundle = OSCBundle(Timetag(secondsSinceNow: 5.0), message)
        client.send(message)
    }
    
    private func updateGagues(with touch: UITouch) {
        force = touch.force.valueFormattedForDisplay ?? ""
        
        let tmpAzimuthUnitVector = touch.azimuthUnitVector(in: imgView)
        azimuthUnitVector = tmpAzimuthUnitVector.valueFormattedForDisplay ?? ""
        
        let tmpAzimuthAngle = touch.azimuthAngle(in: imgView)
        azimuthAngle = tmpAzimuthAngle.valueFormattedForDisplay ?? ""
        
        // When using a finger, the angle is Pi/2 (1.571), representing a touch perpendicular to the device surface.
//        altitudeAngle = touch.altitudeAngle.valueFormattedForDisplay ?? ""
        
        let tmpLocation = touch.preciseLocation(in: imgView)
        location = tmpLocation.valueFormattedForDisplay ?? ""
        let tmplocation = location.replacingOccurrences(of: ",", with: "")
        
        lineColor = colorPicker.color.cgColor
        
        force.remove(at: force.startIndex)
        
        oscSend("/lineColor", rgb)
        oscSend("/location", tmplocation)
        oscSend("/force", force)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first! as UITouch
        
        lastPoint = touch.location(in: imgView)
        
        touches.forEach { (touch) in
            updateGagues(with: touch)
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let tmpForce = CGFloat((force as NSString).floatValue) + 1
        
        UIGraphicsBeginImageContext(imgView.frame.size)
        UIGraphicsGetCurrentContext()?.setStrokeColor(lineColor)
        UIGraphicsGetCurrentContext()?.setLineCap(CGLineCap.round)
        UIGraphicsGetCurrentContext()?.setLineWidth(CGFloat(stroke) * tmpForce)
        UIGraphicsGetCurrentContext()?.setAlpha(CGFloat(alpha))
        
        let tmpStroke = CGFloat(stroke) * tmpForce
        
        let touch = touches.first! as UITouch
        let currPoint = touch.location(in: imgView)
        
        imgView.image?.draw(in: CGRect(x: 0, y: 0, width: imgView.frame.size.width, height: imgView.frame.size.height))
        
        UIGraphicsGetCurrentContext()?.move(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x: currPoint.x, y: currPoint.y))
        UIGraphicsGetCurrentContext()?.strokePath()
        
        imgView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        lastPoint = currPoint
        
        touches.forEach { (touch) in
            updateGagues(with: touch)
        }
        
        oscSend("/stroke", "\(tmpStroke)")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let tmpForce = CGFloat((force as NSString).floatValue) + 1
        
        UIGraphicsBeginImageContext(imgView.frame.size)
        UIGraphicsGetCurrentContext()?.setStrokeColor(lineColor)
        UIGraphicsGetCurrentContext()?.setLineCap(CGLineCap.round)
        UIGraphicsGetCurrentContext()?.setLineWidth(CGFloat(stroke) * tmpForce)
        UIGraphicsGetCurrentContext()?.setAlpha(CGFloat(alpha))
        
        imgView.image?.draw(in: CGRect(x: 0, y: 0, width: imgView.frame.size.width, height: imgView.frame.size.height))
        
        UIGraphicsGetCurrentContext()?.move(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
        UIGraphicsGetCurrentContext()?.strokePath()
        
        imgView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        touches.forEach { (touch) in
            updateGagues(with: touch)
        }
    }
}

