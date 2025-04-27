#!/bin/bash

chmod +x "$0"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <input_dir> <output_dir> [--max_depth N]"
    exit 1
fi

input_dir="$1"
output_dir="$2"
max_depth=""

if [ "$3" = "--max_depth" ] && [ -n "$4" ]; then
    max_depth="$4"
fi

if [ ! -d "$input_dir" ]; then
    echo "Input directory does not exist"
    exit 1
fi

mkdir -p "$output_dir"

process_file() {
    local file="$1"
    local rel_path="${file#$input_dir/}"
    local depth=$(echo "$rel_path" | tr -cd '/' | wc -c)
    local filename=$(basename "$file")
    
    if [ -z "$max_depth" ]; then
        local counter=1
        local new_filename="$filename"
        while [ -e "$output_dir/$new_filename" ]; do
            local name="${filename%.*}"
            local ext="${filename##*.}"
            new_filename="${name}${counter}.${ext}"
            ((counter++))
        done
        cp "$file" "$output_dir/$new_filename"
    else
        if [ "$depth" -lt "$max_depth" ]; then
            local target_dir="$output_dir/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp "$file" "$target_dir/$filename"
        else
            local target_dir="$output_dir"
            local count=0
            while IFS='/' read -r part; do
                if [ "$count" -lt "$max_depth" ] && [ -n "$part" ]; then
                    target_dir="$target_dir/$part"
                    ((count++))
                fi
            done <<< "$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp "$file" "$target_dir/$filename"
        fi
    fi
}

export -f process_file
export input_dir output_dir max_depth
find "$input_dir" -type f -exec bash -c 'process_file "$0"' {} \;
