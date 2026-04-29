#!/usr/bin/env bash

# Compile README.md from src/skills.yaml using yq

SOURCE="src/skills.yaml"
README="README.md"

# Get username
USER=$(yq '.name' "$SOURCE")

# Start with header image
echo '<p>&nbsp;<img align="center" src="https://readmestats.999857.xyz/api?username='"$USER"'&show_icons=true&locale=en&theme=tokyonight" alt="'"$USER"' stats" /></p>' > "$README"

# Add main title
yq '.title[0].title' "$SOURCE" >> "$README"

# Add subtitle
yq '.subtitle[0].title' "$SOURCE" >> "$README"

# Process each category
for category in frontend backend database hosting devops others ide; do
    # Get category title
    title=$(yq ".$category[0].title" "$SOURCE")
    echo "$title" >> "$README"
    
    # Get list items and their keys using yq
    yq ".$category[1].list" "$SOURCE" -o json -I=0 | jq -r '.[] | to_entries[] | "\(.key)=\(.value)"' | while IFS='=' read -r skill color; do
        # Create badge markdown
        echo "![${skill}](https://img.shields.io/badge/${skill}-${color}?style=for-the-badge&logo=${skill}&logoColor=white)" >> "$README"
    done
done
