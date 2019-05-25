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

import Foundation

/// An abstraction used to resolve a concrete instance of a `BridgeAPINetworker` with known values
// TODO:
// A bridge api call can either be native or web
// it has a known scheme

enum BridgeAPIType {
  case native(BridgeAPINativeProtocolKey)
  case web(BridgeAPIWebProtocolScheme)

  var networker: BridgeAPIURLProviding {
    switch self {
    case let .native(scheme):
      switch scheme {
      case .facebook,
           .messenger,
           .msqrdPlayer:
        return BridgeAPINative()
      }

    case let .web(scheme):
      switch scheme {
      case .https:
        return BridgeAPIWebV1()

      case .web:
        return BridgeAPIWebV2()
      }
    }
  }

  var scheme: String {
    switch self {
    case let .native(scheme):
      switch scheme {
      case .facebook:
        return "fbapi20130214"

      case .messenger:
        return "fb-messenger-share-api"

      case .msqrdPlayer:
        return "msqrdplayer-api20170208"
      }

    case let .web(scheme):
      switch scheme {
      case .https:
        return "https"

      case .web:
        return "web"
      }
    }
  }

  enum BridgeAPINativeProtocolKey: String {
    case facebook = "fbauth2"
    case messenger = "fb-messenger-share-api"
    case msqrdPlayer = "msqrdplayer"
  }

  enum BridgeAPIWebProtocolScheme: String {
    case https
    case web
  }
}
