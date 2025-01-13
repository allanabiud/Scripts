import os

from simyan.comicvine import Comicvine
from simyan.sqlite_cache import SQLiteCache

# Replace with your Comicvine API key
API_KEY = os.getenv("COMICVINE_API_KEY")

# Initialize the Comicvine session with SQLite caching
session = Comicvine(api_key=API_KEY, cache=SQLiteCache())
