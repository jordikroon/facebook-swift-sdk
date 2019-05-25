// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

struct BridgeAPIRequest {
  let actionID: String
  let methodName: String
  let methodVersion: String
  let parameters: [String: AnyHashable]
  let urlProvider: BridgeAPIURLProviding
  let scheme: String
  let userInfo: [String: AnyHashable]
  let settings: SettingsManaging
  let bundle: InfoDictionaryProviding

  init?(
    actionID: String = UUID().uuidString,
    methodName: String,
    methodVersion: String,
    parameters: [String: AnyHashable],
    bridgeAPIType: BridgeAPIType,
    userInfo: [String: AnyHashable],
    settings: SettingsManaging = Settings.shared,
    bundle: InfoDictionaryProviding = Bundle.main
    ) {
    guard let networker = bridgeAPIType.networker else {
      return nil
    }

    self.scheme = bridgeAPIType.scheme
    self.actionID = actionID
    self.methodName = methodName
    self.methodVersion = methodVersion
    self.parameters = parameters
    self.urlProvider = networker
    self.userInfo = userInfo
    self.settings = settings
    self.bundle = bundle
  }

  func requestURL() throws -> URL {
    let url = try urlProvider.requestURL(
      actionID: actionID,
      methodName: methodName,
      methodVersion: methodVersion,
      parameters: parameters
    )

    try bundle.validateFacebookURLScheme(settings: settings)

    guard let appIdentifier = settings.appIdentifier else {
      throw RequestError.invalidAppID
    }

    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      throw RequestError.invalidSourceURL
    }

    var queryItems = components.queryItems ?? []
    var additionalQueryItems = [
      URLQueryItem(name: "cipher_key", value: "foo"),
      URLQueryItem(name: "app_id", value: appIdentifier)
    ]

    if let suffix = settings.urlSchemeSuffix,
      !suffix.isEmpty {
      additionalQueryItems.append(
        URLQueryItem(name: "scheme_suffix", value: settings.urlSchemeSuffix)
      )
    }

    queryItems.append(contentsOf: additionalQueryItems)

    guard let updatedURL = URLBuilder().buildURL(
      scheme: scheme,
      hostName: components.host ?? "",
      path: components.path,
      queryItems: queryItems
      ) else {
        throw RequestError.urlBuildingFailed
    }

    return updatedURL
  }

  enum RequestError: FBError {
    case invalidAppID
    case invalidSourceURL
    case urlBuildingFailed
  }
}

//+ (id<FBSDKBridgeAPIProtocol>)_protocolForType:(FBSDKBridgeAPIProtocolType)type scheme:(NSString *)scheme
//{
//  id<FBSDKBridgeAPIProtocol> protocol = [self protocolMap][@(type)][scheme];
//  if (type == FBSDKBridgeAPIProtocolTypeWeb) {
//    return protocol;
//  }
//  NSURLComponents *components = [[NSURLComponents alloc] init];
//  components.scheme = scheme;
//  components.path = @"/";
//  if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
//    return protocol;
//  }
//  return nil;
//}

// TODO: CipherKey stuff
//+ (NSString *)_cipherKey
//  {
//    if (g_cipherKey) {
//      return g_cipherKey;
//    }
//    g_cipherKey = [[[NSUserDefaults standardUserDefaults] stringForKey:FBSDKBridgeAPICryptoCipherKeyKey] copy];
//    if (g_cipherKey) {
//      return g_cipherKey;
//    }
//    return [self _resetCipherKey];
//}
