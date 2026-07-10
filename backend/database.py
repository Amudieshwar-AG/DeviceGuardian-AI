from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

import os

db_url = os.getenv("DATABASE_URL")
if db_url:
    db_url = db_url.strip().strip("'\"")

if not db_url:
    SQLALCHEMY_DATABASE_URL = "sqlite:///./device_guardian.db"
else:
    SQLALCHEMY_DATABASE_URL = db_url

if SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgres://", "postgresql://", 1)

connect_args = {}
if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
    connect_args["check_same_thread"] = False

def mask_url(url_str):
    if not url_str:
        return ""
    try:
        from urllib.parse import urlparse
        parsed = urlparse(url_str)
        if parsed.password:
            netloc = parsed.hostname or ""
            if parsed.port:
                netloc = f"{netloc}:{parsed.port}"
            if parsed.username:
                netloc = f"{parsed.username}:********@{netloc}"
            return parsed._replace(netloc=netloc).geturl()
        return url_str
    except Exception:
        if "@" in url_str:
            parts = url_str.split("@")
            return f"...@{parts[-1]}"
        return f"[Unparseable URL, length={len(url_str)}]"

try:
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args=connect_args
    )
except Exception as e:
    print(f"DATABASE INITIALIZATION ERROR: {e}")
    print(f"Failed URL was: {mask_url(SQLALCHEMY_DATABASE_URL)}")
    print("Falling back to SQLite database: sqlite:///./device_guardian.db")
    SQLALCHEMY_DATABASE_URL = "sqlite:///./device_guardian.db"
    connect_args = {"check_same_thread": False}
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args=connect_args
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
