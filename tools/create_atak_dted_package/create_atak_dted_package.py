#!/usr/bin/env python3
"""
Script to create an ATAK DTED data package from .dt2 files.
Organizes files into folders by longitude (e###) and renames to latitude (n##.dt2).
"""

import os
import zipfile
import re
import shutil
from pathlib import Path

def parse_dt2_filename(filename):
    """
    Parse DTED filename to extract latitude and longitude.
    Format: n##_e###_1arc_v3.dt2
    Returns: (latitude_part, longitude_part) e.g., ('n47', 'e006')
    """
    # Match pattern like n47_e006_1arc_v3.dt2
    match = re.match(r'^(n\d+)_(e\d+)_', filename)
    if match:
        return match.group(1), match.group(2)
    return None, None

def create_atak_dted_package(source_dir, create_zip=False, output_zip=None):
    """
    Create an ATAK DTED data package from .dt2 files.
    
    Structure:
    - Main folder with same name as source directory
    - Subfolders named by longitude (e###)
    - Files renamed to latitude (n##.dt2)
    
    Args:
        source_dir: Directory containing .dt2 files
        create_zip: Whether to create a ZIP file (default: False)
        output_zip: Output ZIP file path (default: atak_dted_package.zip)
    """
    source_path = Path(source_dir)
    
    if not source_path.exists():
        raise ValueError(f"Source directory does not exist: {source_dir}")
    
    # Clean up any existing package directory and zip files
    main_folder_name = source_path.name
    package_dir = source_path / main_folder_name
    if package_dir.exists():
        print(f"Cleaning up existing package directory: {package_dir}")
        shutil.rmtree(package_dir)
    
    if output_zip is None:
        output_zip = source_path / "atak_dted_package.zip"
    else:
        output_zip = Path(output_zip)
    
    if output_zip.exists() and create_zip:
        print(f"Removing existing ZIP file: {output_zip}")
        output_zip.unlink()
    
    # Find all .dt2 files
    dt2_files = list(source_path.glob("*.dt2"))
    
    if not dt2_files:
        raise ValueError(f"No .dt2 files found in {source_dir}")
    
    print(f"Found {len(dt2_files)} DTED Level 2 files")
    
    # Create subfolder with same name as main folder
    print(f"Creating package structure in: {package_dir}")
    package_dir.mkdir(exist_ok=True)
    
    skipped_files = []
    folders_created = set()
    
    # Copy files to the right place with renamed names
    print(f"Copying and organizing files...")
    for i, dt2_file in enumerate(dt2_files):
        lat_part, lon_part = parse_dt2_filename(dt2_file.name)
        
        if not lat_part or not lon_part:
            skipped_files.append(dt2_file.name)
            if len(skipped_files) <= 5:
                print(f"  Warning: Could not parse filename: {dt2_file.name}")
            continue
        
        # Folder name is the longitude part (e###)
        folder_name = lon_part
        # File name is just the latitude part (n##.dt2)
        new_filename = f"{lat_part}.dt2"
        
        # Create folder if it doesn't exist
        folder_path = package_dir / folder_name
        if folder_name not in folders_created:
            folder_path.mkdir(exist_ok=True)
            folders_created.add(folder_name)
        
        # Copy file with new name
        dest_file = folder_path / new_filename
        shutil.copy2(dt2_file, dest_file)
        
        if (i + 1) % 50 == 0:
            print(f"  Processed {i + 1}/{len(dt2_files)} files...")
    
    if skipped_files:
        print(f"\nSkipped {len(skipped_files)} files due to parsing errors")
    
    print(f"Created {len(folders_created)} folders")
    print(f"Package structure created in: {package_dir}")
    
    # Create ZIP file if requested
    if create_zip:
        print(f"Creating ZIP file: {output_zip}")
        with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Walk through the package directory and add all files
            for root, dirs, files in os.walk(package_dir):
                root_path = Path(root)
                for file in files:
                    file_path = root_path / file
                    # Create arcname with main folder as root
                    rel_path = file_path.relative_to(package_dir.parent)
                    arcname = str(rel_path)
                    zipf.write(file_path, arcname)
        
        print(f"ZIP file created: {output_zip}")
        print(f"Package size: {output_zip.stat().st_size / (1024*1024):.2f} MB")
    
    print(f"\nATAK DTED package structure created successfully")
    print(f"Organized into {len(folders_created)} folders")
    print(f"\nTo import into ATAK:")
    print(f"  1. Transfer the package folder or ZIP to your Android device")
    print(f"  2. Open ATAK")
    print(f"  3. Use Data Package Tool to import")
    print(f"  4. Or extract to: /sdcard/atak/DATA/dted/")
    
    return package_dir if not create_zip else output_zip

if __name__ == "__main__":
    import sys
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Create an ATAK DTED data package from .dt2 files. "
                    "Organizes files into folders by longitude (e###) and renames to latitude (n##.dt2).",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        "source_dir",
        nargs="?",
        default=None,
        help="Directory containing .dt2 files (default: current directory)"
    )
    
    parser.add_argument(
        "-z", "--zip",
        action="store_true",
        help="Create a ZIP file of the package (default: False)"
    )
    
    parser.add_argument(
        "-o", "--output",
        type=str,
        default=None,
        help="Output ZIP file path (default: <source_dir>/atak_dted_package.zip)"
    )
    
    args = parser.parse_args()
    
    # Determine source directory
    if args.source_dir is None:
        # Default to current directory if not specified
        source_dir = Path.cwd()
    else:
        source_dir = Path(args.source_dir)
    
    try:
        output_file = create_atak_dted_package(
            source_dir,
            create_zip=args.zip,
            output_zip=args.output
        )
        print(f"\n✓ Success! Package structure created: {output_file}")
    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
