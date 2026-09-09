DROP TABLE IF EXISTS cards;
DROP TABLE IF EXISTS decks;
DROP TABLE IF EXISTS deck_cards;
DROP TABLE IF EXISTS printings;
DROP TABLE IF EXISTS cycles;
DROP TABLE IF EXISTS packs;

CREATE TABLE cards (
    code TEXT PRIMARY KEY,
    name TEXT,
    subname TEXT,
    type_code TEXT,
    subtype_code TEXT,
    faction_code TEXT,
    faction2_code TEXT,
    faction3_code TEXT,
    traits TEXT,
    tags TEXT,
    uses TEXT, -- like "Uses (3 charges)"
    text TEXT,
    flavor TEXT,
    cost INTEGER,
    health INTEGER,
    sanity INTEGER,
    xp INTEGER,
    slot TEXT,
    bonded_to TEXT,
    hidden BOOLEAN NOT NULL,
    skill_intellect INTEGER,
    skill_combat INTEGER,
    skill_agility INTEGER,
    skill_willpower INTEGER,
    skill_wild INTEGER,
    deck_requirements TEXT,
    deck_options TEXT,
    back_text TEXT,
    back_flavor TEXT,
    restrictions TEXT,
    is_unique BOOLEAN,
    customization_text TEXT,
    deck_limit INTEGER,
    exceptional BOOLEAN
);

--TODO: add references for pack_code?

CREATE TABLE printings (
    code TEXT PRIMARY KEY,
    canonical_code TEXT NOT NULL,
    pack_code TEXT,
    quantity INTEGER,
    position INTEGER,
    FOREIGN KEY(canonical_code) REFERENCES cards(code)
);

CREATE TABLE decks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    investigator_code TEXT,
    size INT NOT NULL, 
    signatures_count INT,
    selections TEXT,
    FOREIGN KEY(investigator_code) REFERENCES cards(code)
);

CREATE TABLE deck_cards (
    deck_id INTEGER NOT NULL,
    card_code TEXT NOT NULL,
    count INTEGER NOT NULL,
    side_deck BOOLEAN NOT NULL,
    FOREIGN KEY(deck_id) REFERENCES decks(id),
    FOREIGN KEY(card_code) REFERENCES cards(code),
    PRIMARY KEY(deck_id, card_code, side_deck)
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

CREATE TABLE taboos (
    code TEXT PRIMARY KEY,
    date_start TEXT NOT NULL
);

CREATE TABLE taboo_cards (
    taboo_list TEXT NOT NULL,
    code TEXT NOT NULL,
    xp INTEGER,
    text TEXT,
    replacement_text TEXT,
    deck_limit INTEGER,
    exceptional BOOLEAN,
    replacement_back_text TEXT,
    deck_options TEXT,
    deck_requirements TEXT,
    customization_text TEXT,
    FOREIGN KEY(taboo_list) REFERENCES taboos(code),
    FOREIGN KEY(code) REFERENCES cards(code),
    PRIMARY KEY(taboo_list, code)
);

CREATE VIEW card_details AS
SELECT
    cards.code,
    cards.name,
    cards.subname,
    cards.type_code,
    cards.subtype_code,
    cards.faction_code,
    cards.faction2_code,
    cards.faction3_code,
    cards.traits,
    cards.tags,
    cards.uses,
    cards.text,
    cards.flavor,
    cards.cost,
    cards.health,
    cards.sanity,
    cards.xp,
    cards.slot,
    cards.bonded_to,
    cards.hidden,
    cards.skill_intellect,
    cards.skill_combat,
    cards.skill_agility,
    cards.skill_willpower,
    cards.skill_wild,
    cards.back_text,
    cards.back_flavor,
    cards.restrictions,
    cards.is_unique,
    cards.customization_text,
    cards.deck_limit AS printed_deck_limit,
    IFNULL(cards.exceptional, 0) AS printed_exceptional,
    cards.deck_options AS printed_deck_options,
    cards.deck_requirements AS printed_deck_requirements,
    printing.pack_code,
    printing.quantity,
    printing.position
FROM cards
JOIN printings AS printing ON cards.code = printing.canonical_code;

CREATE VIEW card_simplified AS
SELECT
    cards.code,
    cards.name,
    cards.subname,
    cards.type_code,
    cards.subtype_code,
    cards.faction_code,
    cards.faction2_code,
    cards.faction3_code,
    cards.cost,
    cards.xp,
    cards.slot,
    cards.hidden,
    cards.traits,
    cards.restrictions,
    cards.tags,
    cards.uses,
    cards.deck_limit AS printed_deck_limit,
    IFNULL(cards.exceptional, 0) AS printed_exceptional,
    cards.deck_options AS printed_deck_options,
    cards.deck_requirements AS printed_deck_requirements,
    printing.pack_code,
    printing.position,
    printing.quantity
FROM cards
JOIN printings AS printing ON cards.code = printing.canonical_code
GROUP BY cards.code;

CREATE INDEX idx_cards_type ON cards(type_code);
CREATE INDEX idx_cards_subtype ON cards(subtype_code);
CREATE INDEX idx_printings_canonical_code ON printings(canonical_code);