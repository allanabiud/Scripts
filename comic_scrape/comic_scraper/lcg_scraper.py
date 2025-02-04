import re

import cloudscraper
from bs4 import BeautifulSoup


# LCG scraping function (from previous implementation)
def scrape_lcg_comic_page(url):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
        "Referer": "https://leagueofcomicgeeks.com",
    }

    scraper = cloudscraper.create_scraper()
    response = scraper.get(url, headers=headers)

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

            # Improved regex pattern to extract the details like pages and price
            # This pattern matches the page count (e.g., "280 pages") and price (e.g., "$49.99"),
            # and ignores other content like "Hardcover" or "Dustjacket Cover".
            pattern = r"(\d+)\s+pages\s+·\s+\$(\d+\.\d{2})"
            match = re.search(pattern, price_details_text)

            # Regex pattern to extract the details like pages and price
            # pattern = r"(\w+ \w+)\s+·\s+(\d+)\s+pages\s+·\s+\$(\d+\.\d{2})"
            # match = re.search(pattern, price_details_text)

            if match:
                data["Cover Price"] = match.group(2)  # $16.99
                data["Page Count"] = match.group(1)  # 176
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
        unwanted_titles = {
            "overview",
            "[Overview]",
            "[title page]",
            "[Title Page]",
            "[dedication]",
            "[Dedication]",
            "[illustration, title, and credits]",
            "[Illustration, Title, and Credits]",
            "[title, illustration and credits]",
            "[Title, Illustration and Credits]",
            "[creator biography]",
            "[Creator Biography]",
            "[cover reprint]",
            "[Cover Reprint]",
            "[variant cover gallery]",
            "[Variant Cover Gallery]",
            "Cover Progression",
        }
        story_titles = []
        story_section = soup.find_all(
            "h4", class_="story-title color-primary m-0 p-0"
        )  # Updated class names
        if story_section:
            for story in story_section:
                title = story.get_text(strip=True)
                # Normalize title to lowercase for comparison and check if it is unwanted
                normalized_title = title.lower()
                # if title not in unwanted_titles:
                #     story_titles.append(title)

                # Filter out unwanted titles
                if normalized_title not in unwanted_titles:
                    # Remove square brackets from the title
                    cleaned_title = re.sub(r"^\[(.*?)\]$", r"\1", title.strip())
                    story_titles.append(cleaned_title)

        # Format story titles as a semicolon-separated string
        data["Story Titles"] = "; ".join(story_titles) if story_titles else "N/A"
        # data["Story Titles"] = story_titles if story_titles else ["N/A"]

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

        # Scrape creators from all sections where ID starts with 'creators-'
        creators_sections = soup.find_all(
            "section", id=lambda x: x and x.startswith("creators-")
        )
        for creators_section in creators_sections:
            creator_divs = creators_section.find_all("div", class_="col-auto")
            for creator_div in creator_divs:
                name_tag = creator_div.find("div", class_="name")
                role_tag = creator_div.find("div", class_="role")
                if name_tag and role_tag:
                    creator_name = name_tag.get_text(strip=True)
                    creator_role = role_tag.get_text(strip=True)
                    creators.append({"name": creator_name, "role": creator_role})

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
            # Dictionary to store creators and their roles
            merged_creators = {}

            for creator in combined_creators:
                creator_name = creator["name"]
                creator_role = creator["role"]

                # If the creator already exists, append the role
                if creator_name in merged_creators:
                    # Add new roles without duplicates
                    existing_roles = set(merged_creators[creator_name].split(", "))
                    new_roles = set(creator_role.split(", "))
                    merged_creators[creator_name] = ", ".join(
                        existing_roles | new_roles
                    )
                else:
                    # Add the creator if not already in the dictionary
                    merged_creators[creator_name] = creator_role

            # Convert the merged creators dictionary back to a list of dictionaries
            data["Creators"] = [
                {"name": name, "role": role} for name, role in merged_creators.items()
            ]
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
