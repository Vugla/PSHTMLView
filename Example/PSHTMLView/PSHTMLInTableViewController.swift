//
//  HTMLInTableViewController.swift
//  PSHTMLView
//
//  Created by Predrag Samardzic on 23/11/2017.
//  Copyright © 2017 Predrag Samardzic. All rights reserved.
//

import UIKit
import SafariServices
import WebKit
import MessageUI
import PSHTMLView

class PSHTMLCell: UITableViewCell {
    @IBOutlet weak var htmlView : PSHTMLView!
}

class PSHTMLInTableViewController: UIViewController {
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var tableView: UITableView!
    
    lazy private var htmlCell: PSHTMLCell = { [weak self] in
        var cell = self?.tableView.dequeueReusableCell(withIdentifier: "HTMLCell") as! PSHTMLCell
        cell.htmlView.delegate = self
        cell.htmlView.webView.navigationDelegate = self
        cell.htmlView.webView.uiDelegate = self
        cell.htmlView.webView.scrollView.delegate = self
        return cell
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        loadData()
    }
    
    func setupTable() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 300
        tableView.tableFooterView = UIView()
    }
    
    func loadData() {
        
        //loading html
        let html = """
        <HTML>
        <HEAD>
        <TITLE>Your Title Here</TITLE>
        </HEAD>
        <BODY BGCOLOR="FFFFFF">
        <DIV><CENTER><IMG ID="myImage" SRC="https://static.pexels.com/photos/675764/pexels-photo-675764.jpeg" ALIGN="BOTTOM" STYLE= "max-width: 100%;"> </CENTER></DIV>
        <HR>
        <a href="https://github.com/Vugla">Link Name</a>
            is a link to another nifty site
        <H1>This is a Header</H1>
        <H2>This is a Medium Header</H2>
        Send me mail at <a href="mailto:predragsamardzic13@gmail.com">
        predragsamardzic13@gmail.com</a>.
        <P> This is a new paragraph!
        <P> <B>This is a new paragraph!</B>
        <BR> <B><I>This is a new sentence without a paragraph break, in bold italics.</I></B>
        <HR>
        </BODY>
        </HTML>
"""
        progressView.isHidden = false
        progressView.setProgress(0, animated: false)
        htmlCell.htmlView.html = html
        
        //adding custom script - action when image clicked
        //adding observer and handling callback in delegate method handleScriptMessage
        let script = "var imgElement = document.getElementById(\"myImage\"); imgElement.onclick = function(e) { window.webkit.messageHandlers.\(PSHTMLViewScriptMessage.HandlerName.onImageClicked.rawValue).postMessage(e.currentTarget.getAttribute(\"src\")); };"
        htmlCell.htmlView.addScript(script, observeMessageWithName: .onImageClicked)
    }
    
}

extension PSHTMLInTableViewController : UITableViewDataSource, UITableViewDelegate  {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 1:
            return htmlCell
        default:
            return tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
    }
    
}

extension PSHTMLInTableViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

extension PSHTMLInTableViewController: PSHTMLViewDelegate {
    
    func heightChanged(height: CGFloat) {
        print(height)
        tableView.reloadData()
    }
  
    func handleScriptMessage(_ message: WKScriptMessage) {
        //opening image link in safari when clicked
        if message.name == PSHTMLViewScriptMessage.HandlerName.onImageClicked.rawValue {
            if let urlString = message.body as? String, let url = URL(string: urlString) {
                let svc = SFSafariViewController(url: url)
                present(svc, animated: true, completion: nil)
            }
        }
    }
    
    func loadingProgress(progress: Float) {
        progressView.isHidden = progress == 1
        progressView.setProgress(progress, animated: true)
    }
  
}

extension PSHTMLInTableViewController: WKNavigationDelegate {
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    progressView.setProgress(0, animated: false)
  }
  
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    print("Loading for \(navigation.debugDescription) fail with error : \(error)")
  }
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
      //example of intercepting link and launching ios mail app (should work on real device)
      if url.absoluteString.hasPrefix("mailto:") {
        if MFMailComposeViewController.canSendMail() {
          //todo send mail
          let composeVC = MFMailComposeViewController()
          composeVC.mailComposeDelegate = self
          if let recipient = url.absoluteString.components(separatedBy: ":").last {
            composeVC.setToRecipients([recipient])
          }
          composeVC.setSubject("Hello!")
          composeVC.setMessageBody("Hello, this webview was useful!", isHTML: false)
          self.present(composeVC, animated: true, completion: nil)
        } else {
          //example of calling javascript from swift (note that alert shown is native one tnx to WKUIDelegate, will show in simulator)
          htmlCell.htmlView.webView.evaluateJavaScript("alert(\"Mail services are not available\");")
        }
        return decisionHandler(.cancel)
      } else {
        //intentinally openining all other links in Safari
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true, completion: nil)
        return decisionHandler(.cancel)
      }

    }
    return decisionHandler(.allow)
  }
}

extension PSHTMLInTableViewController: WKUIDelegate {
  /// Handle javascript:alert(...)
  public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
    
    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
      completionHandler()
    }
    
    alertController.addAction(okAction)
    
    present(alertController, animated: true)
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
    
    present(alertController, animated: true)
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
    
    present(alertController, animated: true)
  }
  
  
}

extension PSHTMLInTableViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension PSHTMLViewScriptMessage.HandlerName {
    static let onImageClicked =  PSHTMLViewScriptMessage.HandlerName("onImageClicked")
}
