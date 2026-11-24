import Foundation
import FamilyControls

/// Explains *why* Screen Time authorization failed, so the user isn't left
/// with a button that silently does nothing.
enum ScreenTimeDiagnostics {

    /// Whether the provisioning profile this build was signed with grants
    /// `com.apple.developer.family-controls`.
    /// - `true` / `false` for development / ad-hoc / sideloaded builds,
    /// - `nil` when there is no embedded profile (App Store, TestFlight, Simulator).
    static var profileHasFamilyControls: Bool? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url) else { return nil }
        // The profile is a CMS-signed plist; the XML payload is readable as text.
        let text = String(decoding: data, as: UTF8.self)
        return text.contains("com.apple.developer.family-controls")
    }

    static var missingEntitlementMessage: String {
        """
        This copy of Rewire was signed without the Family Controls entitlement, \
        so iOS won't show the Screen Time permission dialog.

        How to fix it:
        • Sign it with a paid Apple Developer account whose App ID has the \
        "Family Controls" capability enabled (Xcode does this automatically), or
        • Build and run it from Xcode on a Mac.

        Free Apple IDs used by AltStore/SideStore/Sideloadly can't grant this entitlement.
        """
    }

    /// Human-readable explanation for an authorization error.
    static func message(for error: Error) -> String {
        if profileHasFamilyControls == false {
            return missingEntitlementMessage
        }
        guard let fc = error as? FamilyControlsError else {
            return "Screen Time authorization failed: \(error.localizedDescription)\n\n"
                + "If you sideloaded the app, the build is probably missing the Family Controls entitlement."
        }
        switch fc {
        case .restricted:
            return "Screen Time is restricted on this device (for example by a parent or a device-management profile)."
        case .unavailable:
            return "Screen Time isn't available. Make sure Screen Time is turned on in Settings → Screen Time, "
                + "and that this build has the Family Controls entitlement."
        case .invalidAccountType:
            return "This Apple ID can't authorize Screen Time for itself. Child accounts in Family Sharing "
                + "need a parent to approve on their device."
        case .invalidArgument:
            return "Screen Time rejected the request (invalid argument). Please reinstall the app."
        case .authorizationConflict:
            return "Another app is already managing Screen Time on this device. Remove its permission in "
                + "Settings → Screen Time and try again."
        case .authorizationCanceled:
            return "You cancelled the Screen Time dialog. Tap the button again and choose \"Continue\"."
        case .networkError:
            return "Couldn't reach Apple to verify your Apple ID. Check your internet connection and try again."
        case .authenticationMethodUnavailable:
            return "A device passcode is required. Set one in Settings → Face ID & Passcode, then try again."
        @unknown default:
            return "Screen Time authorization failed: \(error.localizedDescription)"
        }
    }
}
