#!/bin/bash

# Location of your todo file
TODO_FILE="$HOME/.local/share/rofi_todo.txt"

# Nerd Font icons
ICON_ADD=""    # Add new task
ICON_DONE=""   # Mark as done
ICON_DELETE="" # Delete
ICON_CHECK=""  # Done task indicator

# Ensure file exists
mkdir -p "$(dirname "$TODO_FILE")"
touch "$TODO_FILE"

# Build Rofi list (icons added dynamically)
build_list() {
  echo "$ICON_ADD  Add new task"
  while IFS= read -r line; do
    if [[ "$line" == "{x} "* ]]; then
      echo "$ICON_CHECK ${line:4}"
    else
      echo "   $line"
    fi
  done <"$TODO_FILE"
}

CHOICE=$(build_list | rofi -dmenu -p "To-Do List" \
  -theme-str 'entry { placeholder: "Type to select or add task"; }')

# Add new task
if [[ "$CHOICE" == "$ICON_ADD  Add new task" ]]; then
  NEW_TASK=$(rofi -dmenu -p "New Task" \
    -theme-str 'entry { placeholder: "Write your task here"; }')
  if [[ -n "$NEW_TASK" ]]; then
    echo "$NEW_TASK" >>"$TODO_FILE"
  fi

# Handle existing task
elif [[ -n "$CHOICE" ]]; then
  # Strip icons/spaces
  TASK=$(echo "$CHOICE" | sed "s/^$ICON_CHECK //; s/^   //")

  ACTION=$(echo -e "$ICON_DONE  Mark as Done\n$ICON_DELETE  Delete" |
    rofi -dmenu -p "Task Action" \
      -theme-str 'entry { placeholder: "Choose action"; }')

  case "$ACTION" in
  "$ICON_DONE  Mark as Done")
    sed -i "s/^$TASK\$/{x} $TASK/" "$TODO_FILE"
    ;;
  "$ICON_DELETE  Delete")
    grep -vFx "$TASK" "$TODO_FILE" | grep -vFx "{x} $TASK" >"$TODO_FILE.tmp" &&
      mv "$TODO_FILE.tmp" "$TODO_FILE"
    ;;
  esac
fi
