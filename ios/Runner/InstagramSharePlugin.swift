import Flutter
import Photos
import UIKit

/// 인스타그램 스토리·피드 편집 화면으로 사진을 바로 넘긴다.
///
/// OS 공유 시트를 띄우지 않는다.
/// - 스토리: Meta가 문서로 지원하는 방식. 이미지를 클립보드에 특정 키로 담고
///   `instagram-stories://share`를 연다.
/// - 피드: 인스타그램은 앨범에 있는 사진만 참조할 수 있어서, 먼저 앨범에
///   저장하고 그 로컬 식별자로 `instagram://library`를 연다.
///
/// 어느 쪽이든 마지막 공유 버튼은 사용자가 인스타그램 안에서 누른다.
enum InstagramShare {
  private static let channelName = "gamdo/instagram_share"
  private static let storyScheme = "instagram-stories://share"
  private static let feedScheme = "instagram://library"
  private static let appScheme = "instagram://app"

  private static let opened = "opened"
  private static let notInstalled = "notInstalled"
  private static let failed = "failed"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: registrar.messenger())

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isInstalled":
        result(isInstagramInstalled())

      case "shareToStory":
        guard let image = image(from: call.arguments) else {
          result(failed); return
        }
        let sourceId = (call.arguments as? [String: Any])?[
          "sourceApplicationId"] as? String
        shareToStory(image: image, sourceApplicationId: sourceId, completion: result)

      case "shareToFeed":
        guard let image = image(from: call.arguments) else {
          result(failed); return
        }
        shareToFeed(image: image, completion: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - 공통

  private static func isInstagramInstalled() -> Bool {
    guard let url = URL(string: appScheme) else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private static func image(from arguments: Any?) -> UIImage? {
    guard let args = arguments as? [String: Any],
      let path = args["path"] as? String,
      let data = FileManager.default.contents(atPath: path),
      let image = UIImage(data: data)
    else { return nil }
    return image
  }

  private static func open(_ urlString: String, completion: @escaping FlutterResult) {
    guard let url = URL(string: urlString),
      UIApplication.shared.canOpenURL(url)
    else {
      completion(notInstalled); return
    }
    UIApplication.shared.open(url, options: [:]) { ok in
      completion(ok ? opened : failed)
    }
  }

  // MARK: - 스토리

  private static func shareToStory(
    image: UIImage,
    sourceApplicationId: String?,
    completion: @escaping FlutterResult
  ) {
    guard let data = image.pngData() else {
      completion(failed); return
    }

    // 인스타그램은 이 키로 클립보드를 읽는다. 만료 시간을 짧게 둬야
    // 사용자의 클립보드에 사진이 남지 않는다.
    let items: [String: Any] = ["com.instagram.sharedSticker.backgroundImage": data]
    UIPasteboard.general.setItems(
      [items],
      options: [.expirationDate: Date().addingTimeInterval(60 * 5)]
    )

    var urlString = storyScheme
    if let id = sourceApplicationId, !id.isEmpty {
      urlString += "?source_application=\(id)"
    }
    open(urlString, completion: completion)
  }

  // MARK: - 피드

  private static func shareToFeed(
    image: UIImage,
    completion: @escaping FlutterResult
  ) {
    guard isInstagramInstalled() else {
      completion(notInstalled); return
    }

    // 인스타그램 피드 컴포저는 앨범의 사진만 열 수 있다 (로컬 식별자 기준).
    // 그래서 임시 파일이 아니라 앨범에 한 장 저장한 뒤 그것을 가리킨다.
    let authorize: (@escaping (Bool) -> Void) -> Void = { done in
      if #available(iOS 14, *) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
          done(status == .authorized || status == .limited)
        }
      } else {
        PHPhotoLibrary.requestAuthorization { status in
          done(status == .authorized)
        }
      }
    }

    authorize { granted in
      guard granted else {
        DispatchQueue.main.async { completion(failed) }
        return
      }

      var localIdentifier: String?
      PHPhotoLibrary.shared().performChanges {
        let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
        localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
      } completionHandler: { success, _ in
        DispatchQueue.main.async {
          guard success, let id = localIdentifier else {
            completion(failed); return
          }
          // 식별자에 /, & 등이 들어 있어 그대로 붙이면 URL이 깨진다
          let encoded =
            id.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? id
          open("\(feedScheme)?LocalIdentifier=\(encoded)", completion: completion)
        }
      }
    }
  }
}
