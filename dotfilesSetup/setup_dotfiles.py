import os
import re
import shutil
import subprocess
from pathlib import Path

from rich.console import Console
from rich.markdown import Markdown
from rich.padding import Padding
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.prompt import Confirm, Prompt
from rich.style import Style
from rich.table import Table

# Initialize Rich console
console = Console()

################################################################################
# Messages
################################################################################

# Welcome Message
welcome_message = """
This is my dotfiles setup script.

It is able to:
- Install script dependencies
- Clone dotfiles repositories
- Stow dotfiles
- Handle existing dotfiles
"""

prompt_sudo_message = """
This script requires root privileges to:
- Install script dependencies
- Configure dotfiles
"""

script_dependencies_message = """
This following dependencies are required to run this script:

{dependencies_list}
"""

clone_dotfiles_repository_message = """
Acceptable URL Syntax:

- HTTPS URL: https://github.com/username/repository.git
- SSH URL: git@github.com:username/repository.git
"""

target_directory_message = """
Acceptable Directory Syntax:

- Absolute path: /home/YOUR_USERNAME/dotfiles
- Relative path: ~/dotfiles
"""

directory_exists_message = """
Directory "{target_dir}" already exists.

1. Delete existing repo and clone again
2. Try updating the existing repo
3. Use existing repo without updating
4. Exit
"""

dotfiles_to_stow_message = """
You have selected the following dotfiles to stow:

{selected_dotfiles}
"""

broken_symlink_message = """
File or directory {target_path} is a broken symlink pointing to a non-existent file or directory.

1. Delete the broken symlink and proceed
2. Skip stowing this file
"""

symlink_to_dotfiles_repo_message = """
File or directory {target_path} is already stowed by another package in the dotfiles repo.

1. Overwrite symlink
2. Skip stowing this file
"""

symlink_to_external_location_message = """
File or directory {target_path} is symlinked to {link_target}.

1. Overwrite symlink
2. Backup symlink and replace
3. Skip stowing this file
"""

regular_file_and_directories_message = """
File or directory {target_path} already exists.

1. Overwrite
2. Backup and replace
3. Skip stowing this file
"""

repeat_section_message = """
Choose a section to repeat or type 'exit' to finish.

1. Install Dependencies
2. Clone Dotfiles
3. Stow Dotfiles
"""

################################################################################
# Styles
################################################################################

# Markdown
markdown_style = Style(bold=True, color="green")
list_style = Style(bold=True, color="yellow")


################################################################################
# Utility functions
################################################################################


# Padding
def add_padding(text="", padding=(1, 0, 0, 0)):
    console.print(
        Padding(
            text,
            pad=padding,
        )
    )


# Run commands with a spinner
def run_command(command, spinner_description, show_error=True):
    """Run a shell command and display a spinner while it executes."""
    with Progress(
        SpinnerColumn(), TextColumn(f"[cyan]{spinner_description}")
    ) as progress:
        task = progress.add_task("spinner")
        try:
            subprocess.run(
                command, shell=True, check=True, capture_output=True, text=True
            )
            progress.stop_task(task)
            return True
        except subprocess.CalledProcessError as e:
            progress.stop_task(task)
            if show_error:
                console.print(f"[red]Error:[/red] {e}")
            return False


# Prompt for sudo access
def prompt_sudo():
    """Prompt for sudo access with confirmation."""
    add_padding()
    console.print(
        Panel(
            Markdown(prompt_sudo_message, style=markdown_style),
            title="[bold blue]Sudo Access[/bold blue]",
            title_align="left",
        )
    )

    if Confirm.ask("[yellow]Do you want to grant sudo access?[/yellow]", default=True):
        # Clear any existing sudo credentials
        run_command("sudo -k", "Clearing existing sudo credentials")

        # Attempt to get sudo access
        try:
            console.print("[cyan]Requesting sudo access...[/cyan]")
            subprocess.run("sudo -v", shell=True, check=True)
            console.print("[green]Root access granted[/green]")

            # Keep sudo privileges alive
            console.print("[cyan]Maintaining sudo privileges...[/cyan]")
            command = "while true; do sudo -n true; sleep 60; kill -0 $$ || exit; done 2>/dev/null &"
            os.system(command)
        except Exception:
            console.print("[red]Failed to get sudo access. Exiting.[/red]")
            exit(1)
    else:
        console.print("[red]Root access denied. Exiting.[/red]")
        exit(1)


