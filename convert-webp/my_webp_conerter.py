import argparse
import logging
import os
import pathlib
import shlex
import shutil
import subprocess

from rich.console import Console
from rich.logging import RichHandler
from rich.progress import Progress

console = Console()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(message)s",
    handlers=[RichHandler(console=console, rich_tracebacks=True)],
)
logger = logging.getLogger("webp_converter")


def get_file_mime_type(comic_file):
    command = shlex.split(f"file -b --mime-type {comic_file}")
    try:
        rar_mime = {
            "application/vnd.rar",
            "application/x-rar-compressed",
            "application/x-rar",
            "application/rar",
        }
        zip_mime = {
            "application/zip",
            "application/x-zip-compressed",
            "multipart/x-zip",
        }
        output = subprocess.check_output(command).decode("utf-8").strip()
        if output in rar_mime:
            return "rar"
        elif output in zip_mime:
            return "zip"
        else:
            return None
    except subprocess.CalledProcessError:
        logger.error(f"Failed to detect MIME type for {comic_file}")
        return None


def create_work_dir(filename):
    work_path = pathlib.Path("./work") / filename.stem
    work_path.mkdir(parents=True, exist_ok=True)
    return work_path


def extract_comic(work_path, filename):
    filetype = get_file_mime_type(filename)
    if not filetype:
        console.print(f"[red]Unsupported file type: {filename}[/red]")
        return

    command = (
        f"7z e -o{work_path} {filename}"
        if filetype == "zip"
        else f"unrar e {filename} {work_path}"
    )

    subprocess.run(
        shlex.split(command), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    console.print(f"[green]Extracted {filename}[/green]")


def convert_images_to_webp(work_path):
    valid_ext = {".jpg", ".jpeg", ".png", ".gif"}
    files = [f for f in work_path.iterdir() if f.suffix.lower() in valid_ext]

    with Progress(console=console) as progress:
        task = progress.add_task("[cyan]Converting images...", total=len(files))
        for file in files:
            out_path = work_path / f"{file.stem}.webp"
            cmd = (
                f"gif2webp {file} -q 80 -o {out_path}"
                if file.suffix.lower() == ".gif"
                else f"cwebp {file} -q 80 -o {out_path}"
            )
            subprocess.run(
                shlex.split(cmd), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            progress.advance(task)


def create_comic_archive(work_path, output_file):
    output_zip = f"{output_file}.cbz"
    cmd = f"7z a -tzip {output_zip} {work_path}/*.webp"
    subprocess.run(
        shlex.split(cmd), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    console.print(f"[green]Created {output_zip}[/green]")


def process_comic(file):
    file = pathlib.Path(file)
    if not file.exists():
        console.print(f"[red]File not found: {file}[/red]")
        return

    work_path = create_work_dir(file)
    extract_comic(work_path, file)
    convert_images_to_webp(work_path)
    create_comic_archive(work_path, file)
    shutil.rmtree(work_path)
    console.print(f"[bold green]Conversion complete: {file}[/bold green]")


def main():
    parser = argparse.ArgumentParser(
        description="Convert comic book archives to WebP format."
    )
    parser.add_argument(
        "files", nargs="+", help="Comic files or directories to convert."
    )
    args = parser.parse_args()

    for item in args.files:
        path = pathlib.Path(item)
        if path.is_dir():
            for comic in path.glob("*.cbz"):
                process_comic(comic)
        else:
            process_comic(path)


if __name__ == "__main__":
    main()
