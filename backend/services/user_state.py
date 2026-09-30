from __future__ import annotations
import sqlite3
from pathlib import Path
from typing import Any

DB_PATH = Path(__file__).resolve().parents[1] / "data" / "gisam_state.db"


def db():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH, timeout=10)
    conn.row_factory = sqlite3.Row
    return conn


def init_state_db():
    with db() as conn:
        conn.execute("""
        CREATE TABLE IF NOT EXISTS profiles (
            user_id TEXT PRIMARY KEY,
            display_name TEXT NOT NULL DEFAULT 'Usuario GISAM',
            avatar TEXT NOT NULL DEFAULT 'default',
            bio TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )""")
        conn.execute("""
        CREATE TABLE IF NOT EXISTS tree_state (
            user_id TEXT PRIMARY KEY,
            level INTEGER NOT NULL DEFAULT 1,
            xp INTEGER NOT NULL DEFAULT 0,
            xp_required INTEGER NOT NULL DEFAULT 1000,
            water INTEGER NOT NULL DEFAULT 50,
            health INTEGER NOT NULL DEFAULT 50,
            happiness INTEGER NOT NULL DEFAULT 50,
            updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )""")
        conn.execute("""
        CREATE TABLE IF NOT EXISTS missions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            xp_reward INTEGER NOT NULL DEFAULT 10,
            completed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )""")
        conn.execute("""
        CREATE TABLE IF NOT EXISTS friendships (
            user_id TEXT NOT NULL,
            friend_id TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'accepted',
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY(user_id, friend_id)
        )""")


def ensure_user(user_id: str):
    with db() as conn:
        conn.execute(
            "INSERT OR IGNORE INTO profiles(user_id) VALUES (?)", (user_id,)
        )
        conn.execute(
            "INSERT OR IGNORE INTO tree_state(user_id) VALUES (?)", (user_id,)
        )
        count = conn.execute(
            "SELECT COUNT(*) FROM missions WHERE user_id=?", (user_id,)
        ).fetchone()[0]
        if count == 0:
            conn.executemany(
                "INSERT INTO missions(user_id,title,xp_reward) VALUES (?,?,?)",
                [
                    (user_id, "Hablar con GISAM", 50),
                    (user_id, "Cuidar el árbol", 30),
                    (user_id, "Completar una actividad", 40),
                    (user_id, "Escuchar música", 20),
                ],
            )


def profile(user_id: str) -> dict[str, Any]:
    ensure_user(user_id)
    with db() as conn:
        p = dict(conn.execute(
            "SELECT * FROM profiles WHERE user_id=?", (user_id,)
        ).fetchone())
        t = dict(conn.execute(
            "SELECT * FROM tree_state WHERE user_id=?", (user_id,)
        ).fetchone())
    return {"profile": p, "tree": t}


def update_profile(user_id: str, display_name: str, bio: str = "", avatar: str = "default"):
    ensure_user(user_id)
    with db() as conn:
        conn.execute(
            """UPDATE profiles SET display_name=?, bio=?, avatar=? WHERE user_id=?""",
            (display_name[:80], bio[:500], avatar[:120], user_id),
        )
    return profile(user_id)


def add_xp(user_id: str, amount: int) -> dict[str, Any]:
    ensure_user(user_id)
    amount = max(0, min(amount, 1000))
    with db() as conn:
        t = conn.execute(
            "SELECT * FROM tree_state WHERE user_id=?", (user_id,)
        ).fetchone()
        xp = t["xp"] + amount
        level = t["level"]
        required = t["xp_required"]
        while xp >= required:
            xp -= required
            level += 1
            required = int(required * 1.25)
        conn.execute(
            """UPDATE tree_state SET level=?, xp=?, xp_required=?,
               updated_at=CURRENT_TIMESTAMP WHERE user_id=?""",
            (level, xp, required, user_id),
        )
    return profile(user_id)


def missions(user_id: str):
    ensure_user(user_id)
    with db() as conn:
        rows = conn.execute(
            """SELECT id,title,xp_reward,completed FROM missions
               WHERE user_id=? ORDER BY id""", (user_id,)
        ).fetchall()
    return [dict(r) for r in rows]


def complete_mission(user_id: str, mission_id: int):
    ensure_user(user_id)
    with db() as conn:
        row = conn.execute(
            """SELECT xp_reward, completed FROM missions
               WHERE id=? AND user_id=?""", (mission_id, user_id)
        ).fetchone()
        if row is None:
            return None
        if row["completed"]:
            return profile(user_id)
        conn.execute(
            "UPDATE missions SET completed=1 WHERE id=? AND user_id=?",
            (mission_id, user_id),
        )
    return add_xp(user_id, row["xp_reward"])


def add_friend(user_id: str, friend_id: str):
    if user_id == friend_id:
        return False
    ensure_user(user_id)
    ensure_user(friend_id)
    with db() as conn:
        conn.execute(
            "INSERT OR IGNORE INTO friendships(user_id,friend_id) VALUES (?,?)",
            (user_id, friend_id),
        )
        conn.execute(
            "INSERT OR IGNORE INTO friendships(user_id,friend_id) VALUES (?,?)",
            (friend_id, user_id),
        )
    return True


def friends(user_id: str):
    ensure_user(user_id)
    with db() as conn:
        rows = conn.execute(
            """SELECT p.user_id,p.display_name,p.avatar,p.bio
               FROM friendships f JOIN profiles p ON p.user_id=f.friend_id
               WHERE f.user_id=? ORDER BY p.display_name""",
            (user_id,),
        ).fetchall()
    return [dict(r) for r in rows]
