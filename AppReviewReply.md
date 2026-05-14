Hello,

Thank you for the review and the crash report.

This build removes the Google Mobile Ads SDK from the app target to eliminate the launch-time crash path. The app now launches without third-party ad SDK initialization.

The target remains iPhone-only with TARGETED_DEVICE_FAMILY set to iPhone.

We will submit a new build for review.
