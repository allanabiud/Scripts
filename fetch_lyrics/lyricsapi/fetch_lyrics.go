package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	// "time"

	"github.com/joho/godotenv"
	"github.com/raitonoberu/lyricsapi/spotify"
)

// SongInfo represents the JSON structure from rmpc
type SongInfo struct {
	File     string `json:"file"`
	Metadata struct {
		Artist      string `json:"artist"`
		Title       string `json:"title"`
		AlbumArtist string `json:"albumartist"`
	} `json:"metadata"`
}

func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	// Fetch the cookie from the environment variable
	cookie := os.Getenv("SPOTIFY_COOKIE")
	if cookie == "" {
		log.Fatalf("Environment variable SPOTIFY_COOKIE is not set")
	}

	// Configure the cookie for lyricsapi
	api := spotify.NewClient("")

	// Fetch song information using rmpc
	songJSON, err := ioutil.ReadAll(os.Stdin) // Assumes rmpc song is piped into the script
	if err != nil {
		log.Fatalf("Failed to read song info: %v", err)
	}

	var song SongInfo
	if err := json.Unmarshal(songJSON, &song); err != nil {
		log.Fatalf("Failed to parse song info: %v", err)
	}

	// Extract artist and title
	// artist := song.Metadata.Artist
	album_artist := song.Metadata.AlbumArtist
	title := song.Metadata.Title
	filePath := song.File

	// if artist == "" || title == "" || filePath == "" {
	if album_artist == "" || title == "" || filePath == "" {
		log.Println("Missing artist, title, or file path, skipping lyrics fetch.")
		return
	}

	// Generate path for the LRC file
	baseName := strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))
	lrcPath := filepath.Join(os.Getenv("HOME"), "Music", "Music", baseName+".lrc")

	// Check if the LRC file already exists
	if _, err := os.Stat(lrcPath); err == nil {
		log.Printf("LRC file already exists: %s", lrcPath)
		return
	}

	// Fetch lyrics using lyricsapi
	log.Printf("Fetching lyrics for %s %s...", album_artist, title)
	lyrics, _ := api.GetByName(fmt.Sprintf("%s %s", album_artist, title))
	if lyrics == nil {
		log.Printf("Lyrics not found for %s %s", album_artist, title)
		return
	} else {
		log.Printf("Found lyrics for %s %s", album_artist, title)
	}

	// Write LRC file
	var lrcContent strings.Builder
	for _, line := range lyrics {
		timeStamp := fmt.Sprintf("[%02d:%02d.%02d]", line.Time/60000, (line.Time%60000)/1000, (line.Time%1000)/10)
		lrcContent.WriteString(fmt.Sprintf("%s %s\n", timeStamp, line.Words))
	}

	if err := ioutil.WriteFile(lrcPath, []byte(lrcContent.String()), 0644); err != nil {
		log.Fatalf("Failed to write LRC file: %v", err)
	}

	log.Printf("Lyrics saved to: %s", lrcPath)
}
