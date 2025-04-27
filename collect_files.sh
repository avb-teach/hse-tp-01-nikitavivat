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

copy_file() {
    local src="$1"
    local dest="$2"
    local filename=$(basename "$src")
    local counter=1
    local new_dest="$dest"

    while [ -e "$new_dest" ]; do
        local name="${filename%.*}"
        local ext="${filename##*.}"
        if [ "$name" = "$filename" ]; then
            new_dest="${dest%/*}/${filename}${counter}"
        else
            new_dest="${dest%/*}/${name}${counter}.${ext}"
        fi
        ((counter++))
    done
    cp "$src" "$new_dest"
}

if [ -n "$max_depth" ]; then
    while IFS= read -r -d '' file; do
        rel_path="${file#$input_dir/}"
        depth=$(echo "$rel_path" | tr -cd '/' | wc -c)
        
        if [ "$depth" -lt "$max_depth" ]; then
            dir_path=$(dirname "$rel_path")
            target_dir="$output_dir/$dir_path"
            mkdir -p "$target_dir"
            copy_file "$file" "$target_dir/$(basename "$file")"
        else
            parts=()
            while IFS='/' read -ra array; do
                for part in "${array[@]}"; do
                    if [ -n "$part" ]; then
                        parts+=("$part")
                    fi
                done
            done <<< "$rel_path"
            
            target_dir="$output_dir"
            for ((i=0; i<max_depth && i<${#parts[@]}-1; i++)); do
                target_dir="$target_dir/${parts[i]}"
            done
            mkdir -p "$target_dir"
            copy_file "$file" "$target_dir/$(basename "$file")"
        fi
    done < <(find "$input_dir" -type f -print0)
else
    while IFS= read -r -d '' file; do
        copy_file "$file" "$output_dir/$(basename "$file")"
    done < <(find "$input_dir" -type f -print0)
fi
