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

if [ -n "$max_depth" ]; then
    find "$input_dir" -mindepth 1 -maxdepth "$max_depth" -type f | while read -r file; do
        rel_path="${file#$input_dir/}"
        dir_path=$(dirname "$rel_path")
        mkdir -p "$output_dir/$dir_path"
        cp "$file" "$output_dir/$dir_path/"
    done

    find "$input_dir" -mindepth "$((max_depth + 1))" -type f | while read -r file; do
        rel_path="${file#$input_dir/}"
        dir_parts=($(echo "$rel_path" | tr '/' ' '))
        target_dir=""
        
        for ((i=0; i<max_depth && i<${#dir_parts[@]}-1; i++)); do
            if [ -z "$target_dir" ]; then
                target_dir="${dir_parts[i]}"
            else
                target_dir="$target_dir/${dir_parts[i]}"
            fi
        done
        
        if [ -n "$target_dir" ]; then
            mkdir -p "$output_dir/$target_dir"
            cp "$file" "$output_dir/$target_dir/"
        fi
    done
else
    find "$input_dir" -type f | while read -r file; do
        filename=$(basename "$file")
        counter=1
        new_filename="$filename"
        
        while [ -e "$output_dir/$new_filename" ]; do
            name="${filename%.*}"
            ext="${filename##*.}"
            new_filename="${name}${counter}.${ext}"
            ((counter++))
        done
        
        cp "$file" "$output_dir/$new_filename"
    done
fi 