import hashlib
import os
import time

import requests

from asc_api import api, find_app_id, get_localization_id, get_or_create_version

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
LOCALIZATION = {
    "description": (
        "歌舞伎町風の夜の盤面で、4人のキャラクターが競うリバーシゲームです。"
        "リップ、ボトル、ネイル、チョコの駒を置き、相手の駒をはさんで返します。"
    ),
    "keywords": "リバーシ,オセロ,4人,対戦,歌舞伎町,ボードゲーム,ネオン,パーティー",
    "promotionalText": "4人のキャラクターが夜の盤面で競う、歌舞伎町風リバーシ。",
    "marketingUrl": "https://snarfnet.github.io/",
    "supportUrl": "https://snarfnet.github.io/",
}
WHATS_NEW = "現在のアプリ画面に合わせてスクリーンショットを更新しました。"


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
            if not BUILD_NUMBER and version and state == "VALID":
                return item["id"]
            if state == "VALID" and latest_valid_id is None:
                latest_valid_id = item["id"]
        print(f"  attempt {attempt + 1}/90, waiting 30s")
        time.sleep(30)
    if latest_valid_id:
        print("Target build not found, using latest valid build")
        return latest_valid_id
    raise RuntimeError("No valid processed build found")


def ensure_version_settings(app_id, version_id, build_id):
    patch_ignoring_conflict(f"/appStoreVersions/{version_id}", {
        "copyright": "2026 Tokyo Nasu",
        "usesIdfa": True,
        "releaseType": "AFTER_APPROVAL",
    }, "Version settings")
    patch_ignoring_conflict(f"/builds/{build_id}", {"usesNonExemptEncryption": False}, "Encryption")
    patch_ignoring_conflict(f"/apps/{app_id}", {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}, "Content rights")

    api("PATCH", f"/appStoreVersions/{version_id}/relationships/build", json={
        "data": {"type": "builds", "id": build_id}
    })
    print("Build linked to version")


def patch_ignoring_conflict(path, attrs, label):
    resource_type = path.split("/")[1]
    resource_id = path.split("/")[2]
    try:
        api("PATCH", path, json={
            "data": {"type": resource_type, "id": resource_id, "attributes": attrs}
        })
        print(f"{label}: updated")
    except RuntimeError as error:
        if "409" in str(error):
            print(f"{label}: already set")
            return
        raise


def ensure_review_detail(version_id):
    attrs = {
        **REVIEW_CONTACT,
        "demoAccountRequired": False,
        "demoAccountName": "",
        "demoAccountPassword": "",
        "notes": (
            "This build addresses Guideline 2.3.3. "
            "All existing screenshot sets were cleared to remove stale images that may appear under View All Sizes. "
            "The 6.5-inch iPhone and 13-inch iPad screenshots were reuploaded with current in-app screens "
            "showing character selection, active 10 x 10 board play, valid move hints, dialogue, and the result screen."
        ),
    }
    review_details = api("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
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
    print("Review detail updated")


def update_localization(version_id):
    loc_id = get_localization_id(version_id)
    if not loc_id:
        return
    api("PATCH", f"/appStoreVersionLocalizations/{loc_id}", json={
        "data": {
            "type": "appStoreVersionLocalizations",
            "id": loc_id,
            "attributes": LOCALIZATION,
        }
    })
    print("Localization metadata updated")
    try:
        api("PATCH", f"/appStoreVersionLocalizations/{loc_id}", json={
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": loc_id,
                "attributes": {"whatsNew": WHATS_NEW},
            }
        })
        print("What's New updated")
    except RuntimeError as error:
        if "whatsNew" in str(error) and "409" in str(error):
            print("What's New is locked for this version, skipping")
            return
        raise


def upload_screenshots(version_id):
    localizations = api("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200").get("data", [])
    if not localizations:
        loc_id = get_localization_id(version_id)
        localizations = [{"id": loc_id, "attributes": {"locale": "ja"}}] if loc_id else []

    for loc in localizations:
        locale = loc.get("attributes", {}).get("locale", "unknown")
        print(f"Uploading screenshots for {locale}")
        sets = api("GET", f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets?limit=200").get("data", [])
        existing = {item["attributes"]["screenshotDisplayType"]: item["id"] for item in sets}
        clear_existing_screenshots(sets)
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
            for filename in filenames:
                upload_screenshot(set_id, filename)


def clear_existing_screenshots(sets):
    deleted = 0
    for screenshot_set in sets:
        set_id = screenshot_set["id"]
        display_type = screenshot_set.get("attributes", {}).get("screenshotDisplayType", "unknown")
        screenshots = api("GET", f"/appScreenshotSets/{set_id}/appScreenshots?limit=200").get("data", [])
        for item in screenshots:
            api("DELETE", f"/appScreenshots/{item['id']}")
            deleted += 1
        if screenshots:
            print(f"  cleared {len(screenshots)} old screenshots from {display_type}")
    if deleted:
        print(f"  cleared {deleted} old screenshots total")


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


def cancel_existing_review_submissions(app_id):
    canceled = False
    submissions = api("GET", f"/apps/{app_id}/reviewSubmissions?limit=20").get("data", [])
    for item in submissions:
        state = item.get("attributes", {}).get("state")
        if state not in {"WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_REVIEW", "UNRESOLVED_ISSUES"}:
            continue
        try:
            api("PATCH", f"/reviewSubmissions/{item['id']}", json={
                "data": {"type": "reviewSubmissions", "id": item["id"], "attributes": {"canceled": True}}
            })
            print(f"Canceled review submission {item['id']} (was {state})")
            canceled = True
        except RuntimeError as error:
            print(f"Could not cancel {item['id']}: {error}")
    if canceled:
        time.sleep(30)


def submit_for_review(app_id, version_id):
    review = api("POST", "/reviewSubmissions", json={
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    })
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


def main():
    app_id = find_app_id()
    version_id = get_or_create_version(app_id, APP_VERSION)
    build_id = wait_for_build(app_id)
    ensure_version_settings(app_id, version_id, build_id)
    ensure_review_detail(version_id)
    update_localization(version_id)
    upload_screenshots(version_id)
    print("Waiting 5 minutes for screenshot processing...")
    time.sleep(300)
    cancel_existing_review_submissions(app_id)
    submit_for_review(app_id, version_id)


if __name__ == "__main__":
    main()
