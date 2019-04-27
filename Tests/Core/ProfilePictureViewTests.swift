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

// swiftlint:disable force_unwrapping file_length type_body_length

@testable import FacebookCore
import XCTest

class ProfilePictureViewTests: XCTestCase {
  private var view: ProfilePictureView!
  private var fakeUserProfileProvider: FakeUserProfileProvider!
  private let fakeNotificationCenter = FakeNotificationCenter()
  private let fakeLogger = FakeLogger()
  private var frame = CGRect(
    origin: .zero,
    size: CGSize(width: 100, height: 100)
  )
  var placeholderImageData: Data!
  private let puppyImage = UIImage(
    named: "puppy.jpeg",
    in: Bundle(for: ProfilePictureViewTests.self),
    compatibleWith: nil
    )!

  override func setUp() {
    super.setUp()

    fakeUserProfileProvider = FakeUserProfileProvider()
    placeholderImageData = HumanSilhouetteIcon.image(
      size: frame.size,
      color: HumanSilhouetteIcon.placeholderImageColor
      )?
      .pngData()
    createView()

    verify()
  }

  func createView() {
    view = ProfilePictureView(
      frame: frame,
      userProfileProvider: fakeUserProfileProvider,
      notificationCenter: fakeNotificationCenter,
      logger: fakeLogger
    )
  }

  func verify() {
    // verify and then clean up values set during initialization
    verifyPlaceholderImage()
    fakeUserProfileProvider.fetchProfileImageCallCount = 0
    view.imageView.image = nil
  }

  // MARK: - Dependencies

  func testProfileServiceDependency() {
    view = ProfilePictureView(frame: frame)

    XCTAssertTrue(view.userProfileProvider is UserProfileService,
                  "A profile picture view should have the expected concrete implementation for its user profile provider")
  }

  func testNotificationCenterDependency() {
    view = ProfilePictureView(frame: frame)

    XCTAssertTrue(view.notificationCenter is NotificationCenter,
                  "A profile picture view should have the expected concrete implementation for its notification center dependency")
  }

  func testLoggerDependency() {
    view = ProfilePictureView(frame: frame)

    XCTAssertTrue(view.logger is Logger,
                  "A profile picture view should have the expected concrete implementation for its logger dependency")
  }

  // MARK: - View Configuration

  func testInitializingWithCoder() {
    let archiver = NSKeyedArchiver(requiringSecureCoding: false)
    let view = ProfilePictureView(coder: archiver)
    XCTAssertNil(view, "Should not be able to initialize a profile picture view from empty date")
  }

  func testNeedsImageUpdate() {
    view = ProfilePictureView(frame: frame)

    XCTAssertFalse(view.needsImageUpdate,
                   "A newly created profile picture view should not require an image update")
  }

  func testInitialConfiguration() {
    XCTAssertEqual(view.profileIdentifier.description, GraphPath.me.description,
                   "The initial profile identifier should be the graph path for 'me'")
    XCTAssertEqual(view.backgroundColor, .white,
                   "The view should have an initial background color of white")
    XCTAssertEqual(view.contentMode, .scaleAspectFit,
                   "The view should have the initial content mode of scale aspect fit")
    XCTAssertFalse(view.isUserInteractionEnabled,
                   "The view should not enable user interaction by default")
  }

  func testInitialConfigurationImageView() {
    XCTAssertEqual(view.imageView.frame, view.bounds,
                   "The frame of the image view should be pinned to the bounds of the profile view")
    XCTAssertEqual(view.imageView.autoresizingMask, [.flexibleWidth, .flexibleHeight],
                   "Image view should have the expected autoresizing mask")
    XCTAssertTrue(view.subviews.contains(view.imageView),
                  "Image view should be added as a subview of the profile view")
  }

  // MARK: - Placeholder Image

  func testPlaceholderImage() {
    view.setPlaceholderImage()

    verifyPlaceholderImage("Setting a placeholder image should set the expected image on the image view")

    XCTAssertTrue(view.placeholderImageIsValid,
                  "Should consider a just-set placeholder to be valid")
    XCTAssertFalse(view.hasProfileImage,
                   "View is not considered to have a profile image when it has a placeholder image")
  }

  // MARK: - Setting Needs Image Update

