#!/bin/bash

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <input_dir> <output_dir> [--max_depth N]"
    exit 1
fi

input_dir="$1"
output_dir="$2"
max_depth=0

for ((i=3; i<=$#; i++)); do
    if [ "${!i}" = "--max_depth" ]; then
        ((i++))
        max_depth="${!i}"
        if ! [[ "$max_depth" =~ ^[0-9]+$ ]]; then
            echo "Error: max_depth must be a non-negative integer"
            exit 1
        fi
    fi
done

if [ ! -d "$input_dir" ]; then
    echo "Error: Input directory does not exist"
    exit 1
fi

mkdir -p "$output_dir"

copy_with_rename() {
    local src="$1"
    local target_dir="$2"
    local filename=$(basename "$src")
    
    if [ -e "$target_dir/$filename" ]; then
        local base="${filename%.*}"
        local ext="${filename##*.}"
        [ "$base.$ext" = "$filename" ] && ext="" || ext=".$ext"
        local counter=1
        while [ -e "$target_dir/$base$counter$ext" ]; do
            ((counter++))
        done
        cp "$src" "$target_dir/$base$counter$ext"
    else
        cp "$src" "$target_dir/$filename"
    fi
}

get_depth() {
    local path="$1"
    local depth=0
    local tmp="$path"
    
    while [[ "$tmp" == */* ]]; do
        ((depth++))
        tmp="${tmp#*/}"
    done
    
    echo "$depth"
}

process_dir() {
    local dir="$1"
    local rel_path="${dir#$input_dir/}"
    [ -z "$rel_path" ] && return
    
    local depth=$(get_depth "$rel_path")
    if [ "$depth" -ge "$max_depth" ]; then
        # Получаем имя директории
        local parts
        IFS='/' read -ra parts <<< "$rel_path"
        local dir_name="${parts[$depth-1]}"
        
        # Создаем директорию в корне
        local target_dir="$output_dir/$dir_name"
        mkdir -p "$target_dir"
        
        # Копируем все файлы из этой директории и её поддиректорий
        find "$dir" -type d | while read -r subdir; do
            local subdir_rel="${subdir#$dir/}"
            [ -z "$subdir_rel" ] && continue
            mkdir -p "$target_dir/$subdir_rel"
        done
        
        find "$dir" -type f | while read -r file; do
            local file_rel="${file#$dir/}"
            local file_dir="$(dirname "$file_rel")"
            [ "$file_dir" = "." ] && file_dir=""
            local target_subdir="$target_dir${file_dir:+/$file_dir}"
            mkdir -p "$target_subdir"
            copy_with_rename "$file" "$target_subdir"
        done
    fi
}

# Копируем файлы на глубине <= max_depth
find "$input_dir" -type f | while read -r file; do
    rel_path="${file#$input_dir/}"
    depth=$(get_depth "$rel_path")
    
    if [ "$depth" -le "$max_depth" ]; then
        target_dir="$output_dir/$(dirname "$rel_path")"
        mkdir -p "$target_dir"
        copy_with_rename "$file" "$target_dir"
    fi
done

# Копируем каждую папку на глубине >= max_depth в корень
find "$input_dir" -type d | while read -r dir; do
    process_dir "$dir"
done