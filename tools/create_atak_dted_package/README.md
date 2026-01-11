# Create ATAK DTED Package

A Python utility script for creating ATAK-compatible DTED (Digital Terrain Elevation Data) data packages from DTED Level 2 (`.dt2`) files.

## Overview

DTED (Digital Terrain Elevation Data) files provide elevation information for terrain mapping in ATAK. This tool:
- Organizes `.dt2` files into folders by longitude (e###)
- Renames files to latitude format (n##.dt2)
- Creates a folder structure ready for ATAK import
- Optionally creates a ZIP file of the package

The organized structure can be:
- Extracted directly to ATAK's DTED directory (`/sdcard/atak/DATA/dted/`)
- Imported via ATAK's Data Package Tool
- Uploaded to OpenTAKServer for distribution to clients

## Prerequisites

- Python 3.6 or higher
- DTED Level 2 files (`.dt2` format) with naming convention: `n##_e###_1arc_v3.dt2`

## Installation

No installation required. The script is standalone and uses only Python standard library modules.

## Usage

### Basic Usage

```bash
# Process current directory (creates folder structure only)
python3 create_atak_dted_package.py

# Process specific directory
python3 create_atak_dted_package.py /path/to/dted/directory
```

### Examples

**Create package structure from current directory:**
```bash
python3 create_atak_dted_package.py
```

**Create package from a specific directory:**
```bash
python3 create_atak_dted_package.py /path/to/dted/files
```

**Create ZIP file of the package:**
```bash
python3 create_atak_dted_package.py -z
```

**Create ZIP with custom output filename:**
```bash
python3 create_atak_dted_package.py -z -o my_dted_package.zip
```

**Process directory and create ZIP:**
```bash
python3 create_atak_dted_package.py /path/to/dted/files -z -o output.zip
```

### Command Line Options

```
usage: create_atak_dted_package.py [-h] [-z] [-o OUTPUT] [source_dir]

positional arguments:
  source_dir           Directory containing .dt2 files (default: current directory)

options:
  -h, --help           Show help message
  -z, --zip            Create a ZIP file of the package (default: False)
  -o, --output OUTPUT  Output ZIP file path (default: <source_dir>/atak_dted_package.zip)
```

## Output

The script creates an organized folder structure (and optionally a ZIP file) with DTED files organized by longitude.

### Package Structure

The script creates a folder structure where:
- Main folder has the same name as the source directory
- Subfolders are named by longitude (e###, e.g., `e006`, `e007`)
- Files are renamed to latitude format (n##.dt2, e.g., `n47.dt2`, `n48.dt2`)

**Example structure:**
```
source_directory/
└── source_directory/          # Main package folder
    ├── e006/                  # Longitude folder
    │   ├── n47.dt2
    │   ├── n48.dt2
    │   └── ...
    ├── e007/                  # Longitude folder
    │   ├── n47.dt2
    │   ├── n48.dt2
    │   └── ...
    └── ...
```

**If `-z` flag is used, creates:**
```
atak_dted_package.zip
└── source_directory/
    ├── e006/
    │   ├── n47.dt2
    │   └── ...
    └── ...
```

## Using the Package

### Import into ATAK/iTAK

**Method 1: Direct folder extraction (recommended)**
1. Transfer the package folder (or extract the ZIP) to your Android device
2. Extract/copy to: `/sdcard/atak/DATA/dted/`
3. The DTED elevation data will be automatically available for terrain visualization

**Method 2: Via Data Package Tool**
1. Transfer the ZIP file to your device
2. Open ATAK/iTAK
3. Go to **Settings** → **Data Packages** → **Import**
4. Select the ZIP file
5. The DTED elevation data will be available for terrain visualization

### Upload to OpenTAKServer

You can upload the ZIP package to OpenTAKServer for automatic distribution to connected clients:

```bash
# Using curl (requires authentication token)
curl -X POST \
  -H "Authentication-Token: <your_token>" \
  -F "file=@atak_dted_package.zip" \
  "http://<opentakserver_host>:<port>/api/data_packages"
```

Or use the Ansible role:
```bash
ansible-playbook playbooks/site.yml --tags ots-dted
```

## DTED File Formats

The tool currently supports:
- **DTED Level 2** (`.dt2`) - 30 m resolution

**File naming convention required:**
- Format: `n##_e###_1arc_v3.dt2`
- Example: `n47_e006_1arc_v3.dt2` (latitude 47°N, longitude 6°E)
- The script extracts latitude (`n##`) and longitude (`e###`) from the filename
- Files that don't match this pattern will be skipped with a warning

## Notes

- Large DTED file collections may take time to process
- The script processes files in batches and shows progress every 50 files
- DTED files are typically large (hundreds of MB to GB), ensure sufficient storage
- Files are organized by longitude folders and renamed to latitude format for ATAK compatibility
- The script automatically cleans up existing package directories and ZIP files before creating new ones
- Progress is shown during processing, including warnings for files that couldn't be parsed

## Related Tools

- [`ansible/roles/opentakserver-dted/`](../../ansible/roles/opentakserver-dted/) - Ansible role for uploading DTED packages to OpenTAKServer
- [`bash/atak/scripts/certDP.sh`](../../bash/atak/scripts/certDP.sh) - Script for creating certificate data packages (reference for package structure)

## Troubleshooting

**Error: "Source directory does not exist"**
- Ensure the specified directory path is correct
- Use absolute paths if relative paths don't work
- If no directory is specified, ensure you're running from a directory containing `.dt2` files

**Error: "No .dt2 files found in <directory>"**
- Ensure the directory contains `.dt2` files
- Check that files have the `.dt2` extension
- Verify file permissions allow reading

**Warning: "Could not parse filename"**
- Files must follow the naming convention: `n##_e###_1arc_v3.dt2`
- Check that filenames match the pattern (e.g., `n47_e006_1arc_v3.dt2`)
- Files that don't match will be skipped

**Error: "Output ZIP file path not writable"**
- Check write permissions for the output location
- Ensure sufficient disk space for the ZIP file
- Use `-o` option to specify a different output location

**Package too large**
- Consider splitting large DTED collections into multiple packages by region
- Use the `-z` flag to create compressed ZIP files
- DTED Level 2 files are high resolution and can be very large

## References

- [TAK Product Center](https://tak.gov) - Official TAK documentation
- [ATAK Data Package Format](https://github.com/deptofdefense/AndroidTacticalAssaultKit) - ATAK package specification
- [DTED Format Specification](https://www.dgiwg.org/dted/) - Digital Terrain Elevation Data standards
