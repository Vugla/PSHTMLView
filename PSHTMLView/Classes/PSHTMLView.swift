//
//  HTMLView.swift
//  PSHTMLView
//
//  Created by Predrag Samardzic on 23/11/2017.
//  Copyright © 2017 Predrag Samardzic. All rights reserved.
//

import UIKit
import WebKit

public protocol PSHTMLViewDelegate: class {
    func presentAlert(_ alertController: UIAlertController)
    func heightChanged(height: CGFloat)
    func shouldNavigate(for navigationAction: WKNavigationAction) -> Bool
    func handleScriptMessage(_ message: WKScriptMessage)
    func loadingProgress(progress: Float)
    func didFinishLoad()
}

public class PSHTMLView: UIView {
    
    let webViewKeyPathsToObserve = ["estimatedProgress"]
    var webViewHeightConstraint: NSLayoutConstraint!
    
    public var baseUrl:URL? = nil {
        didSet {
            webView.loadHTMLString(html ?? "", baseURL: baseUrl)
        }
    }
    public weak var delegate: PSHTMLViewDelegate?
    public var webView: WKWebView! {
        didSet {
            addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            webView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            webViewHeightConstraint = webView.heightAnchor.constraint(equalToConstant: self.bounds.height)
            webViewHeightConstraint.isActive = true
            webView.scrollView.isScrollEnabled = false
            webView.allowsBackForwardNavigationGestures = false
            webView.contentMode = .scaleToFill
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.scrollView.delaysContentTouches = false
//            webView.scrollView.decelerationRate = .normal
            webView.scrollView.delegate = self
        }
    }
    public var html: String? {
        didSet {
            webView.loadHTMLString(html ?? "", baseURL: baseUrl)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
        let controller = WKUserContentController()
        addDefaultScripts(controller: controller)
        
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        
        webView = WKWebView(frame: CGRect.zero, configuration: config)
        
        for keyPath in webViewKeyPathsToObserve {
            webView.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
        }
    }
    
    deinit {
        for keyPath in webViewKeyPathsToObserve {
            webView.removeObserver(self, forKeyPath: keyPath)
        }
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
            
        case "estimatedProgress":
            delegate?.loadingProgress(progress: Float(webView.estimatedProgress))
            
        default:
            break
        }
    }
    
    private func addDefaultScripts(controller: WKUserContentController) {
        controller.addUserScript(PSHTMLViewScripts.viewportScript)
        controller.addUserScript(PSHTMLViewScripts.disableSelectionScript)
        controller.addUserScript(PSHTMLViewScripts.disableCalloutScript)
        controller.addUserScript(PSHTMLViewScripts.addToOnloadScript)
        
        //add contentHeight script and handler
        controller.add(self, name: PSHTMLViewScriptMessage.HandlerName.onContentHeightChange.rawValue)
        controller.addUserScript(PSHTMLViewScripts.heigthOnLoadScript)
        controller.addUserScript(PSHTMLViewScripts.heigthOnResizeScript)
    }
    
    public func addScript(_ scriptString: String, observeMessageWithName: PSHTMLViewScriptMessage.HandlerName? = nil) {
        webView.configuration.userContentController.addUserScript(WKUserScript(source: scriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        if let observeMessageWithName = observeMessageWithName {  webView.configuration.userContentController.add(self, name: observeMessageWithName.rawValue)
        }
    }
    
}

extension PSHTMLView: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.didFinishLoad()
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let delegate = delegate {
            return decisionHandler(delegate.shouldNavigate(for: navigationAction) ? .allow : .cancel)
        }
        return decisionHandler(.allow)
    }
}

extension PSHTMLView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == PSHTMLViewScriptMessage.HandlerName.onContentHeightChange.rawValue {
            guard let responseDict = message.body as? [String:Any], let height = responseDict["height"] as? Float, webViewHeightConstraint.constant != CGFloat(height) else {
                return
            }
            webViewHeightConstraint.constant = CGFloat(height)
            delegate?.heightChanged(height: CGFloat(height))
        }
        delegate?.handleScriptMessage(message)
    }
    
    
}

extension PSHTMLView: WKUIDelegate {
    /// Handle javascript:alert(...)
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
            completionHandler()
        }
        
        alertController.addAction(okAction)
        
        delegate?.presentAlert(alertController)
    }
    
    /// Handle javascript:confirm(...)
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
            completionHandler(true)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
            completionHandler(false)
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        delegate?.presentAlert(alertController)
    }
    
    /// Handle javascript:prompt(...)
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { action in
            let textField = alertController.textFields![0] as UITextField
            completionHandler(textField.text)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
            completionHandler(nil)
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        delegate?.presentAlert(alertController)
    }
    
    
}

extension PSHTMLView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
}

struct PSHTMLViewScripts {
    //strings
    private static let viewportScriptString = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); meta.setAttribute('initial-scale', '1.0'); meta.setAttribute('maximum-scale', '1.0'); meta.setAttribute('minimum-scale', '1.0'); meta.setAttribute('user-scalable', 'no'); document.getElementsByTagName('head')[0].appendChild(meta);"
    private static let disableSelectionScriptString = "document.documentElement.style.webkitUserSelect='none';"
    private static let disableCalloutScriptString = "document.documentElement.style.webkitTouchCallout='none';"
    private static let addToOnloadScriptString = "function addLoadEvent(func) { var oldonload = window.onload; if (typeof window.onload != 'function') { window.onload = func; } else { window.onload = function() { if (oldonload) { oldonload(); } func(); } } } addLoadEvent(nameOfSomeFunctionToRunOnPageLoad); addLoadEvent(function() { }); "
    private static let heigthOnLoadScriptString = "window.onload= function () {window.webkit.messageHandlers.\(PSHTMLViewScriptMessage.HandlerName.onContentHeightChange.rawValue).postMessage({justLoaded:true,height: document.body.offsetHeight});};"
    private static let heigthOnResizeScriptString = "function incrementCounter() {window.webkit.messageHandlers.\(PSHTMLViewScriptMessage.HandlerName.onContentHeightChange.rawValue).postMessage({height: document.body.offsetHeight});}; document.body.onresize = incrementCounter;"
    
    static let getContentHeightScriptString = "document.body.offsetHeight"
    
    
    //scripts
    static let viewportScript = WKUserScript(source: viewportScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    static let disableSelectionScript = WKUserScript(source: disableSelectionScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    static let disableCalloutScript = WKUserScript(source: disableCalloutScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    static let addToOnloadScript = WKUserScript(source: addToOnloadScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    static let heigthOnLoadScript = WKUserScript(source: heigthOnLoadScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    static let heigthOnResizeScript = WKUserScript(source: heigthOnResizeScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    
}

public struct PSHTMLViewScriptMessage {
    public struct HandlerName : RawRepresentable, Equatable, Hashable, Comparable {
        public var rawValue: String
        
        public var hashValue: Int
        
        public static func <(lhs: PSHTMLViewScriptMessage.HandlerName, rhs: PSHTMLViewScriptMessage.HandlerName) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
            self.hashValue = rawValue.hashValue
        }
        public init(rawValue: String) {
            self.rawValue = rawValue
            self.hashValue = rawValue.hashValue
        }
    }
}

extension PSHTMLViewScriptMessage.HandlerName {
    public static let onContentHeightChange = PSHTMLViewScriptMessage.HandlerName("onContentHeightChange")
}
