from time import sleep

from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm, Prompt
from selenium import webdriver

from comic_scraper.comicvine import session
from comic_scraper.fill_form import fill_django_form, login
from comic_scraper.lcg_scraper import scrape_lcg_comic_page
from comic_scraper.output_handler import (
    create_directory,
    save_to_csv,
    save_to_html,
    save_to_json,
)
from comic_scraper.utils import (
    extract_issue_id,
    process_cover_date,
    process_in_store_date,
    strip_html_tags,
)

# Initialize Rich Console
console = Console()

# Path for output files
output_dir = "./output"
csv_file = f"{output_dir}/issue_details.csv"
json_file = f"{output_dir}/issue_details.json"
html_file = f"{output_dir}/issue_details.html"
log_file = f"{output_dir}/fetch_log.txt"

# Ensure the output directory exists
create_directory(output_dir)


# Display script title
console.print(
    Panel.fit(
        "[bold magenta]COMIC SCRAPE[/bold magenta]",
        border_style="magenta",
    )
)


def log_message(message):
    """Logs messages to a file."""
    with open(log_file, "a") as log:
        log.write(message + "\n")


def get_user_inputs():
    """Prompt the user for input and return them with borders."""
    # Get inputs
    issue_url = Prompt.ask(
        "[bold green]Enter the Comicvine Issue URL[/bold green]"
    ).strip()
    issue_id = extract_issue_id(issue_url)
    lcg_url = Prompt.ask(
        "[bold green]Enter the LCG Comic page URL[/bold green]"
    ).strip()

    return issue_id, lcg_url


def fetch_comicvine_issue(issue_id):
    """Fetch and process the issue details from Comicvine."""
    # Simulate a slow network connection
    sleep(2)
    issue_details = session.get_issue(issue_id=int(issue_id))
    cover_date = issue_details.cover_date or "N/A"
    in_store_date = issue_details.store_date or "N/A"

    return {
        "issue_details": issue_details,
        "formatted_cover_date": process_cover_date(cover_date),
        "formatted_in_store_date": process_in_store_date(in_store_date),
    }


def process_issue_data(
    issue_details, lcg_data, formatted_cover_date, formatted_in_store_date
):
    cv_creators = [
        (
            f"{creator.name} ({', '.join(creator.roles)})"
            if isinstance(creator.roles, list)
            else f"{creator.name} ({creator.roles})"
        )
        for creator in issue_details.creators or []
        # for creator in issue_details.creators or []
    ]
    description_cleaned = strip_html_tags(issue_details.description or "N/A")

    return {
        "Series": issue_details.volume.name if issue_details.volume else "N/A",
        "Number": issue_details.number or "N/A",
        "Collection Title": issue_details.name or "N/A",
        "Story Titles": lcg_data.get("Story Titles", "N/A"),
        "Cover": (
            str(issue_details.image.original_url) if issue_details.image else "N/A"
        ),
        "Cover Date": formatted_cover_date,
        "In Store Date": formatted_in_store_date,
        "Comic Vine ID": issue_details.id,
        "ISBN": lcg_data.get("ISBN", "N/A"),
        "Distributor SKU": lcg_data.get("Distributor SKU", "N/A"),
        "UPC": lcg_data.get("UPC", "N/A"),
        "Cover Price": lcg_data.get("Cover Price", "N/A"),
        "Page Count": lcg_data.get("Page Count", "N/A"),
        "Format": lcg_data.get("Format", "N/A"),
        "Description": description_cleaned,
        "Creators": lcg_data.get("Creators", "N/A"),
        "Creators (CV)": ", ".join(cv_creators) if cv_creators else "N/A",
        "Characters": (
            [{"name": char.name, "id": char.id} for char in issue_details.characters]
            if issue_details.characters
            else "N/A"
        ),
        # "Characters": (
        #     ", ".join([char.name for char in issue_details.characters])
        #     if issue_details.characters
        #     else "N/A"
        # ),
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


def main():
    """Main function to fetch issue data and save outputs."""
    try:
        # Get inputs with borders
        issue_id, lcg_url = get_user_inputs()

        # Log user inputs
        log_message(f"User Input - Comicvine Issue ID: {issue_id}")
        log_message(f"User Input - LCG URL: {lcg_url}")

        # Use a spinner while fetching Comicvine issue details
        with console.status("[bold green]Fetching issue details...", spinner="dots"):
            log_message(f"Fetching issue with ID {issue_id} from Comicvine...")
            cv_data = fetch_comicvine_issue(issue_id)

        # Get ISBN and Distributor SKU from the LCG page
        lcg_data = scrape_lcg_comic_page(lcg_url)

        # Combine and process data
        data = process_issue_data(
            issue_details=cv_data["issue_details"],
            lcg_data=lcg_data,
            formatted_cover_date=cv_data["formatted_cover_date"],
            formatted_in_store_date=cv_data["formatted_in_store_date"],
        )
        # Display the data summary in a bordered panel
        console.print(
            Panel.fit(
                "\n".join(
                    [
                        f"[green]{k}[/green]: [yellow]{v}[/yellow]"
                        for k, v in data.items()
                    ]
                ),
                title="[bold magenta]Issue Details[/bold magenta]",
                title_align="left",
                border_style="green",
            ),
        )

        # Save outputs
        save_to_json(data, json_file)
        save_to_csv(data, csv_file)
        save_to_html(data, html_file)

        # Prompt the user if they want to fill the form
        if Confirm.ask(
            "[bold green]Do you want to fill the Metron form with the data?[/bold green]",
            default=True,
        ):
            # Set up Firefox WebDriver
            options = webdriver.FirefoxOptions()
            driver = webdriver.Firefox(options=options)
            login(driver)
            fill_django_form(driver, data)

        # Log results
        log_message(
            f"Data saved to:\n  - JSON: {json_file}\n  - CSV: {csv_file}\n  - HTML: {html_file}"
        )
        console.print(
            Panel.fit(
                f"[green]Data saved to:[/green]\n [green]JSON:[/green] [yellow]{json_file}[/yellow]\n [green]CSV:[/green] [yellow]{csv_file}[/yellow]\n [green]HTML:[/green] [yellow]{html_file}[/yellow]",
                title="[bold magenta]Output[/bold magenta]",
                title_align="left",
                border_style="green",
            )
        )

    except Exception as e:
        error_message = f"An error occurred: {e}"
        print(error_message)
        log_message(error_message)


if __name__ == "__main__":
    main()
