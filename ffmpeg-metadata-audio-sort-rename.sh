%%bash
#!/bin/bash
# ============================================================
# 🧩 FFmpeg Metadata + Audio Sorting + Auto Rename Script
# ------------------------------------------------------------
# Detects Season/Episode + Quality, sorts audio by language
# priority, renames files, and embeds metadata.
# ============================================================

# ─── USER CONFIGURATION ─────────────────────────────────────
series_name="Change Me"                     # 🎬 Show name
base_folder="$(pwd)"                        # 📂 Base path
output_root="$base_folder/Processed"        # 📁 Output root folder

# Branding (edit once)
brand_name="change me"                      # 🏷️ Brand or encoder name
brand_url="change me"                       # 🌐 Website or source link
brand_comment="Visit ${brand_name} ➜ ${brand_url}"
brand_description="Watch and Download Episodes at ${brand_url}"
brand_artist="${brand_name}"
brand_network="${brand_name}"
brand_title_prefix="${brand_name} -"

# ─── LANGUAGE ORDER SETUP ───────────────────────────────────
# Define which languages should be prioritized in output
# First = most important → becomes default audio (if found)
# Use standard 3-letter language codes like:
# tel (Telugu), tam (Tamil), hin (Hindi), eng (English),
# kor (Korean), jpn (Japanese), kan (Kannada)
declare -a preferred_langs=("tel" "tam" "hin" "kor" "eng" "jpn" "kan")

# Map code → full language name (used in metadata)
declare -A lang_names=(
  ["tel"]="Telugu"
  ["tam"]="Tamil"
  ["hin"]="Hindi"
  ["kor"]="Korean"
  ["eng"]="English"
  ["jpn"]="Japanese"
  ["kan"]="Kannada"
)

mkdir -p "$output_root"
count=1

# ─── MAIN LOOP ──────────────────────────────────────────────
for file in *.mkv; do
  [[ -f "$file" ]] || continue
  echo "🎬 Processing: $file"

  # Detect Season and Episode
  season=$(echo "$file" | grep -oP '(?<=S)\d{1,2}')
  episode=$(echo "$file" | grep -oP '(?<=E)\d{1,2}')
  [[ -z "$season" ]] && season="1"
  [[ -z "$episode" ]] && episode="$count"
  season_num=$(printf "%02d" "$season")
  episode_num=$(printf "%02d" "$episode")
  episode_id="S${season_num}E${episode_num}"

  # ─── Resolution detection ────────────────────────────────
  resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$file")
  [[ -z "$resolution" ]] && resolution="1080"
  if (( resolution >= 4300 )); then
    quality_label="4320p (8K)"
    quality_tag="8K UHD"
  elif (( resolution >= 2100 )); then
    quality_label="2160p (4K)"
    quality_tag="4K UHD"
  elif (( resolution >= 1440 )); then
    quality_label="1440p"
    quality_tag="QHD"
  elif (( resolution >= 1080 )); then
    quality_label="1080p"
    quality_tag="HD"
  elif (( resolution >= 720 )); then
    quality_label="720p"
    quality_tag="HD"
  elif (( resolution >= 480 )); then
    quality_label="480p"
    quality_tag="SD"
  else
    quality_label="${resolution}p"
    quality_tag="SD"
  fi
  source_tag="(NF WEB-DL ${quality_tag})"

  # ─── Audio Stream Detection ──────────────────────────────
  mapfile -t audio_info < <(ffprobe -v error -select_streams a -show_entries stream=index:stream_tags=language -of csv=p=0 "$file")
  declare -A lang_index
  for entry in "${audio_info[@]}"; do
    idx=$(echo "$entry" | cut -d',' -f1)
    lang=$(echo "$entry" | cut -d',' -f2)
    [[ -n "$lang" ]] && lang_index["$lang"]="$idx"
  done

  # Build mapping args
  map_args=(-map 0:v)
  langs_found=()
  for lang in "${preferred_langs[@]}"; do
    if [[ -n "${lang_index[$lang]}" ]]; then
      map_args+=(-map 0:${lang_index[$lang]})
      langs_found+=("$lang")
    fi
  done

  # Subtitles
  mapfile -t sub_info < <(ffprobe -v error -select_streams s -show_entries stream=index:stream_tags=language -of csv=p=0 "$file")
  [[ ${#sub_info[@]} -gt 0 ]] && map_args+=(-map 0:s?)

  # ─── File Name Generator ─────────────────────────────────
  lang_display=$(printf "%s+" "${langs_found[@]}" | sed 's/+$//')
  [[ -z "$lang_display" ]] && lang_display="multi"
  sub_tag=""; [[ ${#sub_info[@]} -gt 0 ]] && sub_tag="- Esub"
  num=$(printf "%02d" "$count")
  new_name="${num}.${series_name} - ${episode_id} - ${quality_label} ${source_tag} - DD+5.1[${lang_display}] ${sub_tag}.mkv"
  season_folder="$output_root/${series_name}/Season_${season_num}"
  mkdir -p "$season_folder"
  output_file="${season_folder}/${new_name}"

  echo "🎞 Output → $output_file"

  # ─── Metadata Setup ──────────────────────────────────────
  meta_args=()
  for i in "${!langs_found[@]}"; do
    code="${langs_found[$i]}"
    name="${lang_names[$code]}"
    meta_args+=(
      -metadata:s:a:$i title="${brand_name} - $name"
      -metadata:s:a:$i handler_name="${brand_name} - $name"
    )
  done

  sub_index=0
  for entry in "${sub_info[@]}"; do
    sub_lang=$(echo "$entry" | cut -d',' -f2)
    [[ -z "$sub_lang" ]] && sub_lang="und"
    sub_name="${lang_names[$sub_lang]:-$sub_lang}"
    meta_args+=(
      -metadata:s:s:$sub_index title="${brand_name} - ${sub_name} Subtitle"
      -metadata:s:s:$sub_index handler_name="${brand_name} - ${sub_name} Subtitle"
    )
    ((sub_index++))
  done

  # Default audio preference
  disposition_args=()
  if [[ " ${langs_found[*]} " == *" tel "* ]]; then
    tel_index=$(printf "%s\n" "${langs_found[@]}" | grep -n "^tel$" | cut -d: -f1)
    ((tel_index--))
    disposition_args=(-disposition:a:$tel_index default)
  else
    disposition_args=(-disposition:a:0 default)
  fi

  # ─── FFmpeg Command ──────────────────────────────────────
  ffmpeg -hide_banner -loglevel error -stats \
    -i "$file" "${map_args[@]}" \
    -metadata title="${series_name} - ${episode_id} - ${brand_name}" \
    -metadata show="${series_name}" \
    -metadata network="${brand_network}" \
    -metadata comment="${brand_comment}" \
    -metadata description="${brand_description}" \
    -metadata artist="${brand_artist}" \
    -metadata:s:v:0 title="${brand_title_prefix} ${series_name} - ${episode_id}" \
    -metadata:s:v:0 handler_name="${brand_title_prefix} ${series_name} - ${episode_id}" \
    "${meta_args[@]}" \
    -c copy "${disposition_args[@]}" \
    "$output_file" -y

  echo "✅ Done: ${new_name}"
  ((count++))
done

echo ""
echo "🎉 All files processed successfully into: $output_root"
