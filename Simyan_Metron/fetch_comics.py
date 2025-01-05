import csv
import json

# import module to read environment variables
import os
import re
from datetime import date, datetime

import requests
from bs4 import BeautifulSoup
from pydantic.networks import HttpUrl
from simyan.comicvine import Comicvine
from simyan.sqlite_cache import SQLiteCache

# Replace with your Comicvine API key
API_KEY = os.getenv("COMICVINE_API_KEY")

# Initialize the Comicvine session with SQLite caching
session = Comicvine(api_key=API_KEY, cache=SQLiteCache())

# Paths for output files
csv_file = "./output/issue_details.csv"
json_file = "./output/issue_details.json"
html_file = "./output/issue_details.html"


# Custom function to handle non-serializable objects
def custom_serializer(obj):
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()  # Convert datetime and date to ISO 8601 string
    if isinstance(obj, HttpUrl):
        return str(obj)  # Convert HttpUrl to a string
    raise TypeError(f"Type {type(obj)} not serializable")


# Function to remove HTML tags
def strip_html_tags(text):
    clean = re.sub(r"<[^>]+>", "", text)
    return clean


# Helper function to process cover date to "DD-MM-YYYY" format with day as 1
def process_cover_date(cover_date):
    if isinstance(cover_date, date):  # If it's already a datetime.date object
        return cover_date.replace(day=1).strftime("%d-%m-%Y")
    try:
        # Parse the date using "01 Month Year" format (sets the day to 1)
        return datetime.strptime(f"01 {cover_date}", "%d %B %Y").strftime("%d-%m-%Y")
    except ValueError:
        return "N/A"


# Helper function to process in-store date to "DD-MM-YYYY" format
def process_in_store_date(store_date):
    if isinstance(store_date, date):  # If it's already a datetime.date object
        return store_date.strftime("%d-%m-%Y")
    try:
        return datetime.strptime(store_date, "%Y-%m-%d").strftime("%d-%m-%Y")
    except ValueError:
        return "N/A"


