Hello,

Thank you for the review and for sharing the launch crash details.

We investigated the iPad launch path and adjusted the ad startup flow. Banner ads remain enabled, but Google Mobile Ads now starts after the first SwiftUI screen appears. Each banner also waits for a valid root view controller before loading.

The app no longer requests App Tracking Transparency during launch. These changes are intended to prevent the iPad launch crash while keeping ads available.

We will submit a new build after testing.
