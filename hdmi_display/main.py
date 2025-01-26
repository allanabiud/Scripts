import os
import subprocess

MODES = ["project", "extend", "mirror"]
ICONS = {"project": "🖥️", "extend": "🖥️➕", "mirror": "🖥️🔄"}


# current_mode_index = 0


def detect_hdmi():
    result = subprocess.run(["wlr-randr"], capture_output=True, text=True)
    return "HDMI" in result.stdout


def set_display_mode(mode):
    if mode == "project":
        subprocess.run(
            ["wlr-randr", "--output", "HDMI-A-1", "--mode", "1366x768", "--pos", "0,0"]
        )
    elif mode == "extend":
        subprocess.run(
            [
                "wlr-randr",
                "--output",
                "HDMI-A-1",
                "--mode",
                "1366x768",
                "--pos",
                "1920,0",
            ]
        )
    elif mode == "mirror":
        subprocess.run(["wlr-randr", "--output", "HDMI-A-1", "--same-as", "eDP-1"])


def toggle_mode():
    global current_mode_index
    current_mode_index = (current_mode_index + 1) % len(MODES)
    set_display_mode(MODES[current_mode_index])
    print(ICONS[MODES[current_mode_index]])


def main():
    if detect_hdmi():
        toggle_mode()
    else:
        print("HDMI not connected.")


if __name__ == "__main__":
    main()
