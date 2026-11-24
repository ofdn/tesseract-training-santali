#!/bin/bash
# Downloads Latin.traineddata, extracts output/latin.lstm, writes the
# Ol Chiki unicharset and builds tessdata_best/sat_base.traineddata.
# Ol Chiki is an alphabet, so Latin is a closer start than an abugida
# like Odia. Safe to run again.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

TESSDATA_BEST="$SCRIPT_DIR/tessdata_best"
OUTPUT="$SCRIPT_DIR/output"
LANGDATA="$OUTPUT/langdata"

mkdir -p "$TESSDATA_BEST/configs" "$LANGDATA"

# config for making .lstmf files, the same as tesseract's own configs/lstm.train
cat > "$TESSDATA_BEST/configs/lstm.train" << 'CFG'
file_type                   .bl
textord_fast_pitch_test	T
tessedit_zero_rejection T
tessedit_minimal_rejection F
tessedit_write_rep_codes F
edges_children_fix F
edges_childarea 0.65
edges_boxarea 0.9
tessedit_train_line_recognizer T
textord_no_rejects T
tessedit_init_config_only T
CFG

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 1 — Santali training setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# A: download Latin LSTM base
echo ""
echo "→ [A] Base model..."
if [ ! -f "$TESSDATA_BEST/Latin.traineddata" ]; then
    echo "  Downloading tessdata_best/Latin.traineddata..."
    curl -fL --progress-bar \
        "https://github.com/tesseract-ocr/tessdata_best/raw/main/script/Latin.traineddata" \
        -o "$TESSDATA_BEST/Latin.traineddata"
    echo "  Downloaded: $(du -h $TESSDATA_BEST/Latin.traineddata | cut -f1)"
else
    echo "  Already present: tessdata_best/Latin.traineddata"
fi

# B: Extract LSTM weights
echo ""
echo "→ [B] Extracting latin.lstm..."
combine_tessdata -e "$TESSDATA_BEST/Latin.traineddata" "$OUTPUT/latin.lstm" 2>/dev/null
ls -lh "$OUTPUT/latin.lstm"
echo "  (This is the starting point for fine-tuning)"

# C: Create Santali unicharset
echo ""
echo "→ [C] Building Santali unicharset (Ol Chiki + punctuation)..."

python3 << 'PYEOF'
from pathlib import Path

# Full Ol Chiki Unicode block U+1C50–U+1C7F

entries = [
]

# Ol Chiki digits
for cp in range(0x1C50, 0x1C5A):
    entries.append((chr(cp), '0', '0', 'Ol_Chiki', 'x'))

# Ol Chiki letters
for cp in range(0x1C5A, 0x1C78):
    entries.append((chr(cp), '1', '0', 'Ol_Chiki', 'x'))

# Ol Chiki signs / modifiers
for cp in range(0x1C78, 0x1C7E):
    entries.append((chr(cp), '0', '0', 'Ol_Chiki', ''))

# Ol Chiki punctuation
for cp in range(0x1C7E, 0x1C80):
    entries.append((chr(cp), '10', '10', 'Ol_Chiki', 'p'))

# Common ASCII punctuation that appears in Santali texts
ascii_punct = [
    ('.', '10', '10', 'Common', 'p'),
    (',', '10', '10', 'Common', 'p'),
    (':', '10', '10', 'Common', 'p'),
    ('?', '10', '10', 'Common', 'p'),
    ('!', '10', '10', 'Common', 'p'),
    ('-', '10', '10', 'Common', 'p'),
    ('/', '10', '10', 'Common', 'p'),
    ('"', '10', '10', 'Common', 'p'),
    ("'", '10', '10', 'Common', 'p'),
    ('(', '10', '10', 'Common', 'p'),
    (')', '10', '10', 'Common', 'p'),
    ('*', '10', '10', 'Common', 'p'),
    ('%', '10', '10', 'Common', 'p'),
]
entries.extend(ascii_punct)

