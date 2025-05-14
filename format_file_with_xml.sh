#!/bin/bash

# Script to format a given file's content and metadata into an XML-like structure
# and copy it to the clipboard. (macOS only)

FILE_PATH="$1"

# --- Input Validation ---
if [ -z "$FILE_PATH" ]; then
    echo "Error: No file path provided." >&2
    osascript -e 'display notification "Error: No file path provided." with title "Zed Script Error"'
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found at '$FILE_PATH'" >&2
    osascript -e 'display notification "Error: File not found: '"$(basename "$FILE_PATH")"'" with title "Zed Script Error"'
    exit 1
fi

# --- Metadata Extraction ---
FILENAME=$(basename "$FILE_PATH")

# Refined FILETYPE extraction
# Handles cases like: "script.sh" -> "sh", "Makefile" -> "", ".bashrc" -> "bashrc", "archive.tar.gz" -> "gz"
if [[ "$FILENAME" == .* ]]; then # Hidden file like .bashrc or .config.file
    temp_name_no_leading_dot="${FILENAME#.}"
    if [[ "$temp_name_no_leading_dot" == *.* ]]; then # like .config.file (e.g., .config.fish -> fish)
        FILETYPE="${temp_name_no_leading_dot##*.}"
    else # like .bashrc (no further dots, e.g., .bashrc -> bashrc)
        FILETYPE="$temp_name_no_leading_dot"
    fi
else # Not a hidden file
    if [[ "$FILENAME" == *.* ]]; then # Contains a dot, e.g., file.txt -> txt
        FILETYPE="${FILENAME##*.}"
    else # No dot, e.g., Makefile -> ""
        FILETYPE=""
    fi
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S") # Current timestamp for when formatting occurs
LINE_COUNT=$(awk 'END{print NR}' "$FILE_PATH") # Get precise line count without whitespace issues

# --- Temporary File Setup ---
# Use process ID for a more unique temp file name and ensure cleanup
TMP_OUTPUT_FILE="/tmp/formatted_file_${$}.xml"
# Ensure temp file is deleted on script exit (normal, error, or interrupt)
trap 'rm -f "$TMP_OUTPUT_FILE"' EXIT SIGHUP SIGINT SIGQUIT SIGTERM

# --- Generate XML Output ---
# Create metadata section
cat > "$TMP_OUTPUT_FILE" << EOF
<file_metadata>
  <filepath>$FILE_PATH</filepath>
  <filename>$FILENAME</filename>
  <filetype>$FILETYPE</filetype>
  <timestamp>$TIMESTAMP</timestamp>
  <line_count>$LINE_COUNT</line_count>
</file_metadata>

<file_content>
EOF

# Add file content with line numbers and XML escaping
nl -ba "$FILE_PATH" | \
  sed -e 's/\&/\&amp;/g' \
      -e 's/</\&lt;/g' \
      -e 's/>/\&gt;/g' \
      -e 's/"/\&quot;/g' \
      -e "s/'/\&apos;/g" | \
  sed 's/^[[:space:]]*\([0-9]*\)[[:space:]]*\(.*\)$/\1: \2/' >> "$TMP_OUTPUT_FILE"

echo "</file_content>" >> "$TMP_OUTPUT_FILE"

# --- Copy to Clipboard and Notify (macOS) ---
if command -v pbcopy &> /dev/null; then
    cat "$TMP_OUTPUT_FILE" | pbcopy
    osascript -e 'display notification "File copied with XML formatting ('"$(basename "$FILE_PATH")"') " with title "Zed"'
else
    # This case is highly unlikely on macOS as pbcopy is a standard utility
    echo "Error: pbcopy command not found on macOS. Cannot copy to clipboard." >&2
    echo "Formatted content is in: $TMP_OUTPUT_FILE" >&2
    osascript -e 'display notification "Error: pbcopy not found!" with title "Zed Script Error"'
fi

# Temporary file is cleaned up by the trap