  func testSetNeedImageUpdateWithNoBounds() {
    fakeUserProfileProvider = FakeUserProfileProvider()
    view = ProfilePictureView(
      frame: CGRect(origin: .zero, size: .zero),
      userProfileProvider: fakeUserProfileProvider
    )
    view.setNeedsImageUpdate()

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 0,
                   "Should not attempt to fetch a profile image if there is no space to show a fetched image")
    XCTAssertNil(view.imageView.image,
                 "Should not set an image if there is no space to show an image")
  }

  func testSetNeedsImageUpdateWithInvalidPlaceholderAndProfileImage() {
    view.placeholderImageIsValid = false
    view.hasProfileImage = true
    view.setNeedsImageUpdate()

    verifyPlaceholderImage("Should set a placeholder image if the current placeholder image is invalid")

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 1,
                   "Should attempt to fetch a profile image when an image update is needed")
  }

  func testSetNeedsImageUpdateWithPlaceholderAndNoProfileImage() {
    view.placeholderImageIsValid = true
    view.hasProfileImage = false

    view.setNeedsImageUpdate()

    XCTAssertNotEqual(view.imageView.image?.pngData(), placeholderImageData,
                      "Should only set a placeholder image when there is no profile image and no valid placeholder image")
    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 1,
                   "Should attempt to fetch a profile image when an image update is needed")
  }

  func testSetNeedsImageUpdateWithInvalidPlaceholderAndNoProfileImage() {
    view.placeholderImageIsValid = false
    view.hasProfileImage = false

    view.setNeedsImageUpdate()

    verifyPlaceholderImage("Should set a placeholder image when there is no profile image and no valid placeholder image")
  }

  func testSetNeedsImageUpdateFetchSuccess() {
    view.setNeedsImageUpdate()

    fakeUserProfileProvider.capturedFetchProfileImageCompletion?(
      .success(puppyImage)
    )

    XCTAssertEqual(view.imageView.image?.pngData(), puppyImage.pngData(),
                   "View should set a successfully fetched image on its child image view")
    XCTAssertTrue(view.hasProfileImage,
                  "View should be considered to have a profile image after a fetched image is set on its child view")
  }

  func testSetNeedsImageUpdateFetchFailure() {
    view.setNeedsImageUpdate()

    fakeUserProfileProvider.capturedFetchProfileImageCompletion?(
      .failure(SampleError())
    )

    XCTAssertFalse(view.hasProfileImage,
                   "View should not be considered to have a profile image if fetching a profile image failed")
    XCTAssertEqual(fakeLogger.capturedMessages.count, 1,
                   "Should invoke the logger on a failure to set an image")
  }

  // MARK: - Updating Image

  func testUpdatingImageWithInvalidPlaceholderImage() {
    view.updateImageIfNeeded()

    verifyPlaceholderImage()

    XCTAssertTrue(view.placeholderImageIsValid,
                  "Should consider a just-set placeholder to be valid")
  }

  func testUpdatingImageWithDifferentSizingConfiguration() {
    view.imageView.image = puppyImage

    // Starts to fetch an image with the current sizing configuration, this caches it locally
    view.updateImageIfNeeded()

    // Starts to fetch an image with a new sizing format which should invalidate the currently set image
    view.format = .square
    view.updateImageIfNeeded()

    verifyPlaceholderImage(
      "Should replace the currently set image with a placeholder when trying to update with a new sizing configuration"
    )
  }

  // MARK: - Responsive Properties

  func testSettingContentMode() {
    let contentModes: [UIView.ContentMode] = [
      .bottom,
      .bottomLeft,
      .bottomRight,
      .center,
      .left,
      .redraw,
      .right,
      .scaleAspectFill,
      .scaleAspectFit,
      .scaleToFill,
      .top,
      .topLeft,
      .topRight
    ]

    contentModes.forEach { mode in
      view.contentMode = mode

      XCTAssertEqual(view.imageView.contentMode, mode,
                     "Setting content mode: \(mode) on the view should set content mode: \(mode) on the image view")
    }
  }

  func testSettingIdenticalContentMode() {
    view.contentMode = view.contentMode

    XCTAssertNotEqual(view.imageView.image?.pngData(), placeholderImageData,
                      "Should not set a new placeholder when a content mode changes to an identical content mode")
  }

  func testSettingPlaceholderInvalidatingContentMode() {
    // Set content mode to a new content mode that is no longer considered to 'fit'
    view.contentMode = .scaleToFill

    verifyPlaceholderImage("Changing a content mode that 'fits' to a mode that does not 'fit' the image view should set an updated placeholder value")
  }

  func testSettingIdenticalBounds() {
    view.bounds = frame

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 0,
                   "Should not attempt to fetch a profile image when the bounds change to identical values")
  }

  func testSettingNewBounds() {
    frame = CGRect(
      origin: .zero,
      size: CGSize(
        width: 200,
        height: 200
      )
    )
    view.bounds = frame

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 1,
                   "Should attempt to fetch a profile image when the bounds change")
  }

  func testSettingIdenticalImageSizingFormat() {
    view.format = .normal

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 0,
                   "Should not attempt to fetch a profile image when the image sizing format changes to an identical value")
  }

  func testSettingNewImageSizingFormat() {
    view.format = .square

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 1,
                   "Should attempt to fetch a profile image when the image sizing format changes to a new value")
  }

  func testSettingIdenticalProfileIdentifier() {
    view.profileIdentifier = GraphPath.me.description

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 0,
                   "Should not attempt to fetch a profile image when the profile identifier changes to an identical value")
  }

  func testSettingNewProfileIdentifier() {
    view.imageView.image = nil

    view.placeholderImageIsValid = true

    view.profileIdentifier = "foo"

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 1,
                   "Should attempt to fetch a profile image when the profile identifier changes to a new value")
  }

  // MARK: - Responding to notifications

  func testObservesAccessTokenChanges() {
    XCTAssertEqual(
      fakeNotificationCenter.capturedAddObserverNotificationName,
      .FBSDKAccessTokenDidChangeNotification,
      "Should add an observer for access token changes by default"
    )
  }

  func testObservingAccessTokenChangeWithCustomProfileIdentifier() {
    // Setting a custom profile identifier will prevent the view from updating since it only responds to token
    // changes when the identifier is "me"
    view.profileIdentifier = "foo"

    // Reset the fake
    fakeUserProfileProvider.fetchProfileImageCallCount = 0

    let fakeNotification = Notification(
      name: .FBSDKAccessTokenDidChangeNotification,
      object: AccessToken.self,
      userInfo: [AccessTokenWallet.NotificationKeys.FBSDKAccessTokenDidChangeUserIDKey: true]
    )

    view.accessTokenDidChange(notification: fakeNotification)

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 0,
                   "Should not attempt to fetch a profile image when the access token changes to a token with a non-changed user identifier")
  }

  func testObservingAccessTokenChangeToIdenticalUserIdentifier() {
    let fakeNotification = Notification(
      name: .FBSDKAccessTokenDidChangeNotification,
      object: AccessToken.self,
      userInfo: [AccessTokenWallet.NotificationKeys.FBSDKAccessTokenDidChangeUserIDKey: false]
    )

    view.accessTokenDidChange(notification: fakeNotification)

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 0,
                   "Should not attempt to fetch a profile image when the access token changes to a token with a non-changed user identifier")
  }

  func testObservingAccessTokenChangeToNewUserIdentifier() {
    let fakeNotification = Notification(
      name: .FBSDKAccessTokenDidChangeNotification,
      object: AccessToken.self,
      userInfo: [AccessTokenWallet.NotificationKeys.FBSDKAccessTokenDidChangeUserIDKey: true]
    )

    view.accessTokenDidChange(notification: fakeNotification)

    XCTAssertEqual(fakeUserProfileProvider.fetchProfileImageCallCount, 1,
                   "Should attempt to fetch a profile image when the access token changes to a token with a new user identifier")
  }

  func verifyPlaceholderImage(
    _ message: String = "Should set expected placeholder image",
    _ file: StaticString = #file,
    _ line: UInt = #line
    ) {
    XCTAssertNotNil(
      view.imageView.image,
      message,
      file: file,
      line: line
    )

    XCTAssertEqual(
      self.view.imageView.image?.pngData(),
      placeholderImageData,
      "Should set the expected placeholder image",
      file: file,
      line: line
    )
  }
}