# LCG scraping function (from previous implementation)
def scrape_lcg_comic_page(url):
    # Add User-Agent to mimic a real browser request
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }

    response = requests.get(url, headers=headers)

    # Check the status code of the response
    if response.status_code != 200:
        print(f"Failed to retrieve the LCG page. Status Code: {response.status_code}")
        return {}

    soup = BeautifulSoup(response.text, "html.parser")

    data = {}

    # Extracting the required fields from the LCG page
    try:
        # Extract price and page count details
        price_and_details_div = soup.find("div", class_="col copy-small font-italic")
        if price_and_details_div:
            price_details_text = price_and_details_div.text.strip()
            # Regex pattern to extract the details like pages and price
            pattern = r"(\w+ \w+)\s+·\s+(\d+)\s+pages\s+·\s+\$(\d+\.\d{2})"
            match = re.search(pattern, price_details_text)

            if match:
                data["Cover Price"] = match.group(3)  # $16.99
                data["Page Count"] = match.group(2)  # 176
            else:
                print("Price and details not found.")
                data["Cover Price"] = "N/A"
                data["Page Count"] = "N/A"
        else:
            print("Price and details section not found.")
            data["Cover Price"] = "N/A"
            data["Page Count"] = "N/A"

        # Extract ISBN and Distributor SKU
        details_addtl_div = soup.find_all("div", class_="details-addtl-block")
        if details_addtl_div:
            for block in details_addtl_div:
                name_div = block.find("div", class_="name")
                if name_div:
                    name = name_div.text.strip()

                    value_div = block.find("div", class_="value")
                    if value_div:
                        value = value_div.text.strip()

                        if name == "ISBN":
                            data["ISBN"] = value
                        elif name == "Distributor SKU":
                            data["Distributor SKU"] = value
                        elif name == "UPC":
                            data["UPC"] = value

            if "ISBN" not in data:
                data["ISBN"] = "N/A"
            if "Distributor SKU" not in data:
                data["Distributor SKU"] = "N/A"
            if "UPC" not in data:
                data["UPC"] = "N/A"
        else:
            data["ISBN"] = "N/A"
            data["Distributor SKU"] = "N/A"
            data["UPC"] = "N/A"

        # Extracting Story Titles
        unwanted_titles = [
            "Overview",
            "[Title, Illustration and Credits]",
            "[Cover Reprint]",
            "[Variant Cover Gallery]",
        ]
        story_titles = []
        story_section = soup.find_all(
            "h4", class_="story-title color-primary m-0 p-0"
        )  # Updated class names
        if story_section:
            for story in story_section:
                title = story.get_text(strip=True)
                if title not in unwanted_titles:
                    story_titles.append(title)

        if story_titles:
            data["Story Titles"] = story_titles
        else:
            data["Story Titles"] = ["N/A"]

        # Scraping Creators (Top Level Credits and Featured Creators)
        creators = []

        # Featured Creators Section
        featured_creators = []
        creators_section = soup.find("section", id="creators-")
        if creators_section:
            creator_divs = creators_section.find_all("div", class_="col-auto")
            for creator_div in creator_divs:
                avatar_tag = creator_div.find("div", class_="avatar")
                name_tag = creator_div.find("div", class_="name")
                role_tag = creator_div.find("div", class_="role")
                if avatar_tag and name_tag and role_tag:
                    creator_name = name_tag.get_text(strip=True)
                    creator_role = role_tag.get_text(strip=True)
                    featured_creators.append(
                        {"name": creator_name, "role": creator_role}
                    )

        # Top-Level Credits (Cover Artists)
        top_level_credits_section = soup.find("section", id="top-level-credits")
        if top_level_credits_section:
            cover_artists_section = top_level_credits_section.find(
                "div", id="cover-artists"
            )
            if cover_artists_section:
                cover_artists = cover_artists_section.find_all("div", class_="col-auto")
                for artist in cover_artists:
                    name_tag = artist.find("div", class_="name")
                    role_tag = artist.find("div", class_="role")
                    if name_tag and role_tag:
                        creator_name = name_tag.get_text(strip=True)
                        creator_role = role_tag.get_text(strip=True)
                        creators.append({"name": creator_name, "role": creator_role})

            # Production Credits
            production_section = top_level_credits_section.find(
                "div", id="credits-production"
            )
            if production_section:
                production_artists = production_section.find_all(
                    "div", class_="col-auto"
                )
                for artist in production_artists:
                    name_tag = artist.find("div", class_="name")
                    role_tag = artist.find("div", class_="role")
                    if name_tag and role_tag:
                        creator_name = name_tag.get_text(strip=True)
                        creator_role = role_tag.get_text(strip=True)
                        creators.append({"name": creator_name, "role": creator_role})

        # Combine Featured Creators and Top Level Credits under 'Creators'
        combined_creators = featured_creators + creators
        if combined_creators:
            data["Creators"] = combined_creators
        else:
            data["Creators"] = "N/A"

    except Exception as e:
        print(f"Error extracting data: {e}")
        data["Cover Price"] = "N/A"
        data["Page Count"] = "N/A"
        data["ISBN"] = "N/A"
        data["Distributor SKU"] = "N/A"
        data["Story Titles"] = ["N/A"]
        data["Creators"] = ["N/A"]

    return data


# Prompt the user for input
issue_id = input("Enter the Comicvine Issue ID: ").strip()
lcg_url = input("Enter the LCG Comic page URL: ").strip()

