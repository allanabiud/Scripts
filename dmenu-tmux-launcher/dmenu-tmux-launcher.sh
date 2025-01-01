#!/bin/bash

# Directory to store temporary desktop entries
export XDG_DATA_HOME="$HOME/.local/share"
DESKTOP_DIR="$HOME/.local/share/applications/tmux-sessions"
mkdir -p "$DESKTOP_DIR"

# Clear old entries
rm -f "$DESKTOP_DIR"/*.desktop

# Add a new session option
cat <<EOF >"$DESKTOP_DIR/tmux-new-session.desktop"
[Desktop Entry]
Name=New Tmux Session
Exec=ghostty --class=org.example.tmux --x11-instance-name=tmux -e "tmux new-session"
Type=Application
Categories=Tmux;
EOF

# Add running tmux sessions
tmux list-sessions -F "#S" 2>/dev/null | while read -r session; do
  cat <<EOF >"$DESKTOP_DIR/tmux-$session.desktop"
[Desktop Entry]
Name=Attach to $session (Running Tmux Session)
Exec=ghostty --class=org.example.tmux --x11-instance-name=tmux -e tmux attach-session -t $session
Type=Application
Categories=Tmux;
EOF
done

# Add tmuxifier layouts
for session in $(tmuxifier list-sessions 2>/dev/null); do
  cat <<EOF >"$DESKTOP_DIR/tmuxifier-$session.desktop"
[Desktop Entry]
Name=Tmuxifier $session
Exec=ghostty --class=org.example.tmuxifier --x11-instance-name=tmuxifier -e bash -c "tmuxifier load-layout $session"
Type=Application
Categories=Tmux;
EOF
done

# Kill tmux sessions
tmux list-sessions -F "#S" 2>/dev/null | while read -r session; do
  cat <<EOF >"$DESKTOP_DIR/tmux-kill-$session.desktop"
[Desktop Entry]
Name=Kill $session (Running Tmux Session)
Exec=ghostty --class=org.example.tmux --x11-instance-name=tmux -e tmux kill-session -t $session
Terminal=true
Type=Application
Categories=Tmux;
EOF
done

# Kill tmux server
cat <<EOF >"$DESKTOP_DIR/tmux-kill-server.desktop"
[Desktop Entry]
Name=Kill Tmux Server
Exec=ghostty --class=org.example.tmux --x11-instance-name=tmux -e tmux kill-server
Terminal=true
Type=Application
Categories=Tmux;
EOF

# Refresh the desktop database
update-desktop-database "$DESKTOP_DIR"

# Launch j4-dmenu-desktop
j4-dmenu-desktop --dmenu="dmenu -i -l 10 -p 'Tmux' -nf '#BBBBBB' -nb '#222222' -sb '#8a1919' -sf '#EEEEEE' -fn 'MesloLGS Nerd Font Regular-10'" --use-xdg-de --no-generic --display-binary
