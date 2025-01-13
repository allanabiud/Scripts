import csv
import json
import os

from jinja2 import Environment, FileSystemLoader

from .utils import custom_serializer


def create_directory(file_path):
    """Ensure the directory for the file exists, create if not."""
    directory = os.path.dirname(file_path)
    if not os.path.exists(directory):
        os.makedirs(directory)


def save_to_json(data, file_path):
    with open(file_path, mode="w", encoding="utf-8") as jsonf:
        json.dump(data, jsonf, indent=4, default=custom_serializer, ensure_ascii=False)


def save_to_csv(data, file_path):
    with open(file_path, mode="w", newline="", encoding="utf-8") as csvf:
        writer = csv.writer(csvf)
        writer.writerow(data.keys())
        writer.writerow(data.values())


def save_to_html(data, file_path, template_dir="./templates"):
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template("template.html")
    rendered_html = template.render(data=data)

    with open(file_path, mode="w", encoding="utf-8") as htmlf:
        htmlf.write(rendered_html)
