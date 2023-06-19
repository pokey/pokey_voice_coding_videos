#!/usr/bin/env bash

# Set the size limit
limit=500000000

# Find all .dvc files in the data directory and its subdirectories
while IFS= read -r -d '' file; do
  # Extract size, md5, and path values from the .dvc file
  size=$(yq e '.outs[0].size' "$file")
  md5=$(yq e '.outs[0].md5' "$file")
  path=$(yq e '.outs[0].path' "$file")

  # If size exceeds the limit
  if (( size > limit )); then
    # If the file is a directory
    if [[ $md5 == *.dir ]]; then
      cache_dir=".dvc/cache/${md5:0:2}/${md5:2}"
      # Parse the cache file
      while IFS= read -r row; do
        _jq() {
          echo ${row} | base64 --decode | jq -r ${1}
        }

        # Extract md5 and relpath for each file in the directory
        file_md5=$(_jq '.md5')
        relpath=$(_jq '.relpath')

        # Generate the deletion commands
        echo "rm '$(dirname "$file")/${path}/${relpath}'"
        echo "rm .dvc/cache/${file_md5:0:2}/${file_md5:2}"
      done < <(cat "$cache_dir" | jq -r '.[] | @base64')
      echo "rmdir '$(dirname "$file")/${path}'"
    else
      # If the file is not a directory
      data_path=$(dirname "$file")/"$path"
      cache_path=".dvc/cache/${md5:0:2}/${md5:2}"
      # Generate the deletion commands
      echo "rm \"$data_path\""
      echo "rm $cache_path"
    fi
  fi
done < <(find data -name "*.dvc" -print0)
