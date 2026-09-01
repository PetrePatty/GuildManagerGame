#!/usr/bin/env python3
"""Database Loader & Exporter Utility.

Reads SQLite database contents (such as Databases/adventurers.db) and exports or loads
the data into Python dictionaries and JSON format for easy consumption by Python scripts.
"""

__author__ = "GuildManager Team"
__version__ = "1.0.0"

# 1. Standard library imports
import json
import sqlite3
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

# Module-Level Constants
DEFAULT_DB_PATH = Path(__file__).parent / "Databases" / "adventurers.db"
DEFAULT_JSON_PATH = Path(__file__).parent / "Databases" / "adventurers.json"


def load_db_to_dict(db_path: Union[str, Path] = DEFAULT_DB_PATH) -> Dict[str, List[Dict[str, Any]]]:
    """Reads all tables from an SQLite database and converts them into Python dictionaries.

    Args:
        db_path: Path to the SQLite database file.

    Returns:
        Dictionary mapping table names to lists of row dictionaries.
    """
    db_file = Path(db_path)
    if not db_file.exists():
        raise FileNotFoundError(f"Database file not found at: {db_file}")

    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # Query all user table names
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
    tables = [row[0] for row in cursor.fetchall()]

    db_data: Dict[str, List[Dict[str, Any]]] = {}
    for table_name in tables:
        cursor.execute(f"SELECT * FROM `{table_name}`")
        rows = cursor.fetchall()
        db_data[table_name] = [dict(row) for row in rows]

    conn.close()
    return db_data


def get_table_data(
    table_name: str, db_path: Union[str, Path] = DEFAULT_DB_PATH
) -> List[Dict[str, Any]]:
    """Retrieves all rows for a single table from the database as Python dictionaries.

    Args:
        table_name: Name of the table to fetch.
        db_path: Path to the SQLite database file.

    Returns:
        List of dictionaries representing table rows.
    """
    db_data = load_db_to_dict(db_path)
    if table_name not in db_data:
        raise KeyError(f"Table '{table_name}' not found in database. Available tables: {list(db_data.keys())}")
    return db_data[table_name]


def get_indexed_table(
    table_name: str, key_column: str, db_path: Union[str, Path] = DEFAULT_DB_PATH
) -> Dict[Any, Dict[str, Any]]:
    """Retrieves rows for a table indexed by a specific column (e.g., primary key).

    Args:
        table_name: Name of the table.
        key_column: Name of the column to use as dictionary key.
        db_path: Path to the SQLite database file.

    Returns:
        Dictionary mapping key values to row dictionaries.
    """
    rows = get_table_data(table_name, db_path)
    indexed_data: Dict[Any, Dict[str, Any]] = {}
    for row in rows:
        if key_column not in row:
            raise KeyError(f"Column '{key_column}' not found in table '{table_name}'.")
        indexed_data[row[key_column]] = row
    return indexed_data


def export_db_to_json(
    db_path: Union[str, Path] = DEFAULT_DB_PATH,
    json_path: Union[str, Path] = DEFAULT_JSON_PATH,
    indent: int = 2
) -> Path:
    """Reads the SQLite database and saves all table contents to a structured JSON file.

    Args:
        db_path: Path to input SQLite database.
        json_path: Target path for output JSON file.
        indent: JSON formatting indentation level.

    Returns:
        Path to the saved JSON file.
    """
    db_data = load_db_to_dict(db_path)
    out_file = Path(json_path)
    out_file.parent.mkdir(parents=True, exist_ok=True)

    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(db_data, f, indent=indent, ensure_ascii=False)

    return out_file


def main() -> None:
    """Main execution block: loads database, exports to JSON, and prints summary."""
    print("--------------------------------------------------")
    print(f"Loading database from: {DEFAULT_DB_PATH}")

    try:
        data = load_db_to_dict(DEFAULT_DB_PATH)
        print(f"Successfully loaded {len(data)} tables.")

        print("\nTable Row Counts:")
        for table, rows in data.items():
            print(f"  - {table}: {len(rows)} rows")

        # Export to JSON format
        output_json = export_db_to_json(DEFAULT_DB_PATH, DEFAULT_JSON_PATH)
        print(f"\nExported database contents to JSON format: {output_json}")

        # Quick demonstration of accessing data
        if "races" in data:
            print("\nSample Race Data (loaded into Python dict):")
            for race in data["races"][:3]:
                print(f"  [{race['race_id']}] {race['name']} - {race['description']}")

        print("--------------------------------------------------")

    except Exception as e:
        print(f"Error loading database: {e}")


if __name__ == "__main__":
    main()
