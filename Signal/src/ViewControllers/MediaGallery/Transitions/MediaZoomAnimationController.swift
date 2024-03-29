//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

class MediaZoomAnimationController: NSObject {
    private let galleryItem: MediaGalleryItem

    init(galleryItem: MediaGalleryItem) {
        self.galleryItem = galleryItem
    }
}

extension MediaZoomAnimationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return kIsDebuggingMediaPresentationAnimations ? 1.5 : 0.15
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let fromVC = transitionContext.viewController(forKey: .from) else {
            owsFailDebug("fromVC was unexpectedly nil")
            return
        }

        let fromContextProvider: MediaPresentationContextProvider
        switch fromVC {
        case let contextProvider as MediaPresentationContextProvider:
            fromContextProvider = contextProvider
        case let navController as UINavigationController:
            guard let contextProvider = navController.topViewController as? MediaPresentationContextProvider else {
                owsFailDebug("unexpected contextProvider: \(String(describing: navController.topViewController))")
                return
            }
            fromContextProvider = contextProvider
        case let tabVC as UITabBarController:
            
            guard let contextProvider = (tabVC.selectedViewController as? UINavigationController)?.topViewController as? MediaPresentationContextProvider else {
                owsFailDebug("unexpected context: \(String(describing: tabVC))")
                return
            }
            fromContextProvider = contextProvider
        default:
            owsFailDebug("unexpected fromVC: \(fromVC)")
            return
        }

        guard let fromMediaContext = fromContextProvider.mediaPresentationContext(galleryItem: galleryItem, in: containerView) else {
            owsFailDebug("fromPresentationContext was unexpectedly nil")
            return
        }

        guard let toVC = transitionContext.viewController(forKey: .to) else {
            owsFailDebug("toVC was unexpectedly nil")
            return
        }

        guard let toContextProvider = toVC as? MediaPresentationContextProvider else {
            owsFailDebug("toContext was unexpectedly nil")
            return
        }

        guard let toView = transitionContext.view(forKey: .to) else {
            owsFailDebug("toView was unexpectedly nil")
            return
        }
        containerView.addSubview(toView)

        guard let toMediaContext = toContextProvider.mediaPresentationContext(galleryItem: galleryItem, in: containerView) else {
            owsFailDebug("toPresentationContext was unexpectedly nil")
            return
        }

        guard let presentationImage = galleryItem.attachmentStream.originalImage else {
            owsFailDebug("presentationImage was unexpectedly nil")
            return
        }

        let transitionView = UIImageView(image: presentationImage)
        transitionView.contentMode = .scaleAspectFill
        transitionView.layer.masksToBounds = true
        transitionView.layer.cornerRadius = fromMediaContext.cornerRadius

        containerView.addSubview(transitionView)
        transitionView.frame = fromMediaContext.presentationFrame

        let fromTransitionalOverlayView: UIView?
        if let (overlayView, overlayViewFrame) = fromContextProvider.snapshotOverlayView(in: containerView) {
            fromTransitionalOverlayView = overlayView
            containerView.addSubview(overlayView)
            overlayView.frame = overlayViewFrame
        } else {
            fromTransitionalOverlayView = nil
        }

        let toTransitionalOverlayView: UIView?
        if let (overlayView, overlayViewFrame) = toContextProvider.snapshotOverlayView(in: containerView) {
            toTransitionalOverlayView = overlayView
            containerView.addSubview(overlayView)
            overlayView.frame = overlayViewFrame
        } else {
            toTransitionalOverlayView = nil
        }

        // Because toggling `isHidden` causes UIStack view layouts to change, we instead toggle `alpha`
        fromTransitionalOverlayView?.alpha = 1.0
        fromMediaContext.mediaView.alpha = 0.0
        toView.alpha = 0.0
        toTransitionalOverlayView?.alpha = 0.0
        toMediaContext.mediaView.alpha = 0.0

        let duration = transitionDuration(using: transitionContext)

        fromContextProvider.mediaWillPresent(fromContext: fromMediaContext)
        toContextProvider.mediaWillPresent(toContext: toMediaContext)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                fromTransitionalOverlayView?.alpha = 0.0
                toView.alpha = 1.0
                toTransitionalOverlayView?.alpha = 1.0
                transitionView.frame = toMediaContext.presentationFrame
                transitionView.layer.cornerRadius = toMediaContext.cornerRadius
        },
            completion: { _ in
                fromContextProvider.mediaDidPresent(fromContext: fromMediaContext)
                toContextProvider.mediaDidPresent(toContext: toMediaContext)
                transitionView.removeFromSuperview()
                fromTransitionalOverlayView?.removeFromSuperview()
                toTransitionalOverlayView?.removeFromSuperview()

                toMediaContext.mediaView.alpha = 1.0
                fromMediaContext.mediaView.alpha = 1.0

                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
