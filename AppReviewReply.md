Hello,

Thank you for the review and for sharing the launch crash details.

We investigated the iPad launch path and made changes to prevent the app from loading Google Mobile Ads before the root view controller is available. The app now starts the ads SDK once, waits for SDK initialization before loading banners, and requests App Tracking Transparency only after the app becomes active.

We also fixed Japanese text that could render incorrectly, removed risky force unwraps from the game setup path, updated the Google Mobile Ads package baseline, and increased the build number for the new submission.

We will submit a new build after device testing.
