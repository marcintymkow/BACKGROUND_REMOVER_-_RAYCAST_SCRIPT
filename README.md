# Background Remover – Raycast Scripts

Raycast script commands to convert images to WebP, with an optional step that removes white or black backgrounds.

## Scripts

### Remove Background → WebP (`remove-background-to-webp.sh`)

Removes the background (white or black) from selected files and saves them as WebP with transparency.

**How it works:**

- **Flood fill** – only removes pixels connected to the image edge (keeps things like stars or holes inside the subject)
- **Edge cleanup** – blurring the alpha channel reduces white halos from anti-aliasing
- **WebP export** – encoder settings similar to Squoosh

**Raycast arguments:**

| # | Description | Default |
|---|-------------|---------|
| 1 | WebP quality (75–95) | 75 |
| 2 | Fuzz % – tolerance for “almost white/black” (10–35) | 25 |
| 3 | Background color: `white` or `black` | white |

**Supported formats:** PNG, JPG, JPEG

**Examples:**

- White background (logos, product shots): leave defaults (`white`)
- Black background (e.g. white line art): set the third argument to `black`

---

### Convert to WebP (`convert-to-webp.sh`)

Converts selected images to WebP without removing the background.

**Arguments:**

- Quality (75–95), default **82**

**Supported formats:** PNG, JPG, JPEG, TIFF, GIF, BMP

---

## Requirements

```bash
brew install imagemagick webp
```

- **ImageMagick** – background removal (`remove-background-to-webp.sh`)
- **webp** (`cwebp`) – WebP encoding (both scripts)

---

## Install in Raycast

1. Open Raycast → **Extensions** → **Script Commands**
2. **Add Script Command** → **Import from file**
3. Pick the `.sh` file you want

You can also copy the scripts into your Raycast script commands folder.

---

## Usage

1. Select files in Finder
2. Open Raycast (e.g. ⌘+Space)
3. Run **Remove Background → WebP** or **Convert to WebP**
4. Confirm – `.webp` files are written next to the originals

---

## How background removal works

1. **Flood fill** – ImageMagick only clears pixels connected to the border, so interior details (e.g. soft stars inside the shape) stay visible
2. **`-fill none`** – transparency is applied directly (no magenta or other “chroma key” middle step)
3. **Alpha blur** – smoothing the alpha channel (`-blur 0x1.5 -level 50x100%`) reduces white fringe on edges

---

## Author

Marcin
