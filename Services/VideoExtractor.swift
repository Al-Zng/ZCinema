import Foundation
import WebKit

class VideoExtractor: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var completionHandler: ((Result<String, Error>) -> Void)?
    private var targetHost: ServerHost?
    
    func extractVideoUrl(from pageUrl: String, host: ServerHost, completion: @escaping (Result<String, Error>) -> Void) {
        self.completionHandler = completion
        self.targetHost = host
        
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.preferences.javaScriptEnabled = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        self.webView = webView
        
        if let url = URL(string: pageUrl) {
            webView.load(URLRequest(url: url))
            
            // Timeout after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                if self?.completionHandler != nil {
                    self?.completionHandler?(.failure(NSError(domain: "VideoExtractor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeout extracting video"])))
                    self?.completionHandler = nil
                    self?.webView = nil
                }
            }
        } else {
            completion(.failure(URLError(.badURL)))
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let host = targetHost else { return }
        
        let javascript: String
        switch host {
        case .doodstream:
            javascript = "document.querySelector('video')?.src || document.querySelector('source')?.src || ''"
        case .mixdrop:
            javascript = "document.querySelector('video')?.src || ''"
        case .streamtape:
            javascript = "document.querySelector('#videolink')?.value || document.querySelector('video')?.src || ''"
        case .cybervynx, .lulustream:
            javascript = "document.querySelector('video')?.src || ''"
        }
        
        webView.evaluateJavaScript(javascript) { [weak self] result, error in
            if let urlString = result as? String, !urlString.isEmpty, urlString.hasPrefix("http") {
                self?.completionHandler?(.success(urlString))
                self?.completionHandler = nil
                self?.webView = nil
            } else if let error = error {
                self?.completionHandler?(.failure(error))
                self?.completionHandler = nil
                self?.webView = nil
            } else {
                // Try to find iframe src
                webView.evaluateJavaScript("document.querySelector('iframe')?.src || ''") { result2, error2 in
                    if let urlString = result2 as? String, !urlString.isEmpty, urlString.hasPrefix("http") {
                        self?.completionHandler?(.success(urlString))
                    } else {
                        self?.completionHandler?(.failure(NSError(domain: "VideoExtractor", code: -2, userInfo: [NSLocalizedDescriptionKey: "No video source found"])))
                    }
                    self?.completionHandler = nil
                    self?.webView = nil
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        completionHandler?(.failure(error))
        completionHandler = nil
        self.webView = nil
    }
}