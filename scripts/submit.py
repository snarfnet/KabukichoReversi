import hashlib
import os
import time

import requests

from asc_api import api, find_app_id, get_or_create_version, get_localization_id

APP_VERSION = os.environ.get("APP_VERSION", "1.0")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "")
SCREENSHOT_DIR = "AppStoreScreenshots"
SCREENSHOT_GROUPS = [
    ("APP_IPHONE_65", [
        "kabukicho-reversi-iphone-01.png",
        "kabukicho-reversi-iphone-02.png",
        "kabukicho-reversi-iphone-03.png",
        "kabukicho-reversi-iphone-04.png",
    ]),
    ("APP_IPAD_PRO_3GEN_129", [
        "kabukicho-reversi-ipad-01.png",
        "kabukicho-reversi-ipad-02.png",
        "kabukicho-reversi-ipad-03.png",
        "kabukicho-reversi-ipad-04.png",
    ]),
]
REVIEW_CONTACT = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+81 80-2368-9194",
}


def wait_for_build(app_id):
    print(f"Waiting for processed build (expecting build {BUILD_NUMBER or 'any'})...")
    latest_valid_id = None
    for attempt in range(90):
        payload = api("GET", f"/builds?filter[app]={app_id}&sort=-uploadedDate&limit=10")
        for item in payload.get("data", []):
            attrs = item["attributes"]
            version = attrs.get("version", "")
            state = attrs.get("processingState", "")
            print(f"  build {version}: {state}")
            if BUILD_NUMBER and version == str(BUILD_NUMBER) and state == "VALID":
                return item["id"]
            elif not BUILD_NUMBER and version and state == "VALID":
                return item["id"]
            if state == "VALID" and latest_valid_id is None:
                latest_valid_id = item["id"]
        print(f"  attempt {attempt + 1}/90, waiting 30s")
        time.sleep(30)
    if latest_valid_id:
        print("Target build not found, using latest valid build")
        return latest_valid_id
    raise RuntimeError("No valid processed build found")


def main():
    app_id = find_app_id()
    version_id = get_or_create_version(app_id, APP_VERSION)

    try:
        api("PATCH", f"/appStoreVersions/{version_id}", json={
            "data": {
                "type": "appStoreVersions",
                "id": version_id,
                "attributes": {"copyright": "2025 Tokyo Nasu"},
            }
        })
        print("Copyright set")
    except RuntimeError as e:
        if "409" in str(e):
            print("Copyright already set, skipping")
        else:
            raise

    build_id = wait_for_build(app_id)

    try:
        api("PATCH", f"/builds/{build_id}", json={
            "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
        })
    except RuntimeError as e:
        if "409" in str(e):
            print("usesNonExemptEncryption already set, skipping")
        else:
            raise

    try:
        api("PATCH", f"/apps/{app_id}", json={
            "data": {
                "type": "apps",
                "id": app_id,
                "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
            }
        })
    except RuntimeError as e:
        if "409" in str(e):
            print("contentRightsDeclaration already set, skipping")
        else:
            raise

    review_details = api("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    attrs = {
        **REVIEW_CONTACT,
        "demoAccountRequired": False,
        "demoAccountName": "",
        "demoAccountPassword": "",
        "notes": (
            "This build addresses Guideline 2.3.3. "
            "The 6.5-inch iPhone and 13-inch iPad screenshots were replaced with current in-app screens: "
            "title/character selection, active board play, valid move hints, and the result screen."
        ),
    }
    if review_details.get("data"):
        detail_id = review_details["data"]["id"]
        api("PATCH", f"/appStoreReviewDetails/{detail_id}", json={
            "data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}
        })
    else:
        api("POST", "/appStoreReviewDetails", json={
            "data": {
                "type": "appStoreReviewDetails",
                "attributes": attrs,
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
            }
        })

    for attempt in range(5):
        try:
            api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
                "data": {"type": "builds", "id": build_id}
            })
            print("Build linked to version")
            break
        except RuntimeError as e:
            if "409" in str(e):
                print("Build already linked to version, skipping")
                break
            elif attempt < 4:
                print(f"Build link attempt {attempt + 1} failed, retrying in 30s...")
                time.sleep(30)
            else:
                raise

    loc_id = get_localization_id(version_id)
    if loc_id:
        try:
            api("PATCH", f"/appStoreVersionLocalizations/{loc_id}", json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc_id,
                    "attributes": {
                        "whatsNew": "現在のゲーム画面に合わせてスクリーンショットを更新しました。",
                    },
                }
            })
            print("whatsNew set")
        except RuntimeError as e:
            if "409" in str(e):
                print("whatsNew already set, skipping")
            else:
                raise

    upload_screenshots(version_id)

    print("Waiting 5 minutes for screenshot processing...")
    time.sleep(300)

    # Clean up ALL review submissions
    canceled_any = False
    for state in ["WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_REVIEW", "COMPLETING", "UNRESOLVED_ISSUES"]:
        try:
            existing = api("GET", f"/apps/{app_id}/reviewSubmissions?filter[state]={state}")
            for item in existing.get("data", []):
                try:
                    api("PATCH", f"/reviewSubmissions/{item['id']}", json={
                        "data": {"type": "reviewSubmissions", "id": item["id"], "attributes": {"canceled": True}}
                    })
                    print(f"Canceled review submission {item['id']} (was {state})")
                    canceled_any = True
                except RuntimeError as e:
                    print(f"Could not cancel {item['id']}: {e}")
        except RuntimeError:
            pass

    if canceled_any:
        print("Waiting 15s for cancellations to propagate...")
        time.sleep(15)

    review = None
    for attempt in range(5):
        try:
            review = api("POST", "/reviewSubmissions", json={
                "data": {
                    "type": "reviewSubmissions",
                    "attributes": {"platform": "IOS"},
                    "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
                }
            })
            break
        except RuntimeError as e:
            print(f"Create reviewSubmission attempt {attempt+1}/5 failed: {e}")
            if attempt < 4:
                time.sleep(15)
    if not review:
        print("Could not create reviewSubmission after 5 attempts. Check ASC manually.")
        return
    review_id = review["data"]["id"]

    api("POST", "/reviewSubmissionItems", json={
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": review_id}},
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}},
            },
        }
    })

    api("PATCH", f"/reviewSubmissions/{review_id}", json={
        "data": {"type": "reviewSubmissions", "id": review_id, "attributes": {"submitted": True}}
    })
    print("Submitted for review")


