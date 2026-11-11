#!/usr/bin/env bash
# Compile README.md from src/skills.yaml.
#
# The README is generated, so every section it renders has a key in the source:
# a header edited by hand is gone the next time `task compile` runs. Badge
# labels and logos are URL-encoded, because a raw `C++` or `Node.js` is a
# different path to shields than the name it renders.
set -euo pipefail

SOURCE=src/skills.yaml
README=README.md

# shields draws a `for-the-badge` message in #fff whatever the background is
# (measured 2026-11-11: Nim-FFE953 comes back with fill="#fff" on #ffe953, a
# 1.23:1 contrast), so a pale brand colour is unreadable rather than merely
# light. Keep the hue and darken it in fixed steps until white clears WCAG AA
# (4.5:1); a colour that already passes is emitted unchanged.
readable_bg() {
  awk -v hex="$1" '
    function hv(c) { return index("0123456789ABCDEF", toupper(c)) - 1 }
    BEGIN {
      r = hv(substr(hex,1,1))*16 + hv(substr(hex,2,1))
      g = hv(substr(hex,3,1))*16 + hv(substr(hex,4,1))
      b = hv(substr(hex,5,1))*16 + hv(substr(hex,6,1))
      n = split("1 0.94 0.88 0.82 0.76 0.70 0.64 0.58 0.52 0.46 0.40 0.34 0.28 0.22 0.16", step, " ")
      for (i = 1; i <= n; i++) {
        f = step[i]
        R = r*f/255; G = g*f/255; B = b*f/255
        R = (R <= 0.03928) ? R/12.92 : ((R+0.055)/1.055)^2.4
        G = (G <= 0.03928) ? G/12.92 : ((G+0.055)/1.055)^2.4
        B = (B <= 0.03928) ? B/12.92 : ((B+0.055)/1.055)^2.4
        if (1.05/(0.2126*R + 0.7152*G + 0.0722*B + 0.05) >= 4.5) {
          printf "%02X%02X%02X", int(r*f+0.5), int(g*f+0.5), int(b*f+0.5)
          exit
        }
      }
      printf "%s", hex
    }'
}

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
        bg=$(readable_bg "$color")
        printf '![%s](https://img.shields.io/badge/%s-%s?style=for-the-badge&logo=%s&logoColor=white)\n' \
          "$skill" "$enc" "$bg" "$logo"
      done
  done
} >"$README"
