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
    # Для файлов в пределах max_depth - сохраняем структуру как есть
    find "$input_dir" -mindepth 1 -maxdepth "$max_depth" -type f | while IFS= read -r file; do
        rel_path="${file#$input_dir/}"
        target_dir="$output_dir/$(dirname "$rel_path")"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/$(basename "$file")"
    done

    # Для файлов глубже max_depth - копируем только последние max_depth уровней директорий
    find "$input_dir" -mindepth "$((max_depth + 1))" -type f | while IFS= read -r file; do
        rel_path="${file#$input_dir/}"
        IFS='/' read -ra path_parts <<< "$rel_path"
        
        # Вычисляем, сколько компонентов пути нужно пропустить
        skip_count=$((${#path_parts[@]} - max_depth - 1))
        if [ $skip_count -lt 0 ]; then
            skip_count=0
        fi
        
        # Собираем новый путь из последних max_depth компонентов
        new_path=""
        for ((i=skip_count; i<${#path_parts[@]}; i++)); do
            if [ -z "$new_path" ]; then
                new_path="${path_parts[i]}"
            else
                new_path="$new_path/${path_parts[i]}"
            fi
        done
        
        target_dir="$output_dir/$(dirname "$new_path")"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/$(basename "$file")"
    done
else
    # Если max_depth не указан, копируем все файлы в корень output_dir с обработкой конфликтов имен
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
