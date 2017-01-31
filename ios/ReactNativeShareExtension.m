#import "ReactNativeShareExtension.h"
#import <RCTRootView.h>
#import <MobileCoreServices/MobileCoreServices.h>


#define ITEM_IDENTIFIER @"public.url"

NSExtensionContext* extensionContext;

@implementation ReactNativeShareExtension {
  NSTimer *autoTimer;
  NSString* type;
  NSString* value;
}

- (UIView*) shareView {
  return nil;
}

RCT_EXPORT_MODULE();

- (void)viewDidLoad {
  [super viewDidLoad];

  //object variable for extension doesn't work for react-native. It must be assign to gloabl
  //variable extensionContext. in this way, both exported method can touch extensionContext
  extensionContext = self.extensionContext;

  UIView *rootView = [self shareView];
  if (rootView.backgroundColor == nil) {
    rootView.backgroundColor = [[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.1];
  }

  self.view = rootView;
}


RCT_EXPORT_METHOD(close) {
  [extensionContext completeRequestReturningItems:nil
                                completionHandler:nil];
}

RCT_REMAP_METHOD(data,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  [self extractUrlFromContext: extensionContext withCallback:^(NSDictionary* inventory, NSException* err) {
    resolve(inventory);
  }];
}

- (void)extractUrlFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSDictionary *inventory, NSException *exception))callback {
  @try {
    NSExtensionItem *item = [context.inputItems firstObject];

      NSLog(@"START");

      NSArray *attachments = item.attachments;
      __block NSString *selection = @"";
      __block NSString *returnUrl = @"";

      NSItemProvider *itemProvider;

      for (itemProvider in [item.userInfo valueForKey:NSExtensionItemAttachmentsKey]) {
          if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *) kUTTypeURL]) {
              [itemProvider loadItemForTypeIdentifier:(NSString *) kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                      returnUrl = [url absoluteString];
                      NSDictionary *inventory = @{
                                                @"type": @"text/plain",
                                                @"url": returnUrl,
                                                @"selection": selection
                                                };
                      NSLog( @"SENIDNG RESULTS / NO PROPERTY LIST %@", inventory);
                      callback(inventory, nil);
                      NSLog(@"FOUND URL! %@", returnUrl);
                  });
              }];
              NSLog(@"%@", itemProvider);
          }
      }

      for (NSItemProvider *itemProvider in item.attachments) {
          NSLog( @"%@", itemProvider);
          if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
              [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *jsDict, NSError *error) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                      NSDictionary *jsPreprocessingResults = jsDict[NSExtensionJavaScriptPreprocessingResultsKey];
                      NSString *url = jsPreprocessingResults[@"URL"];
                      if ([url length] > 0) {
                          returnUrl = url;
                      }

                      selection = jsPreprocessingResults[@"selection"];

                      NSLog(@"FOUND URL AFTER JS %@", returnUrl);
                      NSDictionary *inventory = @{
                                                  @"type": @"text/plain",
                                                  @"url": returnUrl,
                                                  @"selection": selection
                                                  };
                      NSLog( @"SENIDNG RESULTS %@", inventory);
                      callback(inventory, nil);
                  });
              }];
              break;
          }
      }
  }
  @catch (NSException *exception) {
    if(callback) {
        NSLog(@"ERROR!");
      callback(nil, exception);
    }
  }
}

@end
