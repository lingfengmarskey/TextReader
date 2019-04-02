//
//  Reader.swift
//  TextReader
//
//  Created by marskey on 2019/4/1.
//  Copyright © 2019 Marskey. All rights reserved.
//

import Foundation


public enum LocalPasteValueType:String {
    case text = "kTextValueNotification"
    case url = "kURLValueNotification"
    case none = "kNone"
    
    var noti:NSNotification.Name {
        return self.pasteTypeNoti()
    }
    
    private func pasteTypeNoti() -> NSNotification.Name {
        return NSNotification.Name(rawValue: self.rawValue)
    }
}


typealias changeBlck = (ReadContentModel)->Void

public class Reader: NSObject {
    
    public static let share:Reader = Reader()
    
    private var _currentContent:ReadContentModel = ReadContentModel()
    
    var contentModified:changeBlck?
    
    public var currentContent:ReadContentModel {
        get {
            return _currentContent
        }
        set {
            setCurrentContent(newValue)
        }
    }
    
    
    func setCurrentContent(_ newValue:ReadContentModel){
        if newValue == _currentContent {
            Utils.FFLog("has a same value, not set")
            return
        }
        _currentContent = newValue
        self.contentModified?(newValue)
        Utils.FFLog("setNewvalue")
    }
    
    
    override init() {
        super.init()
    }
    
}


/// Read content Model
/// used in reading for 
public class ReadContentModel {
    
    var type:LocalPasteValueType = .none
    
    var value:String = "" {
        didSet{
            configValue(value)
        }
    }
    
    var webViewContent:String?
    
    var readContent:String? {
        switch type {
        case .text:
            return value
        case .url:
            return webViewContent
        default:
            return nil
        }
    }
    
    public func setValue(newValue:String)  {
        self.value = newValue
    }
    
    static public func == (lhs:ReadContentModel, rhs:ReadContentModel) -> Bool{
        return lhs.value == rhs.value
    }
    
    private func configValue(_ content:String) {
        if content.isEmpty {
            type = .none
            webViewContent = ""
            return
        }
        if validateUrl(content) {
            type = .url
            return
        }
        type = .text
        webViewContent = ""
    }
    
    private func validateUrl(_ urlstring:String) -> Bool {
        guard let url = URL.init(string: urlstring) else{return false}
        if url.host == nil { return false }
        if url.scheme == nil { return false }
        return true
    }
}
