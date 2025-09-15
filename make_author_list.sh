#!/usr/bin/env bash
set -euo pipefail

# Usage: ./script.sh <authors_file> <affiliations_file> [delimiter]
# Defaults to ';'. Use "\t" for tab. If delimiter is ',' -> quoted CSV supported.

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <authors_file> <affiliations_file> [delimiter]" >&2
  exit 1
fi

AUTHORS_FILE="$1"
AFFILS_FILE="$2"
DELIM="${3:-;}"

# Normalize "\t" to real tab
if [[ "$DELIM" == '\t' ]]; then
  DELIM=$'\t'
fi
if [[ ${#DELIM} -gt 1 ]]; then
  echo "Warning: delimiter must be a single character. Using first character: '${DELIM:0:1}'" >&2
  DELIM="${DELIM:0:1}"
fi

awk -v AUTH="$AUTHORS_FILE" -v AFF="$AFFILS_FILE" -v DELIM="$DELIM" '
function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
function dequote(s,   t) {
  if (s ~ /^".*"$/) {
    t = substr(s, 2, length(s)-2)
    gsub(/""/, "\"", t)
    return t
  }
  return s
}

# fsplit: split line s into array out, honoring quotes if DELIM==","
function fsplit(s, out,   i,c,len,field,quoted,n,nextc) {
  delete out
  if (DELIM != ",") {
    n = split(s, out, (DELIM == "|") ? "\\|" : DELIM)
    for (i=1; i<=n; i++) out[i] = trim(out[i])
    return n
  }

  # Simple CSV parser for comma delimiter
  len = length(s); field=""; quoted=0; n=0
  for (i=1; i<=len; i++) {
    c = substr(s,i,1)
    if (quoted) {
      if (c=="\"") {
        nextc = (i<len) ? substr(s,i+1,1) : ""
        if (nextc=="\"") { field=field "\""; i++ }
        else { quoted=0 }
      } else {
        field=field c
      }
    } else {
      if (c=="\"") {
        quoted=1
      } else if (c==",") {
        n++; out[n]=trim(field); field=""
      } else {
        field=field c
      }
    }
  }
  n++; out[n]=trim(field)
  for (i=1; i<=n; i++) out[i]=dequote(out[i])
  return n
}

BEGIN {
  total_authors = 0
  next_num = 0

  # --- Load affiliations ---
  while ((getline line < AFF) > 0) {
    if (line ~ /^[[:space:]]*$/) continue
    n = fsplit(line, parts)
    if (n < 2) continue
    text = parts[1]
    key  = parts[2]
    if (key != "") key2text[key] = text
  }
  close(AFF)
}

{
  if ($0 ~ /^[[:space:]]*$/) next
  nf = fsplit($0, f)
  name = f[1]
  if (name=="") next

  delete nums; num_count=0; delete seen_key
  for (i=2; i<=nf; i++) {
    key = f[i]
    if (key=="" || key in seen_key) continue
    seen_key[key]=1

    if (!(key in key2num)) {
      next_num++; key2num[key]=next_num
      if (key in key2text) num2text[next_num]=key2text[key]
      else {
        num2text[next_num] = "[MISSING AFFILIATION FOR KEY: " key "]"
        printf("Warning: no affiliation text for key \"%s\".\n", key) > "/dev/stderr"
      }
    }
    num_count++; nums[num_count]=key2num[key]
  }

  token = name
  if (num_count>0) {
    token = token nums[1]
    for (j=2; j<=num_count; j++) token = token "," nums[j]
  }
  total_authors++; authors[total_authors]=token
}

END {
  if (total_authors==1) print authors[1]
  else if (total_authors==2) print authors[1] " & " authors[2]
  else if (total_authors>2) {
    for (i=1;i<=total_authors;i++) {
      if (i==total_authors) printf(" & %s", authors[i])
      else if (i==1) printf("%s", authors[i])
      else printf(", %s", authors[i])
    }
    printf("\n")
  }

  print ""
  for (k=1;k<=next_num;k++) if (k in num2text) printf("%d) %s\n", k, num2text[k])
}
' "$AUTHORS_FILE"
