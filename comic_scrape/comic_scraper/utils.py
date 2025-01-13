import re
from datetime import date, datetime

from pydantic.networks import HttpUrl
from rich.console import Console

# Initialize Rich Console
console = Console()


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


def extract_issue_id(issue_url):
    """Extract the issue ID from the issue URL."""
    # Use a regular expression to extract the issue ID from the URL
    match = re.search(
        r"/(\d+)-(\d+)/", issue_url
    )  # Matches the number between the last two slashes
    if match:
        issue_id = match.group(2)  # Extracted issue ID
        return issue_id
    else:
        console.print(
            "[bold red]Invalid URL format! Could not extract issue ID.[/bold red]"
        )
        raise ValueError("Invalid URL format")
