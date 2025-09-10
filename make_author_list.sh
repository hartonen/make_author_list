#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <authors_file> <affiliations_file>" >&2
  exit 1
fi

AUTHORS_FILE="$1"
AFFILS_FILE="$2"

awk -v AUTH="$AUTHORS_FILE" -v AFF="$AFFILS_FILE" '
function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }

BEGIN {
  # --- Load affiliations: map key -> full text ---
  while ((getline line < AFF) > 0) {
    if (line ~ /^[[:space:]]*$/) continue
    n = split(line, parts, /;/)
    if (n < 2) {
      # Skip malformed line quietly
      continue
    }
    # Expect exactly 2 columns: text ; key
    text = trim(parts[1])
    key  = trim(parts[2])
    if (key != "") {
      key2text[key] = text
    }
  }
  close(AFF)

  # Counters
  total_authors = 0
  next_num = 0
}

# --- Process authors file line-by-line ---
{
  line = $0
  if (line ~ /^[[:space:]]*$/) next

  nf = split(line, f, /;/)
  name = trim(f[1])
  if (name == "") next

  # Collect this author’s affiliation numbers (in row order)
  delete nums
  num_count = 0

  # Track duplicates per author row just in case
  delete seen_key

  for (i = 2; i <= nf; i++) {
    key = trim(f[i])
    if (key == "" || key in seen_key) continue
    seen_key[key] = 1

    # Assign number if first time seen globally
    if (!(key in key2num)) {
      next_num++
      key2num[key] = next_num

      # Remember text by number for output order
      if (key in key2text) {
        num2text[next_num] = key2text[key]
      } else {
        # Missing mapping – keep placeholder and warn to stderr
        num2text[next_num] = "[MISSING AFFILIATION FOR KEY: " key "]"
        printf("Warning: no affiliation text found for key \"%s\".\n", key) > "/dev/stderr"
      }
    }

    # Record the number for this author in the order encountered
    num_count++
    nums[num_count] = key2num[key]
  }

  # Build author token: Name + numbers (comma-separated, no spaces)
  token = name
  if (num_count > 0) {
    token = token
    token = token nums[1]
    for (j = 2; j <= num_count; j++) token = token "," nums[j]
  }

  total_authors++
  authors[total_authors] = token
}

END {
  # --- Print authors line with commas and & before the last author ---
  if (total_authors == 1) {
    print authors[1]
  } else if (total_authors == 2) {
    print authors[1] " & " authors[2]
  } else if (total_authors > 2) {
    for (i = 1; i <= total_authors; i++) {
      if (i == total_authors) {
        # Last: preceded by &
        printf(" & %s", authors[i])
      } else if (i == 1) {
        # First: print without leading comma
        printf("%s", authors[i])
      } else {
        # Middle authors: comma+space
        printf(", %s", authors[i])
      }
    }
    printf("\n")
  } else {
    # No authors found
    exit
  }

  # Blank line
  print ""

  # --- Print numbered affiliation list in encounter order ---
  for (k = 1; k <= next_num; k++) {
    if (k in num2text)
      printf("%d) %s\n", k, num2text[k])
  }
}
' "$AUTHORS_FILE"
