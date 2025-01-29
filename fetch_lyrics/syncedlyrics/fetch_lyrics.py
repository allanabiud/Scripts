import sys

import syncedlyrics


def fetch_lyrics(search_term, save_path, synced_only=True):
    try:
        lrc = syncedlyrics.search(
            search_term, save_path=save_path, synced_only=synced_only
        )
        if lrc:
            print(f"Lyrics saved to: {save_path}")
        else:
            print("No lyrics found.")
    except Exception as e:
        print(f"Error fetching lyrics: {e}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(
            "Usage: python3 fetch_lyrics.py <search_term> --save-path=<path> [--synced-only]"
        )
        sys.exit(1)

    search_term = sys.argv[1]
    save_path = None
    synced_only = False

    for arg in sys.argv[2:]:
        if arg.startswith("--save-path="):
            save_path = arg.split("=", 1)[1]
        elif arg == "--synced-only":
            synced_only = True

    if not save_path:
        print("Error: Save path is required.")
        sys.exit(1)

    fetch_lyrics(search_term, save_path, synced_only)
