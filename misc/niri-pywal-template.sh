#!/bin/bash

# Define source and target paths
SOURCE_CONFIG_KDL="${HOME}/.config/niri/config.kdl"
TARGET_TEMPLATE_KDL="${HOME}/.config/wal/templates/niri-config.kdl"

echo "--- Niri Config Template Generator for Pywal ---"

# Check if the source config file exists
if [ ! -f "$SOURCE_CONFIG_KDL" ]; then
  echo "Error: Original Niri config.kdl not found at $SOURCE_CONFIG_KDL"
  echo "Please ensure your original config file is in place before running this script."
  exit 1
fi

# Create the target directory if it doesn't exist
mkdir -p "$(dirname "$TARGET_TEMPLATE_KDL")" || {
  echo "Error: Could not create directory for template."
  exit 1
}

echo "Reading from: $SOURCE_CONFIG_KDL"
echo "Writing (escaped template) to: $TARGET_TEMPLATE_KDL"
echo ""

# Use sed to escape all single curly braces.
# This replaces every '{' with '{{' and every '}' with '}}'.
# IMPORTANT: This will also double the braces for any Pywal variables you might have already
# inserted (e.g., {color0} would become {{color0}}).
# You will need to manually revert these specific Pywal variable braces back to single ones
# after the script runs.
sed -e 's/{/{{/g' -e 's/}/}}/g' "$SOURCE_CONFIG_KDL" >"$TARGET_TEMPLATE_KDL"

echo "Template created successfully at $TARGET_TEMPLATE_KDL"
echo ""
echo "################################################################################"
echo "### IMPORTANT MANUAL STEP REQUIRED:                                        ###"
echo "###                                                                        ###"
echo "### Now, open the generated template file:                                 ###"
echo "###   $TARGET_TEMPLATE_KDL                                              ###"
echo "###                                                                        ###"
echo "### And MANUALLY replace your desired Niri color values with Pywal         ###"
echo "### variables using *single* curly braces. For example:                  ###"
echo "###                                                                        ###"
echo "###   Change 'active-color #RRGGBB' to 'active-color {color1}'           ###"
echo "###   Make sure '{{color1}}' becomes '{color1}' (if accidentally doubled) ###"
echo "###                                                                        ###"
echo "### Do this for all Niri color options you want to theme dynamically.      ###"
echo "################################################################################"
