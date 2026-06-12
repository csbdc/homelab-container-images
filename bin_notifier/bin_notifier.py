import os
import requests
import re
import json
import sys

WASTE_COLLECTION_URL = os.getenv("WASTE_COLLECTION_URL")
DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")
POSTCODE = os.getenv("POSTCODE")
UPRN = int(os.getenv("UPRN"))

if not DISCORD_WEBHOOK_URL:
    raise SystemExit("DISCORD_WEBHOOK_URL not set")

def fetch_waste_data(postcode, uprn):
    try:
        response = requests.post(
            WASTE_COLLECTION_URL,
            data={"Postcode": postcode, "Uprn": uprn},
            timeout=10
        )
        response.raise_for_status()
    except requests.RequestException as e:
        raise SystemExit(f"Error fetching waste collection data: {e}")

    match = re.search(r"modelData\s*=\s*({.*?});", response.text, re.DOTALL)
    if not match:
        raise ValueError("modelData JSON not found in HTML response")

    try:
        return json.loads(match.group(1))
    except json.JSONDecodeError as e:
        raise ValueError(f"Error parsing modelData JSON: {e}")

def send_discord_message(message):
    try:
        response = requests.post(DISCORD_WEBHOOK_URL, json={"content": message}, timeout=10)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Failed to send Discord message: {e}", file=sys.stderr)

def main():
    try:
        data = fetch_waste_data(POSTCODE, UPRN)
        collections = data.get("NextCollectionDates", [])

        if len(collections) < 2:
            print("Collection data incomplete")
            return

        household = collections[0].get("RelativeToNowText", "").capitalize()
        recycling = collections[1].get("RelativeToNowText", "").capitalize()

        if household in ("Today", "Tomorrow"):
            send_discord_message(f"🗑 Household waste: {household}")
        if recycling in ("Today", "Tomorrow"):
            send_discord_message(f"♻️ Recycling: {recycling}")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()