# Fetch issue details and generate output
try:
    print(f"Fetching issue with ID {issue_id} from Comicvine...")
    issue_details = session.get_issue(issue_id=int(issue_id))

    # Process the cover_date and in_store_date
    cover_date = issue_details.cover_date or "N/A"
    formatted_cover_date = process_cover_date(cover_date)

    in_store_date = issue_details.store_date or "N/A"
    formatted_in_store_date = process_in_store_date(in_store_date)

    # Extract required fields
    cv_creators = []
    if issue_details.creators:
        for creator in issue_details.creators:
            roles = (
                creator.roles if isinstance(creator.roles, list) else [creator.roles]
            )
            roles_str = ", ".join(roles)
            cv_creators.append(f"{creator.name} ({roles_str})")

    # Remove HTML tags from the description
    description = issue_details.description or "N/A"
    description_cleaned = strip_html_tags(description)

    # Get ISBN and Distributor SKU from the LCG page
    lcg_data = scrape_lcg_comic_page(lcg_url)

    data = {
        "Series": issue_details.volume.name if issue_details.volume else "N/A",
        "Number": issue_details.number or "N/A",
        "Collection Title": issue_details.name or "N/A",
        "Story Titles": lcg_data.get("Story Titles", "N/A"),
        "Cover": (
            str(issue_details.image.original_url) if issue_details.image else "N/A"
        ),
        "Cover Date": formatted_cover_date,  # Use formatted cover date with day as 1
        "In Store Date": formatted_in_store_date,  # Use formatted in store date
        "Comic Vine ID": issue_details.id,
        "ISBN": lcg_data.get("ISBN", "N/A"),
        "Distributor SKU": lcg_data.get("Distributor SKU", "N/A"),
        "UPC": lcg_data.get("UPC", "N/A"),
        "Cover Price": lcg_data.get("Cover Price", "N/A"),
        "Page Count": lcg_data.get("Page Count", "N/A"),
        "Description": description_cleaned,  # Use cleaned description
        "Creators": lcg_data.get("Creators", "N/A"),
        "Creators (CV)": cv_creators if cv_creators else "N/A",
        "Characters": (
            ", ".join([char.name for char in issue_details.characters])
            if issue_details.characters
            else "N/A"
        ),
        "Teams": (
            ", ".join([team.name for team in issue_details.teams])
            if issue_details.teams
            else "N/A"
        ),
        "Arcs": (
            ", ".join([arc.name for arc in issue_details.story_arcs])
            if issue_details.story_arcs
            else "N/A"
        ),
    }

    # Print a readable summary
    print("\n--- Issue Details ---")
    for key, value in data.items():
        print(f"{key}: {value}")

    # Save to JSON file
    with open(json_file, mode="w", encoding="utf-8") as jsonf:
        json.dump(data, jsonf, indent=4, default=custom_serializer, ensure_ascii=False)
    print(f"\nData saved to {json_file}")

    # Optionally write to CSV
    with open(csv_file, mode="w", newline="", encoding="utf-8") as csvf:
        writer = csv.writer(csvf)
        writer.writerow(data.keys())
        writer.writerow(data.values())
    print(f"Data also written to {csv_file}")

    # Generate HTML file
    with open(html_file, mode="w", encoding="utf-8") as htmlf:
        # Join story titles with a semicolon
        story_titles = "; ".join(data.get("Story Titles", []))

        html_content = f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Comic Issue Details</title>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
            <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
        </head>
        <body>
            <div class="container mt-4">
                <h1 class="mb-4">Issue Details</h1>
                <div class="row">
                    <!-- Left column with cover image -->
                    <div class="col-md-4">
                        <div class="card">
                            <img src="{data['Cover']}" alt="Cover Image" class="card-img-top">
                            <div class="card-body">
                                <h5 class="card-title">Cover Image</h5>
                                <p class="card-text">This is the cover image of the comic issue.</p>
                                <button class="btn btn-sm btn-outline-secondary download-btn" onclick="downloadImage('{data['Cover']}')"><i class="bi bi-download"></i></button>
                            </div>
                        </div>
                    </div>

                    <!-- Right column with issue details -->
                    <div class="col-md-8">
                        <table class="table table-bordered">
                            <tbody>
                                <!-- Series, Number, Story Title, and Dates in a proportional layout -->
                                <tr>
                                    <th>Series</th>
                                    <td>{data["Series"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Series']}')"><i class="bi bi-clipboard"></i></button></td>
                                    <th>Number </th>
                                    <td>{data["Number"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Number']}')"><i class="bi bi-clipboard"></i></button></td>
                                </tr>
                                <tr>
                                    <th>Collection Title</th>
                                    <td>{data["Collection Title"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Collection Title']}')"><i class="bi bi-clipboard"></i></button></td>
                                    <th>Cover Date</th>
                                    <td>{data["Cover Date"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Cover Date']}')"><i class="bi bi-clipboard"></i></button></td>
                                </tr>
                                <tr>
                                    <th>In Store Date</th>
                                    <td>{data["In Store Date"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['In Store Date']}')"><i class="bi bi-clipboard"></i></button></td>
                                    <th>Comic Vine ID</th>
                                    <td>{data["Comic Vine ID"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Comic Vine ID']}')"><i class="bi bi-clipboard"></i></button></td>
                                </tr>
                                <tr>
                                    <th>Cover Price</th>
                                    <td>{data["Cover Price"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Cover Price']}')"><i class="bi bi-clipboard"></i></button></td>
                                    <th>Page Count</th>
                                    <td>{data["Page Count"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Page Count']}')"><i class="bi bi-clipboard"></i></button></td>
                                </tr>
                                <tr>
                                    <th>ISBN</th>
                                    <td>{data["ISBN"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['ISBN']}')"><i class="bi bi-clipboard"></i></button></td>
                                    <th>Distributor SKU</th>
                                    <td>{data["Distributor SKU"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Distributor SKU']}')"><i class="bi bi-clipboard"></i></button></td>
                                </tr>

                                <!-- UPC in one row -->
                                <tr><th>UPC</th><td colspan="3">{data["UPC"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['UPC']}')"><i class="bi bi-clipboard"></i></button></td></tr>

                                <!-- Story Titles in one row -->
                                <tr><th>Story Titles</th><td colspan="3">{story_titles} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard(`{story_titles}`)"><i class="bi bi-clipboard"></i></button></td></tr>

                                <!-- Description in one row -->
                                <tr><th>Description</th><td colspan="3">{data["Description"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Description']}')"><i class="bi bi-clipboard"></i></button></td></tr>

                                <!-- Characters in two columns -->
                                <tr>
                                    <th>Characters</th>
                                    <td colspan="3">
                                        <div class="row">
                                            <div class="col-md-6">
                                                <ul>
                                                    {"".join([f"<li>{char} <button class='btn btn-sm btn-outline-secondary copy-btn' onclick='copyToClipboard(\"{char}\")'><i class='bi bi-clipboard'></i></button></li>" for char in data['Characters'].split(', ')[:len(data['Characters'].split(', '))//2]])}
                                                </ul>
                                            </div>
                                            <div class="col-md-6">
                                                <ul>
                                                    {"".join([f"<li>{char} <button class='btn btn-sm btn-outline-secondary copy-btn' onclick='copyToClipboard(\"{char}\")'><i class='bi bi-clipboard'></i></button></li>" for char in data['Characters'].split(', ')[len(data['Characters'].split(', '))//2:]])}
                                                </ul>
                                            </div>
                                        </div>
                                    </td>
                                </tr>

                                <!-- Creators in one column -->
                                <tr>
                                    <th>Creators</th>
                                    <td colspan="3">
                                        <ol>
                                            {"".join([f"<li><strong>{creator['name']} <button class='btn btn-sm btn-outline-secondary copy-btn' onclick='copyToClipboard(\"{creator['name']}\")'><i class='bi bi-clipboard'></i></button></strong> - {creator['role']}</li>" for creator in data['Creators']])}
                                        </ol>
                                    </td>
                                </tr>

                                <!-- Teams in two columns -->
                                <tr>
                                    <th>Teams</th>
                                    <td colspan="3">
                                        <div class="row">
                                            <div class="col-md-6">
                                                <ul>
                                                    {"".join([f"<li>{team} <button class='btn btn-sm btn-outline-secondary copy-btn' onclick='copyToClipboard(\"{team}\")'><i class='bi bi-clipboard'></i></button></li>" for team in data['Teams'].split(', ')[:len(data['Teams'].split(', '))//2]])}
                                                </ul>
                                            </div>
                                            <div class="col-md-6">
                                                <ul>
                                                    {"".join([f"<li>{team} <button class='btn btn-sm btn-outline-secondary copy-btn' onclick='copyToClipboard(\"{team}\")'><i class='bi bi-clipboard'></i></button></li>" for team in data['Teams'].split(', ')[len(data['Teams'].split(', '))//2:]])}
                                                </ul>
                                            </div>
                                        </div>
                                    </td>
                                </tr>

                                <!-- Arcs in one column -->
                                <tr><th>Arcs</th><td colspan="3">{data["Arcs"]} <button class="btn btn-sm btn-outline-secondary copy-btn" onclick="copyToClipboard('{data['Arcs']}')"><i class="bi bi-clipboard"></i></button></td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <script>
                function copyToClipboard(text) {{
                    navigator.clipboard.writeText(text).then(function() {{
                        alert('Copied to clipboard: ' + text);
                    }}, function(err) {{
                        console.error('Failed to copy: ', err);
                    }});
                }}
                function downloadImage(url) {{
                    var link = document.createElement('a');
                    link.href = url;
                    link.download = 'cover.jpg';
                    link.click();
                }}
            </script>

            <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
        </body>
        </html>
        """
        htmlf.write(html_content)

    print(f"HTML file generated: {html_file}")

except Exception as e:
    print(f"An error occurred: {e}")
