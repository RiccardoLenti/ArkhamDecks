DROP TABLE IF EXISTS cards;
DROP TABLE IF EXISTS decks;
DROP TABLE IF EXISTS deck_cards;

CREATE TABLE cards (
    code TEXT PRIMARY KEY,
    name TEXT,
    subname TEXT,
    type_code TEXT,
    faction_code TEXT,
    faction2_code TEXT,
    faction3_code TEXT,
    pack_code TEXT,
    traits TEXT,
    text TEXT,
    flavor TEXT,
    cost INTEGER,
    health INTEGER,
    sanity INTEGER,
    xp INTEGER,
    slot TEXT,
    skill_intellect INTEGER,
    skill_combat INTEGER,
    skill_agility INTEGER,
    skill_willpower INTEGER,
    skill_wild INTEGER,
    deck_requirements TEXT,
    deck_options TEXT,
    restrictions TEXT,
    is_unique BOOLEAN,
    customization_text TEXT,
    deck_limit INTEGER,
    quantity INTEGER
);

CREATE TABLE decks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    investigator_code TEXT, 
    FOREIGN KEY(investigator_code) REFERENCES cards(code)
);

CREATE TABLE deck_cards (
    deck_id INTEGER NOT NULL,
    card_code TEXT NOT NULL,
    count INTEGER NOT NULL,
    FOREIGN KEY(deck_id) REFERENCES decks(id),
    FOREIGN KEY(card_code) REFERENCES cards(code),
    PRIMARY KEY(deck_id, card_code)
);

CREATE TABLE cycles (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE packs (
    code TEXT PRIMARY KEY,
    cycle_code TEXT NOT NULL,
    name TEXT NOT NULL
);