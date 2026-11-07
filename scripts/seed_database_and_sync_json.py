# -*- coding: utf-8 -*-
"""
Main seeder script:
1. Seeds/updates content_items in backend/database/database.sqlite so all 7 games have >= 100 challenges.
2. Exports all cards from database.sqlite to mobile/assets/data/seed_games.json for full offline capabilities.
"""

import sqlite3
import json
import datetime
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from data_amthal import AMTHAL_ITEMS
from data_who_am_i import WHO_AM_I_ITEMS
from data_two_truths import TWO_TRUTHS_ITEMS
from data_speed_trivia import SPEED_TRIVIA_ITEMS
from data_autobus import AUTOBUS_ITEMS

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'backend', 'database', 'database.sqlite')
SEED_JSON_PATH = os.path.join(os.path.dirname(__file__), '..', 'mobile', 'assets', 'data', 'seed_games.json')

def run_seeder():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    print("🚀 Starting Database Seeding...")

    # --- 1. Game 1: أمثال شعبية (amthal-shaabiya) ---
    print("\n--- Seeding Game 1: أمثال شعبية ---")
    cur.execute("SELECT prompt FROM content_items WHERE game_id = 1")
    existing_amthal_prompts = set(row[0] for row in cur.fetchall())
    added_amthal = 0
    for item in AMTHAL_ITEMS:
        if item["prompt"] not in existing_amthal_prompts:
            cur.execute("""
                INSERT INTO content_items (
                    game_id, type, prompt, answer, distractors, explanation,
                    difficulty, status, is_active, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                1, "choice", item["prompt"], item["answer"],
                json.dumps(item["distractors"], ensure_ascii=False),
                item.get("explanation", ""),
                item.get("difficulty", "medium"),
                "published", 1, now, now
            ))
            existing_amthal_prompts.add(item["prompt"])
            added_amthal += 1
    print(f"Added {added_amthal} proverbs to Game 1.")

    # --- 2. Game 3: أنا مين ؟ (who-am-i) ---
    print("\n--- Seeding Game 3: أنا مين ؟ ---")
    # Clean out placeholder/dummy questions
    cur.execute("DELETE FROM content_items WHERE game_id = 3 AND (prompt LIKE '%أطول قارات%' OR prompt LIKE '%ما هي%')")
    cur.execute("SELECT prompt FROM content_items WHERE game_id = 3")
    existing_who_prompts = set(row[0] for row in cur.fetchall())
    added_who = 0
    for item in WHO_AM_I_ITEMS:
        if item["prompt"] not in existing_who_prompts:
            cur.execute("""
                INSERT INTO content_items (
                    game_id, type, prompt, answer, distractors, hints, explanation,
                    difficulty, status, is_active, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                3, "who_am_i", item["prompt"], item["answer"],
                json.dumps(item["distractors"], ensure_ascii=False),
                json.dumps(item["hints"], ensure_ascii=False),
                item.get("explanation", ""),
                item.get("difficulty", "medium"),
                "published", 1, now, now
            ))
            existing_who_prompts.add(item["prompt"])
            added_who += 1
    print(f"Added {added_who} personalities to Game 3.")

    # --- 3. Game 5: حقيقتان وكذبة (two-truths-and-lie) ---
    print("\n--- Seeding Game 5: حقيقتان وكذبة ---")
    cur.execute("DELETE FROM content_items WHERE game_id = 5 AND (prompt LIKE '%أطول قارات%' OR prompt LIKE '%ما هي%')")
    cur.execute("SELECT prompt FROM content_items WHERE game_id = 5")
    existing_two_prompts = set(row[0] for row in cur.fetchall())
    added_two = 0
    for item in TWO_TRUTHS_ITEMS:
        if item["prompt"] not in existing_two_prompts:
            cur.execute("""
                INSERT INTO content_items (
                    game_id, type, prompt, answer, distractors, explanation,
                    difficulty, status, is_active, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                5, "two_truths_one_lie", item["prompt"], item["answer"],
                json.dumps(item["distractors"], ensure_ascii=False),
                item.get("explanation", ""),
                item.get("difficulty", "medium"),
                "published", 1, now, now
            ))
            existing_two_prompts.add(item["prompt"])
            added_two += 1
    print(f"Added {added_two} cards to Game 5.")

    # --- 4. Game 6: سؤال على السريع (speed-trivia) ---
    print("\n--- Seeding Game 6: سؤال على السريع ---")
    cur.execute("DELETE FROM content_items WHERE game_id = 6 AND (prompt LIKE '%أطول قارات%' OR prompt LIKE '%سؤال تجريبي%')")
    cur.execute("SELECT prompt FROM content_items WHERE game_id = 6")
    existing_speed_prompts = set(row[0] for row in cur.fetchall())
    added_speed = 0
    for item in SPEED_TRIVIA_ITEMS:
        if item["prompt"] not in existing_speed_prompts:
            cur.execute("""
                INSERT INTO content_items (
                    game_id, type, prompt, answer, distractors, explanation,
                    difficulty, status, is_active, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                6, "choice", item["prompt"], item["answer"],
                json.dumps(item["distractors"], ensure_ascii=False),
                item.get("explanation", ""),
                item.get("difficulty", "easy"),
                "published", 1, now, now
            ))
            existing_speed_prompts.add(item["prompt"])
            added_speed += 1
    print(f"Added {added_speed} questions to Game 6.")

    # --- 5. Game 7: أتوبيس كومبليت (autobus-complete) ---
    print("\n--- Seeding Game 7: أتوبيس كومبليت ---")
    cur.execute("SELECT prompt FROM content_items WHERE game_id = 7")
    existing_autobus_prompts = set(row[0] for row in cur.fetchall())
    added_autobus = 0
    for item in AUTOBUS_ITEMS:
        if item["prompt"] not in existing_autobus_prompts:
            cur.execute("""
                INSERT INTO content_items (
                    game_id, type, prompt, answer, hints, acceptable_alternatives, explanation,
                    difficulty, status, is_active, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                7, "scattergories", item["prompt"], item["answer"],
                json.dumps(item["hints"], ensure_ascii=False),
                json.dumps(item["acceptable_alternatives"], ensure_ascii=False),
                item.get("explanation", ""),
                item.get("difficulty", "medium"),
                "published", 1, now, now
            ))
            existing_autobus_prompts.add(item["prompt"])
            added_autobus += 1
    print(f"Added {added_autobus} rounds to Game 7.")

    conn.commit()

    # --- Audit & Verify Counts in Database ---
    print("\n===============================")
    print("📊 FINAL DATABASE AUDIT REPORT:")
    print("===============================")
    cur.execute("""
        SELECT id, name, slug, template_type,
               (SELECT COUNT(*) FROM content_items WHERE game_id = games.id AND is_active = 1) AS count
        FROM games
        ORDER BY id
    """)
    games_stats = cur.fetchall()
    all_ok = True
    for gid, gname, gslug, gtype, count in games_stats:
        status_icon = "✅" if count >= 100 else "❌"
        if count < 100:
            all_ok = False
        print(f"Game {gid} [{gslug}]: {gname} -> {count} items {status_icon}")

    if all_ok:
        print("\n🎉 ALL GAMES HAVE AT LEAST 100 CHALLENGES!")
    else:
        print("\n⚠️ SOME GAMES STILL HAVE LESS THAN 100 ITEMS!")

    # --- Sync to mobile/assets/data/seed_games.json ---
    print("\n📱 Exporting synchronized cards to mobile/assets/data/seed_games.json...")
    cur.execute("""
        SELECT id, name, slug, subtitle, description, icon, category, template_type,
               min_players, max_players, default_rounds, default_duration_seconds, badge_text
        FROM games
        ORDER BY id
    """)
    games_rows = cur.fetchall()
    
    seed_data = []
    for g in games_rows:
        gid, name, slug, subtitle, description, icon, category, template_type, min_p, max_p, def_r, def_d, badge = g
        
        # Fetch all active cards for this game
        cur.execute("""
            SELECT id, prompt, answer, distractors, forbidden_words, hints, acceptable_alternatives, explanation
            FROM content_items
            WHERE game_id = ? AND is_active = 1
            ORDER BY id
        """, (gid,))
        card_rows = cur.fetchall()
        
        cards_list = []
        for c in card_rows:
            cid, prompt, answer, distractors, forbidden, hints, acceptable, explanation = c
            card_obj = {
                "id": cid,
                "prompt": prompt,
                "answer": answer,
            }
            if distractors:
                try:
                    card_obj["distractors"] = json.loads(distractors)
                except:
                    card_obj["distractors"] = []
            if forbidden:
                try:
                    card_obj["forbidden_words"] = json.loads(forbidden)
                except:
                    card_obj["forbidden_words"] = []
            if hints:
                try:
                    card_obj["hints"] = json.loads(hints)
                except:
                    card_obj["hints"] = []
            if acceptable:
                try:
                    card_obj["acceptable_alternatives"] = json.loads(acceptable)
                except:
                    card_obj["acceptable_alternatives"] = {}
            if explanation:
                card_obj["explanation"] = explanation
            
            cards_list.append(card_obj)
        
        game_obj = {
            "id": gid,
            "name": name,
            "slug": slug,
            "subtitle": subtitle or "",
            "description": description or "",
            "icon": icon or "",
            "category": category or "",
            "template_type": template_type or "",
            "min_players": min_p or 2,
            "max_players": max_p or 16,
            "default_rounds": def_r or 10,
            "default_duration_seconds": def_d or 60,
            "badge_text": badge or "",
            "cards": cards_list
        }
        seed_data.append(game_obj)
        print(f"Exported {len(cards_list)} cards for {slug} ({name}) to seed JSON.")

    with open(SEED_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(seed_data, f, ensure_ascii=False, indent=2)

    print(f"\n✅ Successfully updated: {SEED_JSON_PATH} with {len(seed_data)} games!")
    conn.close()

if __name__ == "__main__":
    run_seeder()
