//
//  ViewController.swift
//  TextReader
//
//  Created by marskey on 2019/3/29.
//  Copyright © 2019 Marskey. All rights reserved.
//

import UIKit
import SnapKit
import WebKit

class ViewController: UIViewController {

    var textView:UITextView = UITextView.init()
    var webView:WKWebView = WKWebView.init()
    var activity = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.whiteLarge)
    
    let cancelBtn = UIButton.init(type: UIButton.ButtonType.custom)
    
    let timeOut:TimeInterval = 5
    
    var timer:Timer?
    
    @IBOutlet var controlView: UIView!
    // MARK: LifeCyle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configSubViews()
        configLayouts()
        
        configReader()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    // MARK: PrivateMethod
    func configSubViews()  {
        
        configBackground()
        configTextView()
        configWebView()
        configActivity()
        configCancelLoadBtn()
        view.bringSubviewToFront(controlView)
    }
    
    func configBackground() {
        let img = UIImageView.init(image: UIImage.init(named: "background"))
        img.frame = view.bounds
        view.addSubview(img)
    }
    
    func configActivity() {
        view.addSubview(activity)
        activity.isHidden = true
    }
    
    func configTextView()  {
        view.addSubview(textView)
        textView.alpha = 0
        textView.isEditable = false
        textView.backgroundColor = UIColor.clear
    }
    
    func configWebView()  {
        view.addSubview(webView)
        webView.navigationDelegate = self
        webView.alpha = 0
    }
    
    func configCancelLoadBtn(){
        view.addSubview(cancelBtn)
        cancelBtn.isHidden = true
        cancelBtn.setTitle("cancel loading", for: .normal)
        cancelBtn.setTitleColor(UIColor.black, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelLoadWebview), for: .touchUpInside)
    }
    
    func configLayouts()  {
        textView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(22)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
        
        
        webView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
        activity.center = view.center
        
        cancelBtn.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-22)
            make.left.equalToSuperview().offset(12)
        }
    }
    
    func configReader() -> Void {
        Reader.share.contentModified = {[weak self] in
            self?.configNewContent($0)
        }
    }
    
    // MARK: ResponseMethod
    func configNewContent(_ content:ReadContentModel) -> Void {
        if content.type == .text {
            receiveTextAction(content.value)
            return
        }
        if content.type == .url {
            receiveURLAction(content.value)
            return
        }
    }
    
    @objc func cancelLoadWebview(){
        if webView.isLoading == false {return}
        webView.stopLoading()
    }
    
    /// config Text Receive Action
    func receiveTextAction(_ text:String) {
        setTextView(text)
    }
    
    /// Config TextView Text
    ///
    /// - Parameters:
    ///   - text: String
    ///   - animated: Bool
    func setTextView(_ text:String, _ animated:Bool = true) -> Void {
        DispatchQueue.main.async {
            self.textView.text = text
            if animated == false {
                self.textView.alpha = 1
                return
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.textView.alpha = 1
            }) { (finished) in
                Utils.FFLog("textview show animation finished")
            }
        }
    }
    
    
    
    /// Config URL Receive Action
    ///
    /// - Parameter url: URL String
    func receiveURLAction(_ url:String) {
        guard let url = URL.init(string: url) else {
            return
        }
        webView.load(URLRequest.init(url:url))
        activity.isHidden = false
        activity.startAnimating()
    }
    
    
    @IBAction func playAction(_ sender: Any) {
        let btn = sender as! UIButton
        if Speecher.reader.isPaused {
            btn.setTitle("paus", for: .normal)
            Speecher.reader.continueSpeaking()
        }else if Speecher.reader.isReading{
            btn.setTitle("play", for: .normal)
            Speecher.reader.pause()
        }else{
            guard let content = Reader.share.currentContent.readContent else{return}
            btn.setTitle("play", for: .normal)
            Speecher.reader.speak(content)
        }
    }
    
    @IBAction func stopAction(_ sender: Any) {
        Speecher.reader.stop()
    }
    
    @IBAction func favourAction(_ sender: Any) {
            Utils.FFLog("")
    }
    
    @IBAction func quickAction(_ sender: Any) {
        let btn = sender as! UIButton
        let i = Speecher.reader.curRate
        guard var index = Speecher.reader.rates.firstIndex(of: i) else{return}
        if index == Speecher.reader.rates.count - 1 {
            index = 0
        }else{
            index += 1
        }
        let rate = Speecher.reader.rates[index]
        Speecher.reader.curRate = rate
        btn.setTitle("\(rate.rawValue)", for: .normal)
    }
    
    @IBAction func voiceAction(_ sender: Any) {
        let vc = voiceslist()
        vc.view.frame = CGRect.init(origin: CGPoint.init(x: 0, y: 200), size: CGSize.init(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 200))
        self.modalTransitionStyle = .coverVertical
        self.definesPresentationContext = true
//        self.modalPresentationStyle = .overCurrentContext
        vc.modalPresentationStyle = .overCurrentContext
        vc.view.alpha = 0.5
        self.present(vc, animated: true) {
            
        }
        
    }
    
}



extension ViewController : WKNavigationDelegate {
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Utils.FFLog("Start Load Web")
        cancelBtn.isHidden = false
        
        timerInvalidate()
        timer = Timer.init(timeInterval: timeOut, repeats: false, block: { (timer) in
            webView.stopLoading()
            timer.invalidate()
        })
        RunLoop.current.add(timer!, forMode: .default)
    }
    
    
    
    func timerInvalidate(){
        if let timer = self.timer {
            timer.invalidate()
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activity.stopAnimating()
        activity.isHidden = true
        cancelBtn.isHidden = true
        timerInvalidate()
        let jsstr = "document.documentElement.innerText" // get main text
        webView.evaluateJavaScript(jsstr) {[weak self] (result, error) in
            if error != nil {
                Utils.FFLog("Pasing Main Content Failure !")
            }else if let content = result as? String{
                Utils.FFLog("Pasing Main Content Success ! conent:\(content)")
                Reader.share.currentContent.webViewContent = content
                self?.setTextView(content)
            }
        }
        
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Utils.FFLog("error:\(error)")
        activity.stopAnimating()
        activity.isHidden = true
        cancelBtn.isHidden = true
        timerInvalidate()
    }
 
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Utils.FFLog("error:\(error)")
        activity.stopAnimating()
        activity.isHidden = true
        cancelBtn.isHidden = true
        timerInvalidate()
    }
    
}

