//
//  TMLWebWindowController.m
//  Pods
//
//  Created by Konstantin Kabanov on 20/03/2017.
//
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLWebWindowController.h"

@interface TMLWebWindowController ()

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation TMLWebWindowController

- (NSString *)windowNibName {
    return @"TMLWebWindowController";
}

- (instancetype)init {
    if (self = [super init]) {
        WKUserContentController *webContentController = [[WKUserContentController alloc] init];
        [webContentController addScriptMessageHandler:self name:@"tmlMessageHandler"];
        
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:@"var tmlMessageHandler = window.webkit.messageHandlers.tmlMessageHandler;" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [webContentController addUserScript:userScript];
        
        WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
        webViewConfig.userContentController = webContentController;
        
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webViewConfig];
        webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        webView.navigationDelegate = self;
        webView.UIDelegate = self;
        
        self.webView = webView;
        
        NSWindow *ourWindow = self.window;
        [ourWindow.contentView addSubview:webView];
    }
    return self;
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    completionHandler(YES);
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (message.body == nil) {
        TMLDebug(@"No body in posted message");
        return;
    }
    
    NSDictionary *result = nil;
    if ([message.body isKindOfClass:[NSDictionary class]] == YES) {
        result = message.body;
    }
    else {
        NSData *bodyData = [[NSData alloc] initWithBase64EncodedString:message.body options:0];
        NSString *body = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        if (body != nil) {
            result = [body tmlJSONObject];
        }
    }
    
    if (result == nil) {
        TMLDebug(@"Didn't find anything relevant in posted message");
        return;
    }
    
    if ([@"error" isEqualToString:result[@"status"]] == YES) {
        NSString *message = result[@"message"];
        if (message == nil) {
            message = @"Unknown Error";
        }
        [self postedErrorMessage:message];
    }
    else {
        [self postedUserInfo:result];
    }
}

#pragma mark - Message post handling

- (void)postedErrorMessage:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText = TMLLocalizedString(@"Error");
    alert.informativeText = message;
    
    [alert runModal];
}

- (void)postedUserInfo:(NSDictionary *)userInfo {
    TMLDebug(@"WebView posted message: %@", userInfo);
}

@end
