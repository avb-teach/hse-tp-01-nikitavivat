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

copy_with_max_depth() {
    local file="$1"
    local rel_path="${file#$input_dir/}"
    local dir_path=$(dirname "$rel_path")
    local filename=$(basename "$file")
    
    # Разбиваем путь на части
    IFS='/' read -ra path_parts <<< "$dir_path"
    local parts_count=${#path_parts[@]}
    
    # Если путь короче или равен max_depth, копируем как есть
    if [ $parts_count -le $max_depth ]; then
        local target_dir="$output_dir/$dir_path"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/$filename"
        return
    fi
    
    # Для путей длиннее max_depth, копируем во все возможные места
    # Сначала копируем оригинальный путь до max_depth
    local orig_target=""
    for ((i=0; i<max_depth; i++)); do
        if [ -z "$orig_target" ]; then
            orig_target="${path_parts[i]}"
        else
            orig_target="$orig_target/${path_parts[i]}"
        fi
    done
    mkdir -p "$output_dir/$orig_target"
    cp "$file" "$output_dir/$orig_target/$filename"
    
    # Теперь копируем в каждую возможную комбинацию директорий глубиной max_depth
    for ((start=1; start<=parts_count-max_depth; start++)); do
        local target=""
        for ((i=start; i<start+max_depth && i<parts_count; i++)); do
            if [ -z "$target" ]; then
                target="${path_parts[i]}"
            else
                target="$target/${path_parts[i]}"
            fi
        done
        if [ -n "$target" ]; then
            mkdir -p "$output_dir/$target"
            cp "$file" "$output_dir/$target/$filename"
        fi
    done
}

if [ -n "$max_depth" ]; then
    # Обработка с max_depth
    find "$input_dir" -type f | while IFS= read -r file; do
        copy_with_max_depth "$file"
    done
else
    # Если max_depth не указан, копируем все файлы в корень с обработкой конфликтов
    find "$input_dir" -type f | while IFS= read -r file; do
        filename=$(basename "$file")
        counter=1
        new_filename="$filename"
        
        while [ -e "$output_dir/$new_filename" ]; do
            name="${filename%.*}"
            ext="${filename##*.}"
            if [ "$name" = "$filename" ]; then
                new_filename="${filename}${counter}"
            else
                new_filename="${name}${counter}.${ext}"
            fi
            ((counter++))
        done
        
        cp "$file" "$output_dir/$new_filename"
    done
fi