# ASCII digits
for ch in '0123456789':
    entries.append((ch, '0', '0', 'Common', 'x'))

uid = 3  # 0=NULL, 1=Joined, 2=Broken
lines = [f'{len(entries) + 3}\n']  # count line (updated below)
lines.append('NULL 0 NULL 0\n')
lines.append('Joined 7 0,69,188,255,486,1218,0,30,486,1188 Latin 1 0 1 Joined\t# Joined [4a 6f 69 6e 65 64 ]a\n')
lines.append('|Broken|0|1 f 0,69,186,255,892,2138,0,80,892,2058 Common 2 10 2 |Broken|0|1\t# Broken\n')

for char, props, direction, script, type_sfx in entries:
    hex_cp = ' '.join(f'{ord(c):x}' for c in char)
    comment_type = f' ]{type_sfx}' if type_sfx else ' ]'
    line = (f'{char} {props} 0,255,0,255,0,0,0,0,0,0 {script}'
            f' {uid} {direction} {uid} {char}\t'
            f'# {char} [{hex_cp}{comment_type}\n')
    lines.append(line)
    uid += 1

# Patch the count
lines[0] = f'{uid}\n'

out = Path('output/sat.unicharset')
out.write_text(''.join(lines), encoding='utf-8')
print(f'  {uid} entries in unicharset → output/sat.unicharset')
print(f'  Ol Chiki: 10 digits + 30 letters + 6 signs + 2 punct = 48')
print(f'  ASCII punct: {len(ascii_punct)}  ASCII digits: 10')
PYEOF

# D: Build sat_base.traineddata
echo ""
echo "→ [D] Building tessdata_best/sat_base.traineddata..."

LANGMODEL_OUT="output/langmodel_tmp"
mkdir -p "$LANGMODEL_OUT"

# combine_lang_model wants radical-stroke.txt even though only CJK uses it
printf "0\n" > "$LANGDATA/radical-stroke.txt"

# Ol Chiki needs one code per character, so a pass-through recoder
rm -rf "$LANGMODEL_OUT/sat_base"
mkdir -p "$LANGMODEL_OUT/sat_base"
combine_lang_model \
    --input_unicharset output/sat.unicharset \
    --script_dir "$LANGDATA" \
    --output_dir "$LANGMODEL_OUT" \
    --lang sat_base \
    --pass_through_recoder > "$LANGMODEL_OUT/build.log" 2>&1

BUILT="$LANGMODEL_OUT/sat_base/sat_base.traineddata"
combine_tessdata -d "$BUILT" 2>&1 | grep -q lstm-recoder || {
    echo "ERROR: $BUILT has no recoder, see $LANGMODEL_OUT/build.log"; exit 1; }

cp "$BUILT" "$TESSDATA_BEST/sat_base.traineddata"
ls -lh "$TESSDATA_BEST/sat_base.traineddata"

# Verify the unicharset is inside
combine_tessdata -u "$TESSDATA_BEST/sat_base.traineddata" "$LANGMODEL_OUT/verify" >/dev/null 2>&1
UC_COUNT=$(head -1 "$LANGMODEL_OUT/verify.lstm-unicharset" | tr -d ' ')
echo "  Unicharset entries in sat_base.traineddata: $UC_COUNT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup complete."
echo ""
echo "  Base model:           tessdata_best/Latin.traineddata"
echo "  LSTM weights:         output/latin.lstm"
echo "  Santali unicharset:   output/sat.unicharset ($UC_COUNT entries)"
echo "  Training traineddata: tessdata_best/sat_base.traineddata"
echo ""
echo "  NEXT STEPS:"
echo "    1. python3 render-corpus.py       (renders synthetic images)"
echo "    2. ./02-make-lstmf.sh             (creates .lstmf files and lstmf/list.txt)"
echo "    3. ./03-train.sh                  (starts training)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
