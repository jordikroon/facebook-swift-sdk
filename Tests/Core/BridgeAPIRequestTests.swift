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

// swiftlint:disable force_unwrapping

@testable import FacebookCore
import XCTest

class BridgeAPIRequestTests: XCTestCase {
  var fakeBridgeAPI = FakeBridgeAPI()
  var request: BridgeAPIRequest!
  var fakeSettings = FakeSettings()
  var fakeBundle = FakeBundle()

  override func setUp() {
    super.setUp()

    let bridgeAPIType = BridgeAPIType.web(.https)
    request = BridgeAPIRequest(
      actionID: "foo",
      methodName: "method",
      methodVersion: "version",
      parameters: ["key": "value"],
      bridgeAPIType: bridgeAPIType,
      userInfo: ["key": "value"],
      settings: fakeSettings,
      bundle: fakeBundle
    )
  }

  // MARK: - Dependencies

  func testBundleDependency() {
    let request = BridgeAPIRequest(
      actionID: "foo",
      methodName: "bar",
      methodVersion: "1.0",
      parameters: [:],
      bridgeAPIType: .native(.facebook),
      userInfo: [:]
    )

    XCTAssertTrue(request?.bundle is Bundle,
                  "Should use the correct concrete implementation to satisfy the bundle dependency")
  }

  func testSettingsDependency() {
    let request = BridgeAPIRequest(
      actionID: "foo",
      methodName: "bar",
      methodVersion: "1.0",
      parameters: [:],
      bridgeAPIType: .native(.facebook),
      userInfo: [:]
    )

    XCTAssertTrue(request?.settings is Settings,
                  "Should use the correct concrete implementation to satisfy the settings dependency")
  }

  func testCreatingValid() {
    XCTAssertEqual(request.actionID, "foo",
                   "Should set the correct value for action id")
    XCTAssertEqual(request.methodName, "method",
                   "Should set the correct value for the method name")
    XCTAssertEqual(request.methodVersion, "version",
                   "Should set the correct value for the method version")
    XCTAssertEqual(request.parameters, ["key": "value"],
                   "Should set the correct value for the method parameters")
    XCTAssertEqual(request.urlProvider is FakeBridgeAPI,
                  "Should set the correct value for the bridge api")
    XCTAssertEqual(request.scheme, "https",
                   "Should set the correct value for the scheme")
    XCTAssertEqual(request.userInfo, ["key": "value"],
                   "Should set the correct value for the protocol type")
  }

  func testCreatingWithoutActionID() {
    let request1 = BridgeAPIRequest(
      methodName: "bar",
      methodVersion: "1.0",
      parameters: [:],
      bridgeAPIType: .native(.facebook),
      userInfo: [:]
    )

    let request2 = BridgeAPIRequest(
      methodName: "bar",
      methodVersion: "1.0",
      parameters: [:],
      bridgeAPIType: .native(.facebook),
      userInfo: [:]
    )

    XCTAssertNotEqual(request1!.actionID, request2!.actionID,
                      "Action identifiers should be unique among requests")
  }

  func testRequestURLRequestsURLFromBridgeAPI() {
    do {
      _ = try request.requestURL()

      XCTAssertEqual(fakeBridgeAPI.capturedActionID, request.actionID,
                     "Requesting a url should forward the action identifier to the bridge api")
      XCTAssertEqual(fakeBridgeAPI.capturedMethodName, request.methodName,
                     "Requesting a url should forward the method name to the bridge api")
      XCTAssertEqual(fakeBridgeAPI.capturedMethodVersion, request.methodVersion,
                     "Requesting a url should forward the method version to the bridge api")
      XCTAssertEqual(fakeBridgeAPI.capturedParameters, request.parameters,
                     "Requesting a url should forward the parameters to the bridge api")
    } catch {
      XCTAssertNotNil(error, "This should handle errors properly")
    }
  }

  func testRequestURLWithValidScheme() {
    fakeSettings.appIdentifier = "abc123"
    fakeBundle.infoDictionary = SampleInfoDictionary.validURLSchemes(schemes: ["fbabc123"])

    do {
      _ = try request.requestURL()
    } catch {
      XCTAssertNil(error, "Should provide a request url given a valid scheme")
    }
  }

  func testRequestURLWithInvalidScheme() {
    fakeSettings.appIdentifier = "abc123"
    fakeBundle.infoDictionary = [:]

    do {
      _ = try request.requestURL()
      XCTFail("Should not provide a request url when there is no valid url scheme")
    } catch let error as InfoDictionaryProvidingError {
      guard case .urlSchemeNotRegistered = error else {
        return XCTFail("Requesting a url with no valid scheme should provide a meaningful error")
      }
    } catch {
      XCTFail("Should provide a meaningful error")
    }
  }

  func testRequestProvidesURLUsingURLFromBridgeAPINetworker() {
    fakeSettings.appIdentifier = "abc123"
    fakeBundle.infoDictionary = SampleInfoDictionary.validURLSchemes(schemes: ["fbabc123"])
    let passThroughQueryItem = URLQueryItemBuilder.build(from: ["bar": "baz"])
    let expectedQueryItems = URLQueryItemBuilder.build(from:
      [
        "bar": "baz",
        "app_id": fakeSettings.appIdentifier!,
        "cipher_key": "foo"
      ]
    )
    fakeBridgeAPI.stubbedURL = URLBuilder().buildURL(scheme: "myApp", hostName: "example.com", queryItems: passThroughQueryItem)!

    do {
      let url = try request.requestURL()

      guard let components = URLComponents(
          url: url,
          resolvingAgainstBaseURL: false
          ),
        let queryItems = components.queryItems
        else {
          return XCTFail("Should be able to get query items from url")
      }

      XCTAssertEqual(
        queryItems.sorted { $0.name < $1.name },
        expectedQueryItems.sorted { $0.name < $1.name },
        "Request should include query items from the url provided by the bridge api"
      )
    } catch {
      XCTAssertNil(error, "Should provide a request url given a valid scheme")
    }
  }
}
