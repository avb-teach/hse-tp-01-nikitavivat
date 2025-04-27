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

get_depth() {
    local path="$1"
    echo "$path" | awk -F/ '{print NF-1}'
}

process_file() {
    local file="$1"
    local rel_path="${file#$input_dir/}"
    local depth=$(get_depth "$rel_path")
    local filename=$(basename "$file")
    
    if [ -z "$max_depth" ]; then
        local counter=1
        local new_filename="$filename"
        while [ -e "$output_dir/$new_filename" ]; do
            local name="${filename%.*}"
            local ext="${filename##*.}"
            if [ "$name" = "$filename" ]; then
                new_filename="${filename}${counter}"
            else
                new_filename="${name}${counter}.${ext}"
            fi
            ((counter++))
        done
        cp "$file" "$output_dir/$new_filename"
    else
        if [ "$depth" -le "$max_depth" ]; then
            local target_dir="$output_dir/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp "$file" "$target_dir/$filename"
        else
            local parts=()
            IFS='/' read -ra path_array <<< "$rel_path"
            local start_idx=$((depth - max_depth))
            
            local target_dir="$output_dir"
            for ((i=start_idx; i<${#path_array[@]}-1; i++)); do
                target_dir="$target_dir/${path_array[i]}"
            done
            
            mkdir -p "$target_dir"
            cp "$file" "$target_dir/$filename"
        fi
    fi
}

export -f process_file get_depth
export input_dir output_dir max_depth
find "$input_dir" -type f -exec bash -c 'process_file "$0"' {} \;
