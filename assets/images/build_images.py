import argparse, os, shutil, sqlite3, time, urllib.request
from PIL import Image

DB_PATH    = "../db/app.db"
CACHE_DIR  = ".cache"
ART_DIR    = "art"
THUMB_DIR  = "thumb"
SOURCE     = "https://assets.arkham.build/{bucket}/{code}.webp"
USER_AGENT = "ArkhamDecks/0.1 (card art build script)"

# /optimized carries the FFG watermark on most cards, but not on investigator scans
OPTIMIZED  = "optimized"
THUMBNAILS = "thumbnails"

ART_WIDTH  = 480
THUMB_SIZE = 160
THUMB_ZOOM = 0.62
THUMB_BIAS = 0.10

# (left, top, right, bottom) as fractions of the source
INVESTIGATOR_BOX = (0.030, 0.170, 0.525, 0.975)


def cards():
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute("SELECT code, type_code FROM cards ORDER BY code").fetchall()
    conn.close()
    return rows


def bucket(type_code):
    return OPTIMIZED if type_code == "investigator" else THUMBNAILS


def cached(code, type_code):
    return os.path.join(CACHE_DIR, bucket(type_code), f"{code}.webp")


def fetch(rows):
    for name in (OPTIMIZED, THUMBNAILS):
        os.makedirs(os.path.join(CACHE_DIR, name), exist_ok=True)
    for i, (code, type_code) in enumerate(rows, 1):
        dest = cached(code, type_code)
        if os.path.exists(dest):
            continue
        request = urllib.request.Request(
            SOURCE.format(bucket=bucket(type_code), code=code),
            headers={"User-Agent": USER_AGENT},
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read()
        with open(dest, "wb") as f:
            f.write(data)
        print(f"[{i}/{len(rows)}] {code}", flush=True)
        time.sleep(0.05)


def art_of(code):
    im = Image.open(cached(code, "investigator")).convert("RGB")
    box = INVESTIGATOR_BOX
    w, h = im.size
    return im.crop((int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h)))


def to_aspect(im, aspect):
    w, h = im.size
    if w / h > aspect:
        nw = int(h * aspect)
        return im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    return im.crop((0, 0, w, int(w / aspect)))


def encode(rows):
    os.makedirs(ART_DIR, exist_ok=True)
    os.makedirs(THUMB_DIR, exist_ok=True)
    for code, type_code in rows:
        if type_code != "investigator":
            shutil.copyfile(
                cached(code, type_code), os.path.join(ART_DIR, f"{code}.webp")
            )
            continue

        art = art_of(code)

        side = int(min(art.size) * THUMB_ZOOM)
        left = (art.width - side) // 2
        top = int((art.height - side) * THUMB_BIAS)
        art.crop((left, top, left + side, top + side)) \
           .resize((THUMB_SIZE, THUMB_SIZE), Image.LANCZOS) \
           .save(os.path.join(THUMB_DIR, f"{code}.webp"), "WEBP", quality=80, method=6)

        art = to_aspect(art, 1.0)
        if art.width > ART_WIDTH:
            art = art.resize((ART_WIDTH, int(art.height * ART_WIDTH / art.width)), Image.LANCZOS)

        art.save(os.path.join(ART_DIR, f"{code}.webp"), "WEBP", quality=72, method=6)


parser = argparse.ArgumentParser()
parser.add_argument("--fetch", action="store_true")
parser.add_argument("--encode", action="store_true")
args = parser.parse_args()

rows = cards()
if args.fetch:
    fetch(rows)
if args.encode:
    encode(rows)