def upload_screenshots(version_id):
    localizations = api("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200").get("data", [])
    if not localizations:
        loc_id = get_localization_id(version_id)
        localizations = api("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200").get("data", [])
        if not localizations and loc_id:
            localizations = [{"id": loc_id, "attributes": {"locale": "ja"}}]

    for loc in localizations:
        locale = loc.get("attributes", {}).get("locale", "unknown")
        print(f"Uploading screenshots for {locale}")
        sets = api("GET", f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200").get("data", [])
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        for display_type, filenames in SCREENSHOT_GROUPS:
            set_id = existing.get(display_type)
            if not set_id:
                created = api("POST", "/appScreenshotSets", json={
                    "data": {
                        "type": "appScreenshotSets",
                        "attributes": {"screenshotDisplayType": display_type},
                        "relationships": {
                            "appStoreVersionLocalization": {
                                "data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}
                            }
                        },
                    }
                })
                set_id = created["data"]["id"]
            for item in api("GET", f"/appScreenshotSets/{set_id}/appScreenshots?limit=200").get("data", []):
                api("DELETE", f"/appScreenshots/{item['id']}")
            for filename in filenames:
                upload_screenshot(set_id, filename)


def upload_screenshot(set_id, filename):
    path = os.path.join(SCREENSHOT_DIR, filename)
    with open(path, "rb") as file:
        data = file.read()
    checksum = hashlib.md5(data).hexdigest()
    created = api("POST", "/appScreenshots", json={
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": len(data)},
            "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
        }
    })
    screenshot_id = created["data"]["id"]
    for operation in created["data"]["attributes"]["uploadOperations"]:
        request_headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        response = requests.put(operation["url"], headers=request_headers, data=data[start:end], timeout=120)
        response.raise_for_status()
    for attempt in range(1, 7):
        try:
            api("PATCH", f"/appScreenshots/{screenshot_id}", json={
                "data": {
                    "type": "appScreenshots",
                    "id": screenshot_id,
                    "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
                }
            })
            print(f"  {filename}: uploaded")
            return
        except RuntimeError as error:
            print(f"  {filename}: confirm retry {attempt}/6 {error}")
            time.sleep(20)
    raise RuntimeError(f"Screenshot upload confirm failed: {filename}")


if __name__ == "__main__":
    main()
