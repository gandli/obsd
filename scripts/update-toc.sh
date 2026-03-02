#!/bin/bash
set -e

# Update README table of contents using shell commands only
# No external dependencies required

README_FILE="README.md"
TEMP_README="README.md.tmp"

# Backup original README
cp "$README_FILE" "$TEMP_README"

# Find all markdown files in Resources directory
find Resources -name "*.md" -type f | sort > /tmp/resource_files.txt

# Count total files
TOTAL_FILES=$(wc -l < /tmp/resource_files.txt)

# Create new table header
cat > /tmp/new_table.txt << 'TABLE_HEADER'
| # | 📌 Title | 📄 Document | 💡 Summary | 🏷️ Type | 📂 Path | 📅 Updated |
|---|---------|-------------|------------|--------|---------|-----------|
TABLE_HEADER

# Process each file and add to table
counter=1
while IFS= read -r filepath; do
    if [ -n "$filepath" ]; then
        # Extract filename without path
        filename=$(basename "$filepath")
        
        # Extract date from filename (format: YYYY-MM-DD)
        if [[ $filename =~ _([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$ ]]; then
            file_date="${BASH_REMATCH[1]}"
        else
            file_date="2026-03-02"
        fi
        
        # Determine type based on directory
        if [[ $filepath == *"/GitHub/"* ]]; then
            file_type="GitHub Repository"
            dir_path="Resources/GitHub/"
        elif [[ $filepath == *"/X/"* ]]; then
            file_type="X Platform"
            dir_path="Resources/X/"
        else
            file_type="Reference"
            dir_path="Resources/"
        fi
        
        # Extract title from file content (first H2 heading)
        if [ -f "$filepath" ]; then
            title_line=$(grep -m 1 "^## " "$filepath" 2>/dev/null || echo "## $filename")
            title_clean=$(echo "$title_line" | sed 's/^## //')
            if [ -z "$title_clean" ] || [ "$title_clean" = "$filename" ]; then
                title_clean="$filename"
            fi
        else
            title_clean="$filename"
        fi
        
        # Create URL-encoded path for link
        url_path=$(echo "$filepath" | sed 's/ /%20/g')
        
        # Add row to table
        printf "| %d | %s | [%s](%s) | Content analysis available | %s | \`%s\` | %s |\n" \
            "$counter" "$title_clean" "$filename" "$url_path" "$file_type" "$dir_path" "$file_date" >> /tmp/new_table.txt
        
        counter=$((counter + 1))
    fi
done < /tmp/resource_files.txt

# Update README with new table
TOC_START="<!-- TOC:START -->"
TOC_END="<!-- TOC:END -->"

# Extract content before TOC
sed -n "1,/$TOC_START/p" "$TEMP_README" > "$README_FILE"

# Add new table
cat /tmp/new_table.txt >> "$README_FILE"

# Add total count comment
echo "<!-- Total: $TOTAL_FILES documents -->" >> "$README_FILE"

# Add TOC end marker
echo "$TOC_END" >> "$README_FILE"

# Extract content after TOC
sed -n "0,/$TOC_END/d; p" "$TEMP_README" >> "$README_FILE"

# Cleanup
rm -f "$TEMP_README" /tmp/resource_files.txt /tmp/new_table.txt

echo "README table updated with $TOTAL_FILES documents"
