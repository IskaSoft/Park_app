#!/bin/bash

OUTPUT="park_app_dump__20.04.2026.txt"

# Çykmagyna öňki faýly poz
rm -f "$OUTPUT"

# ähli dart faýllary tap
find lib -name "*.dart" | while read FILE; do
  echo "$FILE" >> "$OUTPUT"
  echo "" >> "$OUTPUT"
  cat "$FILE" >> "$OUTPUT"
  echo -e "\n------------------------------------\n" >> "$OUTPUT"
done
