#!/usr/bin/env bash
# Compile README.md from src/skills.yaml.
#
# The README is generated, so every section it renders has a key here: a header
# edited by hand is gone the next time `task compile` runs. Badge labels and
# logos are URL-encoded, because a raw `C++` or `Node.js` is a different path to
# shields than the name it renders.
set -euo pipefail

SOURCE=src/skills.yaml
README=README.md

USER=$(yq -r '.name' "$SOURCE")
banner=$(yq -r '.banner' "$SOURCE")
stats=$(yq -r '.stats' "$SOURCE")
intro=$(yq -r '.intro' "$SOURCE")

{
  printf '# %s\n\n' "$USER"
  printf '[![%s](%s)](https://github.com/%s)\n\n' "$USER" "$banner" "$USER"
  printf '%s\n\n' "$intro"
  printf '<p><img align="center" src="%s" alt="%s on GitHub" /></p>\n\n' "$stats" "$USER"

  yq -r '.title' "$SOURCE"
  printf '\n| Repo | What it is |\n| :--- | :--- |\n'
  yq -r '.projects[] | "| [`\(.repo)`](\(.url)) | \(.what) |"' "$SOURCE"

  printf '\n'
  yq -r '.subtitle' "$SOURCE"
  printf '\n'
  yq -r '.elsewhere[] | "- [\(.label)](\(.url))"' "$SOURCE"

  for category in frontend backend database hosting devops others ide; do
    printf '\n'
    yq -r ".$category[0].title" "$SOURCE"
    printf '\n'
    yq -r ".$category[1].list" -o json -I=0 "$SOURCE" |
      jq -r '.[] | to_entries[] | [.key, (if (.value|type)=="object" then .value.c else .value end), (if (.value|type)=="object" then .value.logo else .key end)] | @tsv' |
      while IFS=$'\t' read -r skill color logo; do
        enc=$(printf '%s' "$skill" | jq -sRr @uri)
        printf '![%s](https://img.shields.io/badge/%s-%s?style=for-the-badge&logo=%s&logoColor=white)\n' \
          "$skill" "$enc" "$color" "$logo"
      done
  done
} >"$README"