# Validate Git URL
def validate_git_url(url):
    """
    Validate a Git URL.

    Args:
        url (str): The URL to validate.

    Returns:
        bool: True if the URL is a valid Git URL, False otherwise.
    """
    git_url_regex = re.compile(
        r"^((https?://|git@|git://)([a-zA-Z0-9_.-]+@)?[a-zA-Z0-9_.-]+)(:|/)[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+(.git)?$"
    )
    return bool(git_url_regex.match(url))


# Validate directory path
def validate_directory_path(path):
    """
    Validate a directory path.

    Args:
        path (str): The directory path to validate.

    Returns:
        bool: True if the path is valid, False otherwise.
    """
    # Expand tilde to the user's home directory
    expanded_path = os.path.expanduser(path)

    # Check if path contains only allowed characters
    if re.match(r"^[a-zA-Z0-9_/.\-]+$", expanded_path):
        return True
    return False


def handle_existing_dotfiles(file):
    """Handle existing configuration files for stowing dotfiles."""
    home = Path.home()
    target_path = home / ".config" / file

    if target_path.exists() or target_path.is_symlink():
        while True:
            if target_path.is_symlink():
                link_target = os.readlink(target_path)

                # Handle broken symlinks
                if not os.path.exists(link_target):
                    formatted_message = broken_symlink_message.format(
                        target_path=target_path
                    )
                    add_padding()
                    console.print(
                        Panel(
                            Markdown(
                                formatted_message,
                                style=markdown_style,
                            ),
                            title="[bold blue]Broken symlink[/bold blue]",
                            title_align="left",
                            expand=False,
                        )
                    )
                    choice = Prompt.ask(
                        "[blue]Select an option[/blue]", choices=["1", "2"]
                    )

                    if choice == "1":
                        if Confirm.ask(
                            f"[red]Are you sure you want to delete the broken symlink {target_path}?[/red]"
                        ):
                            target_path.unlink()
                            console.print(
                                f"[green]Removed broken symlink {target_path}[/green]"
                            )
                            return True
                        else:
                            console.print(f"[cyan]Skipping {target_path}[/cyan]")
                            return False
                    elif choice == "2":
                        console.print(f"[cyan]Skipping {target_path}[/cyan]")
                        return False

                # Handle symlinks to dotfiles repo
                elif link_target.startswith(f"{home}/dotfiles/"):
                    formatted_message = symlink_to_dotfiles_repo_message.format(
                        target_path=target_path
                    )
                    add_padding()
                    console.print(
                        Panel(
                            Markdown(
                                formatted_message,
                                style=markdown_style,
                            ),
                            title="[bold blue]Symlinked to dotfiles repo[/bold blue]",
                            title_align="left",
                            expand=False,
                        )
                    )
                    choice = Prompt.ask(
                        "[blue]Select an option[/blue]", choices=["1", "2"]
                    )

                    if choice == "1":
                        stow_dir = Path(link_target).parents[1]
                        package = Path(link_target).parents[0].name
                        if Confirm.ask(
                            f"[red]Are you sure you want to unstow {package}?[/red]"
                        ):
                            subprocess.run(
                                ["stow", "-D", "-d", stow_dir, package], check=True
                            )
                            target_path.unlink()
                            console.print(
                                f"[green]Unstowed package {package} and removed {target_path}[/green]"
                            )
                            return True
                        else:
                            console.print(f"[cyan]Skipping {target_path}[/cyan]")
                            return False
                    elif choice == "2":
                        console.print(f"[cyan]Skipping {target_path}[/cyan]")
                        return False

                # Handle symlinks to external locations
                else:
                    formatted_message = symlink_to_external_location_message.format(
                        target_path=target_path, link_target=link_target
                    )
                    add_padding()
                    console.print(
                        Panel(
                            Markdown(
                                formatted_message,
                                style=markdown_style,
                            ),
                            title="[bold blue]Symlinked to other location[/bold blue]",
                            title_align="left",
                            expand=False,
                        )
                    )
                    choice = Prompt.ask(
                        "[blue]Select an option[/blue]", choices=["1", "2", "3"]
                    )

                    if choice == "1":
                        if Confirm.ask(
                            f"[red]Are you sure you want to overwrite {target_path}?[/red]"
                        ):
                            target_path.unlink()
                            console.print(f"[green]Removed {target_path}[/green]")
                            return True
                        else:
                            console.print(f"[cyan]Skipping {target_path}[/cyan]")
                            return False
                    elif choice == "2":
                        if Confirm.ask(
                            f"[red]Are you sure you want to backup {target_path}?[/red]"
                        ):
                            backup_path = target_path.with_suffix(".backup")
                            shutil.move(target_path, backup_path)
                            console.print(
                                f"[green]Backed up {target_path} as {backup_path}[/green]"
                            )
                            return True
                        else:
                            console.print(f"[cyan]Skipping {target_path}[/cyan]")
                            return False
                    elif choice == "3":
                        console.print(f"[cyan]Skipping {target_path}[/cyan]")
                        return False

            # Handle regular files or directories
            else:
                formatted_message = regular_file_and_directories_message.format(
                    target_path=target_path
                )
                add_padding()
                console.print(
                    Panel(
                        Markdown(
                            formatted_message,
                            style=markdown_style,
                        ),
                        title="[bold blue]File or directory already exists[/bold blue]",
                        title_align="left",
                        expand=False,
                    )
                )
                choice = Prompt.ask(
                    "[blue]Select an option[/blue] (1/2/3)", choices=["1", "2", "3"]
                )

                if choice == "1":
                    if Confirm.ask(
                        f"[red]Are you sure you want to overwrite {target_path}?[/red]"
                    ):
                        if target_path.is_dir():
                            shutil.rmtree(target_path)
                        else:
                            target_path.unlink()
                        console.print(f"[green]Removed {target_path}[/green]")
                        return True
                    else:
                        console.print(f"[cyan]Skipping {target_path}[/cyan]")
                        return False
                elif choice == "2":
                    if Confirm.ask(
                        f"[red]Are you sure you want to backup {target_path}?[/red]"
                    ):
                        backup_path = target_path.with_suffix(".backup")
                        shutil.move(target_path, backup_path)
                        console.print(
                            f"[green]Backed up {target_path} as {backup_path}[/green]"
                        )
                        return True
                    else:
                        console.print(f"[cyan]Skipping {target_path}[/cyan]")
                        return False
                elif choice == "3":
                    console.print(f"[cyan]Skipping {target_path}[/cyan]")
                    return False

    return True


