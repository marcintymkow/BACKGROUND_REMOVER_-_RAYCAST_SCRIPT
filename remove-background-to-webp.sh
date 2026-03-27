#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Remove Background → WebP
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ✂️
# @raycast.argument1 { "type": "text", "placeholder": "75", "optional": true }
# @raycast.argument2 { "type": "text", "placeholder": "25", "optional": true }
# @raycast.argument3 { "type": "text", "placeholder": "white", "optional": true }
# @raycast.packageName Image Tools

# Documentation:
# @raycast.description Usuwa tło (tylko połączone z brzegiem) → WebP
# @raycast.author Marcin
# @raycast.authorURL https://raycast.com

# Domyślne wartości (puste pola = te wartości)
QUALITY="${1:-75}"
# Fuzz: tolerancja na "prawie białe/czarne" piksele - wyższa = usuwa więcej halo (25-35 dla antyaliasingu)
FUZZ="${2:-25}"
# Kolor tła: white (domyślnie) lub black (dla ilustracji na czarnym tle, np. białe linie)
BG_COLOR="${3:-white}"
[[ "$BG_COLOR" != "black" ]] && BG_COLOR="white"

# Sprawdź ImageMagick
if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo "❌ Zainstaluj ImageMagick: brew install imagemagick"
    exit 1
fi
IMAGEMAGICK=$(command -v magick 2>/dev/null || command -v convert 2>/dev/null)

# Sprawdź cwebp
if ! command -v cwebp &> /dev/null; then
    echo "❌ Zainstaluj webp: brew install webp"
    exit 1
fi

# Pobierz zaznaczone pliki z Findera
FILES=$(osascript -e '
tell application "Finder"
    set selectedItems to selection
    if selectedItems is {} then
        return ""
    end if
    set filePaths to ""
    repeat with i in selectedItems
        set filePaths to filePaths & POSIX path of (i as alias) & linefeed
    end repeat
    return filePaths
end tell
')

if [ -z "$FILES" ]; then
    echo "❌ Zaznacz pliki w Finderze"
    exit 1
fi

COUNT=0
SAVED=0

while IFS= read -r file; do
    [ -z "$file" ] && continue
    
    EXT="${file##*.}"
    EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$EXT_LOWER" =~ ^(jpg|jpeg|png)$ ]]; then
        DIR=$(dirname "$file")
        BASENAME=$(basename "$file" ".$EXT")
        OUTPUT="$DIR/${BASENAME}.webp"
        TEMP_PNG="$DIR/${BASENAME}_temp_bgremoved.png"
        
        SIZE_BEFORE=$(stat -f%z "$file" 2>/dev/null || echo 0)
        
        # Krok 1: Usuń tło (flood fill z przezroczystością)
        # Krok 2: Czyste krawędzie - blur kanału alpha usuwa białe halo z antyaliasingu
        $IMAGEMAGICK "$file" -alpha set -bordercolor "$BG_COLOR" -border 1 -fuzz "${FUZZ}%" \
            -fill none -draw "color 0,0 floodfill" -shave 1 \
            \( +clone -alpha extract -blur 0x1.5 -level 50x100% \) -alpha off -compose copyOpacity -composite \
            "$TEMP_PNG" 2>/dev/null
        
        if [ ! -f "$TEMP_PNG" ]; then
            continue
        fi
        
        # Krok 2: Konwersja do WebP (parametry jak w convert-to-webp.sh)
        cwebp -q "$QUALITY" -m 6 -af -sharp_yuv -quiet "$TEMP_PNG" -o "$OUTPUT" 2>/dev/null
        
        # Usuń plik tymczasowy
        rm -f "$TEMP_PNG"
        
        if [ -f "$OUTPUT" ]; then
            SIZE_AFTER=$(stat -f%z "$OUTPUT" 2>/dev/null || echo 0)
            if [ "$SIZE_BEFORE" -gt 0 ]; then
                REDUCTION=$((100 - (SIZE_AFTER * 100 / SIZE_BEFORE)))
                SAVED=$((SAVED + SIZE_BEFORE - SIZE_AFTER))
            fi
            ((COUNT++))
        fi
    fi
done <<< "$FILES"

if [ $COUNT -gt 0 ]; then
    if [ $SAVED -gt 1048576 ]; then
        SAVED_FMT="$(echo "scale=1; $SAVED/1048576" | bc)MB"
    elif [ $SAVED -gt 1024 ]; then
        SAVED_FMT="$(echo "scale=1; $SAVED/1024" | bc)KB"
    else
        SAVED_FMT="${SAVED}B"
    fi
    echo "✅ Usunięto tło z $COUNT plików → WebP (oszczędność ~$SAVED_FMT)"
else
    echo "❌ Nie znaleziono plików PNG/JPG/JPEG do przetworzenia"
fi
