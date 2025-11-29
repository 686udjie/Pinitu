import Flutter
import UIKit
import Photos

extension AppDelegate {
    func getAlbum(named albumName: String, completion: @escaping (PHAssetCollection?) -> Void) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let existingAlbum = collection.firstObject {
            completion(existingAlbum)
        } else {
            var albumPlaceholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }) { success, error in
                if success, let placeholder = albumPlaceholder {
                    let createdCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject
                    completion(createdCollection)
                } else {
                    completion(nil)
                }
            }
        }
    }

    func saveToAlbum(fileURL: URL, albumName: String, isVideo: Bool, completion: @escaping (Bool, Error?) -> Void) {
        getAlbum(named: albumName) { album in
            guard let album = album else {
                completion(false, nil)
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let assetRequest: PHAssetChangeRequest
                if isVideo {
                    assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)!
                } else {
                    assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)!
                }

                // Set creation date to now
                assetRequest.creationDate = Date()

                if let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                   let placeholder = assetRequest.placeholderForCreatedAsset {
                    albumChangeRequest.addAssets([placeholder] as NSArray)
                }
            }, completionHandler: completion)
        }
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.mousica.pinitu/gallery", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "saveToAlbum" {
          if let args = call.arguments as? [String: Any], let bytes = args["bytes"] as? FlutterStandardTypedData, let isVideo = args["isVideo"] as? Bool, let albumName = args["albumName"] as? String {
            self?.saveToAlbum(bytes: bytes, isVideo: isVideo, albumName: albumName, result: result)
          } else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments are invalid", details: nil))
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveToAlbum(bytes: FlutterStandardTypedData, isVideo: Bool, albumName: String, result: @escaping FlutterResult) {
    let data = Data(bytes.data)
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(isVideo ? "temp_video.mp4" : "temp_image.jpg")
    do {
      try data.write(to: tempURL)
      saveToAlbum(fileURL: tempURL, albumName: albumName, isVideo: isVideo) { success, error in
        if success {
          result("Saved to album")
        } else {
          result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription ?? "Unknown error", details: nil))
        }
      }
    } catch {
      result(FlutterError(code: "SAVE_FAILED", message: error.localizedDescription, details: nil))
    }
  }
}