def list_dotfiles(dotfiles_dir):
    """List all dotfiles in the cloned repository."""
    return [
        f
        for f in os.listdir(dotfiles_dir)
        if not f.endswith((".md", ".git", ".gitignore"))
    ]


def stow_dotfile(dotfile, dotfiles_dir, home_dir):
    """Stow a single dotfile."""
    target_path = Path(home_dir) / ".config" / dotfile
    if handle_existing_dotfiles(target_path):
        result = subprocess.run(
            ["stow", "-v", "-R", "-t", str(home_dir), dotfile], cwd=dotfiles_dir
        )
        if result.returncode == 0:
            console.print(f"[green]Stowed {dotfile} successfully.[/green]")
        else:
            console.print(f"[red]Failed to stow {dotfile}.[/red]")
    else:
        print(f"Skipped {dotfile}.")


################################################################################
# Script functions
################################################################################


def welcome():
    """Print welcome message."""
    console.print(Markdown("# DOTFILES SETUP SCRIPT", style="bold yellow"))
    console.print(
        Panel(
            Markdown(
                welcome_message,
                style=markdown_style,
            ),
            expand=True,
        )
    )


def install_dependencies():
    """Install script dependencies."""
    add_padding()
    console.print(Markdown("# Dependencies", style="bold yellow"))

    dependencies = ["stow", "git"]
    missing_dependencies = []

    for dependency in dependencies:
        if (
            run_command(
                f"pacman -Q {dependency}",
                f"Checking for {dependency}...",
                show_error=False,
            )
            is None
        ):
            missing_dependencies.append(dependency)

    if missing_dependencies:
        dependencies_list = "\n".join([f"- **{dep}**" for dep in missing_dependencies])
        formatted_message = script_dependencies_message.format(
            dependencies_list=dependencies_list
        )
        console.print(
            Panel(
                Markdown(
                    formatted_message,
                    style=markdown_style,
                ),
                title="[bold cyan]Install script dependencies[/bold cyan]",
                title_align="left",
                expand=False,
            )
        )
        # Prompt the user to install each missing dependency
        for dependency in missing_dependencies:
            if Confirm.ask(
                f"[bold yellow]Install [yellow]{dependency}[/yellow]?[/bold yellow]",
                default=True,
            ):
                run_command(
                    f"sudo pacman -S --noconfirm {dependency}",
                    f"Installing {dependency}",
                )
                console.print(f"[green]{dependency} was installed![/green]")
            else:
                console.print(f"[red]{dependency} was not installed![/red]")
    else:
        console.print("[green]All required dependencies are already installed.[/green]")


