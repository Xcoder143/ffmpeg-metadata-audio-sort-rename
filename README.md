# 🎬 FFmpeg Metadata + Audio Sorting + Auto Rename

Automatically:
- Sorts audio tracks based on your **preferred language order**
- Embeds editable **metadata and branding**
- **Detects season, episode, and quality**
- Renames and organizes files neatly under `Processed/SeriesName/Season_XX/`

---

## ⚙️ How to Use

### 1️⃣ Install FFmpeg
```bash
sudo apt install ffmpeg


2️⃣ Place the Script

Put ffmpeg_metadata_sort.sh in the same folder as your .mkv files.

3️⃣ Run
bash ffmpeg_metadata_sort.sh


Processed files will be saved in:

Processed/<Series_Name>/Season_<XX>/

🧠 How to Set Language Order

Language sorting determines:

Which audios are kept and ordered

Which one becomes the default audio track

Edit this section in the script:

declare -a preferred_langs=("tel" "tam" "hin" "kor" "eng" "jpn" "kan")

Example 1 – South Indian Preference
declare -a preferred_langs=("tam" "tel" "hin" "eng")


➡ Tamil first, Telugu second, Hindi third, English last.

Example 2 – International Order
declare -a preferred_langs=("eng" "hin" "tam" "tel")


➡ English audio becomes default if available.

🏷️ Supported Language Codes
Code	Language
tel	Telugu
tam	Tamil
hin	Hindi
eng	English
kor	Korean
jpn	Japanese
kan	Kannada

You can add or remove entries as needed.

🧾 Output Format Example
Processed/Squid Game/Season_01/
01.Squid Game - S01E01 - 1080p (HD) (NF WEB-DL HD) - DD+5.1[tel+tam+hin+eng] - Esub.mkv

🧾 Metadata Example
Tag	Example Value
title	Squid Game - S01E01 - change me
network	change me
artist	change me
comment	Visit change me ➜ change me
description	Watch and Download Episodes at change me
🧩 Tip:

Files without season/episode info will still be auto-numbered (01, 02, etc).

Unavailable languages are skipped automatically.

Subtitle detection adds “- Esub” in the filename.
