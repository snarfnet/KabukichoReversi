Hello,

Thank you for the review and for the iPad launch crash report.

This build makes the app iPhone-only. We removed iPad from the target device family and removed iPad-specific supported orientations, because the current release is intended for iPhone.

Banner ads remain enabled on iPhone. As an additional safeguard, the ad SDK does not start when the runtime device idiom is iPad.

We will submit a new build for review.