def clone_dotfiles():
    """Clone dotfiles repositories."""
    add_padding()
    console.print(Markdown("# Clone dotfiles repositories", style="bold yellow"))

    default_repo_url = "https://github.com/allanabiud/dotfiles.git"
    default_target_dir = os.path.expanduser("~/dotfiles")
    clone_success = False

    # Prompt for repository URL
    while True:
        console.print(
            Panel(
                Markdown(
                    clone_dotfiles_repository_message,
                    style=markdown_style,
                ),
                title="[bold blue]Repository URL[/bold blue]",
                title_align="left",
                expand=False,
            )
        )
        user_repo_url = Prompt.ask(
            "[blue]Enter the repository URL[/blue]",
            default=default_repo_url,
        )
        if validate_git_url(user_repo_url):
            repo_url = user_repo_url
            console.print(
                Padding(
                    f"[bold blue]Using[/bold blue] [bold yellow]{repo_url}[/bold yellow]",
                    (1, 0),
                )
            )
            break
        else:
            console.print("[red]Invalid Git URL. Please enter a valid Git URL.[/red]")

    # Prompt for target directory
    while True:
        console.print(
            Panel(
                Markdown(
                    target_directory_message,
                    style=markdown_style,
                ),
                title="[bold blue]Target Directory[/bold blue]",
                title_align="left",
                expand=False,
            )
        )
        user_target_dir = Prompt.ask(
            "[blue]Enter the target directory[/blue]",
            default=default_target_dir,
        )
        if validate_directory_path(user_target_dir):
            target_dir = os.path.expanduser(user_target_dir)
            console.print(
                Padding(
                    f"[bold blue]Using[/bold blue] [bold yellow]{target_dir}[/bold yellow]",
                    (1, 0),
                )
            )
            break
        else:
            console.print(
                "[red]Invalid directory path. Please enter a valid directory path.[/red]"
            )

    # Handle cloning or updating the repository
    while not clone_success:
        if os.path.isdir(target_dir):
            formatted_message = directory_exists_message.format(target_dir=target_dir)
            console.print(
                Panel(
                    formatted_message,
                    style=list_style,
                    title="[yellow]Existing directory![/yellow]",
                    title_align="left",
                    expand=False,
                )
            )
            choice = Prompt.ask(
                "[blue]Select an option[/blue]", choices=["1", "2", "3", "4"]
            )

            if choice == "1":
                if Confirm.ask(
                    f"[red]Are you sure you want to delete {target_dir}?[/red]"
                ):
                    shutil.rmtree(target_dir)
                    console.print("[green]Directory deleted.[/green]")
                    if Confirm.ask(
                        f"[blue]Clone [yellow]{repo_url}[/yellow] to [yellow]{target_dir}[/yellow]?[/blue]",
                        default=True,
                    ):
                        clone_success = run_command(
                            f"git clone {repo_url} {target_dir}",
                            "Cloning",
                        )
                else:
                    console.print(
                        "[yellow]Directory not deleted. Choose another option.[/yellow]"
                    )

            elif choice == "2":
                console.print(
                    "[blue]Attempting to update existing repository...[/blue]"
                )
                if run_command(
                    f"cd {target_dir} && git remote set-url origin {repo_url} && git pull",
                    "Updating Repository",
                ):
                    console.print("[green]Repository updated successfully.[/green]")
                    clone_success = True
                else:
                    console.print("[red]Failed to update the repository.[/red]")

            elif choice == "3":
                console.print("[green]Using existing repository as is.[/green]")
                clone_success = True

            elif choice == "4":
                console.print(
                    "[yellow]Exiting without cloning the repository.[/yellow]"
                )
                return None
        else:
            if Confirm.ask(
                f"[blue]Clone [yellow]{repo_url}[/yellow] to [yellow]{target_dir}[/yellow]?[/blue]",
                default=True,
            ):
                clone_success = run_command(
                    f"git clone {repo_url} {target_dir}",
                    "Cloning",
                )
            else:
                console.print(
                    "[yellow]Exiting without cloning the repository.[/yellow]"
                )
                return None

    console.print(
        Padding(
            Panel(
                "[green]Repository cloned/updated successfully.[/green]",
                title="[bold blue]Success[/bold blue]",
                title_align="left",
                expand=False,
            ),
            (1, 0, 0, 0),
        )
    )
    DOTFILES_DIR = target_dir
    return DOTFILES_DIR


