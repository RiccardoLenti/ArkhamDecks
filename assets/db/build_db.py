import sqlite3, json, os, glob

DB_PATH = "app.db"
SCHEMA_PATH = "schema.sql"
JSON_DIR = "json"

if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()



with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
    cur.executescript(f.read())

for path in glob.glob(os.path.join(JSON_DIR, "**/*.json"), recursive=True):
    with open(path, "r", encoding="utf-8") as f:
        cards = json.load(f)
        for card in cards:
            if card.get('faction_code') is None:
                continue

            cur.execute("""
                INSERT INTO cards (
                    code, name, subname, type_code, faction_code, faction2_code, faction3_code,
                    pack_code, traits, text, flavor, cost, health,
                    sanity, xp, slot, skill_intellect, skill_combat,
                    skill_agility, skill_willpower, skill_wild, deck_requirements,
                    is_unique, customization_text, deck_limit, quantity
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                card.get("code"),
                card.get("name"),
                card.get("subname"),
                card.get("type_code"),
                card.get("faction_code"),
                card.get("faction2_code"),
                card.get("faction3_code"),
                card.get("pack_code"),
                card.get("traits"),
                card.get("text"),
                card.get("flavor"),
                card.get("cost"),
                card.get("health"),
                card.get("sanity"),
                card.get("xp"),
                card.get("slot"),
                card.get("skill_intellect"),
                card.get("skill_combat"),
                card.get("skill_agility"),
                card.get("skill_willpower"),
                card.get("skill_wild"),
                card.get("deck_requirements"),
                1 if card.get("is_unique") else 0,
                card.get("customization_text"),
                card.get("deck_limit"),
                card.get("quantity")
            ))

conn.commit()
conn.close()
