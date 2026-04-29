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

for path in glob.glob(os.path.join(JSON_DIR, "cards", "**/*.json"), recursive=True):
    with open(path, "r", encoding="utf-8") as f:
        cards = json.load(f)
        for card in cards:
            dup = card.get('duplicate_of')
            if dup is not None:
                cur.execute("""
                    INSERT INTO printings (
                        code, canonical_code, pack_code, quantity, position    
                    ) VALUES (?, ?, ?, ?, ?)
                """, (
                    card.get('code'),
                    card.get('duplicate_of'),
                    card.get('pack_code'),
                    card.get('quantity'),
                    card.get('position'))
                )

                continue


            # if we're here then it's not a duplicate
            cur.execute("""
                INSERT INTO cards (
                    code, name, subname, type_code, faction_code, faction2_code, 
                    faction3_code, traits, text, flavor, cost, health,
                    sanity, xp, slot, bonded_to, hidden, skill_intellect, skill_combat,
                    skill_agility, skill_willpower, skill_wild, deck_requirements, deck_options,
                    back_text, back_flavor, restrictions, is_unique, customization_text, deck_limit
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                          ?, ?, ?, ?, ?, ?)
            """, (
                card.get("code"),
                card.get("name"),
                card.get("subname"),
                card.get("type_code"),
                card.get("faction_code"),
                card.get("faction2_code"),
                card.get("faction3_code"),
                card.get("traits"),
                card.get("text"),
                card.get("flavor"),
                card.get("cost"),
                card.get("health"),
                card.get("sanity"),
                card.get("xp"),
                card.get("slot"),
                card.get("bonded_to"),
                1 if card.get("hidden") else 0,
                card.get("skill_intellect"),
                card.get("skill_combat"),
                card.get("skill_agility"),
                card.get("skill_willpower"),
                card.get("skill_wild"),
                card.get("deck_requirements"),
                json.dumps(card.get("deck_options")) if card.get("deck_options") is not None else None,
                card.get("back_text"),
                card.get("back_flavor"),
                card.get("restrictions"),
                1 if card.get("is_unique") else 0,
                card.get("customization_text"),
                card.get("deck_limit"),
            ))

            cur.execute("""
                INSERT INTO printings (
                    code, canonical_code, pack_code, quantity, position
                ) VALUES (?, ?, ?, ?, ?)
                """, (
                card.get("code"),
                card.get("code"),
                card.get("pack_code"),
                card.get("quantity"),
                card.get("position"))
            )

cycles_path = os.path.join(JSON_DIR, "cycles.json")
if os.path.exists(cycles_path):
    with open(cycles_path, "r", encoding="utf-8") as f:
        cycles = json.load(f)
        for cycle in cycles:
            cur.execute("""
                INSERT INTO cycles (code, name)
                VALUES (?, ?)
            """, (cycle.get("code"), cycle.get("name")))
else:
    print("WARNING: cycles.json not found!")

packs_path = os.path.join(JSON_DIR, "packs.json")
if os.path.exists(packs_path):
    with open(packs_path, "r", encoding="utf-8") as f:
        packs = json.load(f)
        for pack in packs: 
            cur.execute("""
                INSERT INTO packs (code, cycle_code, name) 
                VALUES (?, ?, ?)
            """, (pack.get("code"), pack.get("cycle_code"), pack.get("name")))

taboos_path = os.path.join(JSON_DIR, "taboos.json")
if os.path.exists(taboos_path):
    with open(taboos_path, 'r', encoding="utf-8") as f:
        taboos = json.load(f)
        for taboo_list in taboos:
            taboo_code = taboo_list.get("code")
            cur.execute("INSERT INTO taboos (code, date_start) VALUES (?, ?)",
                        (taboo_code, taboo_list.get("date_start")))
            for card in taboo_list.get("cards"):
                try:
                    cur.execute("""
                            INSERT INTO taboo_cards(taboo_list, code, xp, text, 
                                                    replacement_text)
                            VALUES (?, ?, ?, ?, ?)""",
                            (taboo_code, card.get("code"), card.get("xp"), 
                             card.get("text"), card.get("replacement_text")))
                except:
                    print(f"{taboo_code=} | {card.get('code')=}")

conn.commit()
conn.close()