def stow_dotfiles(dotfiles_dir):
    add_padding()
    console.print(Markdown("# Stow Dotfiles", style="bold yellow"))

    home_dir = str(Path.home())

    if not dotfiles_dir:
        console.print(
            "[red]DOTFILES_DIR is not set. Did you clone the dotfiles repo first?"
        )
        return

    dotfiles_list = list_dotfiles(dotfiles_dir)
    table = Table(
        title="Dotfiles in cloned repo",
        title_style="bold blue",
        header_style="bold yellow",
        border_style="bold cyan",
        show_lines=True,
        expand=True,
    )

    # Add columns
    table.add_column("Number", justify="center", style="bold magenta")
    table.add_column("Dotfile Name", justify="left")

    # Add rows
    for index, dotfile in enumerate(dotfiles_list, start=1):
        table.add_row(str(index), dotfile)

    console.print(table)

    selection = Prompt.ask(
        f"[blue]Select dotfile(s) to stow (space-separated numbers or 'a' for all)[/blue] [magenta][1-{len(dotfiles_list)} or a][/magenta]",
        default="a",
    )

    if selection.strip().lower() == "a":
        selected_dotfiles = dotfiles_list
    else:
        try:
            selected_dotfiles = [
                dotfiles_list[int(num) - 1]
                for num in selection.split()
                if 1 <= int(num) <= len(dotfiles_list)
            ]
        except (ValueError, IndexError):
            console.print("[red]Invalid selection.")
            return

    formatted_message = dotfiles_to_stow_message.format(
        selected_dotfiles="\n".join([f" - {dotfile}" for dotfile in selected_dotfiles])
    )
    add_padding()
    console.print(
        Panel(
            Markdown(
                formatted_message,
                style=markdown_style,
            ),
            title="[bold blue]Selected dotfiles[/bold blue]",
            title_align="left",
            expand=False,
        )
    )
    if not Confirm.ask("[bold blue]Is this correct?[/bold blue]"):
        console.print("[red]Please reselect dotfiles to stow.")
        return stow_dotfiles(dotfiles_dir)

    os.chdir(dotfiles_dir)
    for dotfile in selected_dotfiles:
        console.print(f"[bold blue]Stowing {dotfile}...[/bold blue]")
        stow_dotfile(dotfile, dotfiles_dir, home_dir)


def script_completed():
    """Print script completed message."""
    add_padding()
    console.print(Markdown("# SETUP COMPLETE!", style="bold green"))


# Main execution logic
def main():
    # Welcome message
    welcome()

    if not Confirm.ask(
        "[bold yellow]Continue?[/bold yellow]",
        default=True,
    ):
        return

    # Prompt for sudo access
    prompt_sudo()
    if not Confirm.ask("[bold yellow]Continue?[/bold yellow]", default=True):
        return

    # Define repeatable sections and their corresponding functions
    sections = {
        "Install Dependencies": install_dependencies,
        "Clone Dotfiles": clone_dotfiles,
        "Stow Dotfiles": lambda: stow_dotfiles(dotfiles_dir),
    }

    executed_sections = []

    # Loop through the repeatable sections
    for section_name, section_function in sections.items():
        while True:
            # Execute the section
            result = section_function()

            # Store result if needed (dotfiles_dir for stow_dotfiles)
            if section_name == "Clone Dotfiles":
                dotfiles_dir = result

            executed_sections.append(section_name)

            # Ask if the user wants to repeat this section
            if not Confirm.ask(
                f"[bold yellow]Repeat {section_name}?[/bold yellow]", default=False
            ):
                break

        # Ask if the user wants to continue to the next section
        if not Confirm.ask(
            "[bold yellow]Continue to next section?[/bold yellow]", default=True
        ):
            break

    # Script completed
    script_completed()

    # Final prompt to repeat any section
    while True:
        console.print(
            Panel(
                Markdown(repeat_section_message, style=markdown_style),
                title="[bold blue]Repeat Section[/bold blue]",
                title_align="left",
                expand=False,
            )
        )

        choice = Prompt.ask(
            "[bold blue]Enter a number to repeat a section (or 'exit')[/bold blue] [magenta][1-3 or 'exit']:[/magenta]",
            default="exit",
        )

        if choice.lower() == "exit":
            break

        try:
            choice_index = int(choice) - 1
            if 0 <= choice_index < len(executed_sections):
                section_to_repeat = executed_sections[choice_index]
                console.print(
                    f"\n[bold cyan]>>> Repeating: {section_to_repeat}[/bold cyan]\n"
                )
                sections[section_to_repeat]()
            else:
                console.print("[bold red]Invalid selection. Try again.[/bold red]")
        except ValueError:
            console.print(
                "[bold red]Invalid input. Please enter a number or 'exit'.[/bold red]"
            )

    console.print("[bold green]Script execution finished![/bold green]")


if __name__ == "__main__":
    main()
