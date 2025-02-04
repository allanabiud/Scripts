import os
import re
import time
from datetime import datetime

from rich.console import Console
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

console = Console()

# Constants
LOGIN_URL = "https://metron.cloud/accounts/login/"
FORM_URL = "https://metron.cloud/issue/create/"
USERNAME = os.getenv("METRON_USERNAME")
PASSWORD = os.getenv("METRON_PASSWORD")


def get_format_keyword(format):
    """Maps the format to a corresponding keyword."""
    format_keywords = {
        "Trade Paperback": "TPB",
        "Hardcover": "HC",
        "Softcover": "SC",
        "Graphic Novel": "GN",
        # Add more mappings as needed
    }
    return format_keywords.get(
        format, format
    )  # Default to the format if no match found


def get_year_from_date(date_str):
    """Extracts the year from a date string in the format DD-MM-YYYY."""
    try:
        date_obj = datetime.strptime(date_str, "%d-%m-%Y")
        return str(date_obj.year)
    except ValueError:
        return "Unknown"


def extract_core_series_name(series_name):
    """Extracts the core part of the series name, excluding extra details like series title prefixes and unnecessary suffixes."""

    # Step 1: Remove everything before the first colon (if present)
    core_series_name = series_name.split(":", 1)[-1].strip()

    # Step 2: Remove suffixes like "The Deluxe Edition", "The Complete", "HC", "TPB", "Paperback"
    core_series_name = re.sub(
        r"(The Deluxe Edition|The Complete|HC|TPB|Paperback)$", "", core_series_name
    ).strip()

    # Step 3: Remove any unwanted trailing punctuation (e.g., semicolons, spaces, or colons)
    core_series_name = re.sub(r"[;:,\.\s]+$", "", core_series_name).strip()

    return core_series_name


def login(driver):
    """Logs into the Metron website."""
    driver.get(LOGIN_URL)

    # Find login fields
    username_input = driver.find_element(By.NAME, "username")
    password_input = driver.find_element(By.NAME, "password")

    # Enter credentials and submit
    username_input.send_keys(USERNAME)
    password_input.send_keys(PASSWORD)
    password_input.send_keys(Keys.RETURN)

    # Wait for login to complete
    time.sleep(5)
    console.print("[bold green]Login successful![/bold green]")


def select_series(driver, series_name, data):
    """Handles the Select2 autocomplete dropdown for the 'series' field."""

    # Step 1: Prepare the search query with only the series name
    search_query = extract_core_series_name(series_name)
    console.print(f"[bold blue]Searching for:[/bold blue] {search_query}")

    # Step 2: Click the dropdown to activate the search field
    dropdown = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.ID, "select2-id_series-container"))
    )
    dropdown.click()
    time.sleep(1)

    # Step 3: Locate the active search box (use the last one)
    search_boxes = driver.find_elements(By.CSS_SELECTOR, "input.select2-search__field")
    search_box = search_boxes[-1]

    # Step 4: Type the series name
    search_box.send_keys(search_query)
    time.sleep(2)  # Allow time for suggestions to load

    # Step 5: Get the Format keyword and year
    format_keyword = get_format_keyword(data.get("Format", ""))
    cover_date = data.get("Cover Date", "")
    year = get_year_from_date(cover_date)

    # Step 6: Check for options in the dropdown
    while True:
        # Get all the <li> elements within the <ul>
        options = driver.find_elements(
            By.CSS_SELECTOR, "ul.select2-results__options li.select2-results__option"
        )

        for option in options:
            option_text = option.text.strip()
            console.print(f"[bold blue]Current option:[/bold blue] {option_text}")

            # Search for the series name, format keyword, and year in brackets
            if (
                series_name.lower() in option_text.lower()  # Match series name
                and format_keyword.lower()
                in option_text.lower()  # Match format keyword
                and f"({year})" in option_text  # Match year in brackets
            ):
                console.print(
                    f"[bold green]Correct match found: {option_text}! Selecting it.[/bold green]"
                )
                option.click()  # Select the correct option
                time.sleep(1)
                return
            # If only one option is found, select it
            elif len(options) == 1:
                console.print(
                    f"[bold green]Only one option found: {option_text}! Selecting it.[/bold green]"
                )
                option.click()  # Select the correct option
                time.sleep(1)
                return

        # Step 7: If no match is found, scroll to load more results
        load_more_button = driver.find_elements(
            By.CSS_SELECTOR, "li.select2-results__option--load-more"
        )
        if load_more_button:
            console.print(
                "[bold yellow]No match found, scrolling to load more options...[/bold yellow]"
            )
            driver.execute_script(
                "arguments[0].scrollIntoView();", load_more_button[0]
            )  # Scroll down to load more
            time.sleep(2)  # Wait for more options to load
        else:
            console.print(
                "[bold red]No more results available, exiting search.[/bold red]"
            )
            break

    console.print("[bold red]Series not found in options.[/bold red]")


def fill_django_form(driver, data):
    """Uses Selenium to open a Django form, fill in details, but NOT submit."""
    driver.get(FORM_URL)

    try:
        WebDriverWait(driver, 10)  # Wait for form to load

        # Select2 dropdown for Series field
        select_series(driver, data["Series"], data)

        # Fill the text fields
        driver.find_element(By.NAME, "number").send_keys(data["Number"])
        driver.find_element(By.NAME, "title").send_keys(data["Collection Title"])
        driver.find_element(By.NAME, "name").send_keys(data["Story Titles"])
        driver.find_element(By.NAME, "cover_date").send_keys(data["Cover Date"])
        driver.find_element(By.NAME, "store_date").send_keys(data["In Store Date"])
        driver.find_element(By.NAME, "cv_id").send_keys(data["Comic Vine ID"])
        driver.find_element(By.NAME, "isbn").send_keys(data["ISBN"])
        driver.find_element(By.NAME, "sku").send_keys(data["Distributor SKU"])
        driver.find_element(By.NAME, "upc").send_keys(data["UPC"])
        driver.find_element(By.NAME, "price").send_keys(data["Cover Price"])
        driver.find_element(By.NAME, "page").send_keys(data["Page Count"])
        driver.find_element(By.NAME, "desc").send_keys(data["Description"])
        driver.find_element(By.NAME, "creators").send_keys(data["Creators"])
        driver.find_element(By.NAME, "characters").send_keys(data["Characters"])

        console.print(
            "[bold green]Form has been filled in! Please review and submit manually.[/bold green]"
        )

        # Keep browser open for review
        input("[Press ENTER in the terminal to close the browser]")

    except Exception as e:
        console.print(f"[bold red]Error filling form: {e}[/bold red]")
