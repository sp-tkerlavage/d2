#!/usr/bin/env python3
"""
Generate README files for D2 diagram directories.
Includes companion markdown content and maintains alphabetical ordering.
"""

import os
import sys
import glob
import re
from pathlib import Path
from typing import List, Optional

def find_project_root() -> Path:
    """Find the project root by looking for .git directory."""
    current = Path.cwd()
    while current != current.parent:
        if (current / '.git').exists():
            return current
        current = current.parent
    return Path.cwd()

def extract_title_from_filename(filename: str) -> str:
    """Extract and format title from filename like '01-high-level.d2'."""
    base = os.path.splitext(os.path.basename(filename))[0]
    # Remove numeric prefix
    if re.match(r'^\d{2}-', base):
        _, title = base.split('-', 1)
    else:
        title = base
    
    # Convert hyphens to spaces and title case
    return title.replace('-', ' ').title()

def get_companion_content(d2_file: str) -> Optional[str]:
    """Get content from companion markdown file if it exists."""
    base = os.path.splitext(d2_file)[0]
    md_file = f"{base}.md"
    
    if os.path.exists(md_file):
        with open(md_file, 'r') as f:
            content = f.read().strip()
            if content:
                return content
    return None

def generate_diagram_section(d2_file: str, relative_path: str = ".") -> str:
    """Generate a README section for a single D2 diagram."""
    filename = os.path.basename(d2_file)
    base = os.path.splitext(filename)[0]
    
    # Extract prefix and title
    match = re.match(r'^(\d{2})-(.+)$', base)
    if match:
        prefix = match.group(1)
        title = match.group(2).replace('-', ' ').title()
        section_title = f"## {prefix} - {title}"
    else:
        title = extract_title_from_filename(filename)
        section_title = f"## {title}"
    
    # Start building section
    section = [section_title]
    
    # Add companion content if exists
    companion_content = get_companion_content(d2_file)
    if companion_content:
        section.append("")
        section.append(companion_content)
    
    # Add diagram image
    section.append("")
    section.append(f"![{title}]({relative_path}/diagrams/{base}.png)")
    
    return '\n'.join(section)

def find_d2_files(directory: str) -> List[str]:
    """Find all D2 files in a directory, sorted alphabetically."""
    d2_pattern = os.path.join(directory, '[0-9][0-9]-*.d2')
    d2_files = glob.glob(d2_pattern)
    
    # Also include any D2 files without numeric prefix
    all_d2 = glob.glob(os.path.join(directory, '*.d2'))
    non_numeric = [f for f in all_d2 if not re.match(r'^\d{2}-', os.path.basename(f))]
    
    # Sort numeric files first, then non-numeric
    d2_files = sorted(d2_files) + sorted(non_numeric)
    
    return d2_files

def get_subdirectories(directory: str) -> List[str]:
    """Get immediate subdirectories that contain D2 files or other subdirectories with D2 files."""
    subdirs = []
    for item in os.listdir(directory):
        item_path = os.path.join(directory, item)
        if os.path.isdir(item_path) and not item.startswith('.') and item != 'diagrams':
            # Check if this directory or any subdirectory contains D2 files
            if has_d2_files_recursive(item_path):
                subdirs.append(item)
    return sorted(subdirs)

def has_d2_files_recursive(directory: str) -> bool:
    """Check if directory or any subdirectory contains D2 files."""
    for root, dirs, files in os.walk(directory):
        # Skip hidden directories and diagrams directories
        dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'diagrams']
        if any(f.endswith('.d2') for f in files):
            return True
    return False

def generate_navigation_section(current_dir: str, project_root: str) -> List[str]:
    """Generate navigation links to subdirectories."""
    subdirs = get_subdirectories(current_dir)
    if not subdirs:
        return []
    
    section = ["## Sections", ""]
    for subdir in subdirs:
        # Format subdirectory name for display
        display_name = subdir.replace('-', ' ').title()
        section.append(f"- [{display_name}](./{subdir}/)")
    
    return section

def get_directory_content(directory: str) -> Optional[str]:
    """Get content from directory-level markdown file if it exists."""
    # Look for a markdown file with the same name as the directory
    dir_name = os.path.basename(directory)
    dir_md_file = os.path.join(directory, f"{dir_name}.md")
    
    # Also check for a generic directory.md file
    generic_md_file = os.path.join(directory, "directory.md")
    
    for md_file in [dir_md_file, generic_md_file]:
        if os.path.exists(md_file):
            with open(md_file, 'r') as f:
                content = f.read().strip()
                if content:
                    return content
    return None

def generate_readme_for_directory(directory: str, project_root: str) -> str:
    """Generate README content for a single directory."""
    # Get directory name for title
    dir_name = os.path.basename(directory) if directory != project_root else "D2 Diagrams"
    title = dir_name.replace('-', ' ').title()
    
    readme_parts = [f"# {title}", ""]
    
    # Add navigation to subdirectories (at the top)
    nav_section = generate_navigation_section(directory, project_root)
    if nav_section:
        readme_parts.extend(nav_section)
        readme_parts.append("")
    
    # Add directory-level content if it exists (below navigation)
    dir_content = get_directory_content(directory)
    if dir_content:
        readme_parts.append(dir_content)
        readme_parts.append("")
    
    # Find and process D2 files in this directory
    d2_files = find_d2_files(directory)
    
    if d2_files:
        if nav_section or dir_content:
            readme_parts.append("## Diagrams")
            readme_parts.append("")
        
        diagram_sections = []
        for d2_file in d2_files:
            section = generate_diagram_section(d2_file)
            diagram_sections.append(section)
        
        # Join sections with horizontal rule
        readme_parts.append("\n\n---\n\n".join(diagram_sections))
    
    return '\n'.join(readme_parts)

def update_readme(directory: str, project_root: str) -> None:
    """Update or create README.md in the specified directory."""
    readme_path = os.path.join(directory, 'README.md')
    content = generate_readme_for_directory(directory, project_root)
    
    # Write README file
    with open(readme_path, 'w') as f:
        f.write(content)
    
    print(f"Updated: {readme_path}")

def generate_top_level_readme(project_root: str) -> None:
    """Generate top-level README using top-level.md content file."""
    readme_path = os.path.join(project_root, 'README.md')
    top_level_md = os.path.join(project_root, 'top-level.md')
    
    readme_parts = ["# D2 Diagrams Repository", ""]
    
    # Add navigation sections if there are subdirectories
    subdirs = get_subdirectories(project_root)
    if subdirs:
        readme_parts.append("## Sections")
        readme_parts.append("")
        for subdir in subdirs:
            display_name = subdir.replace('-', ' ').title()
            readme_parts.append(f"- [{display_name}](./{subdir}/)")
        readme_parts.append("")
    
    # Add content from top-level.md if it exists
    if os.path.exists(top_level_md):
        with open(top_level_md, 'r') as f:
            content = f.read().strip()
            if content:
                readme_parts.append(content)
                readme_parts.append("")
    
    # Write the complete README
    with open(readme_path, 'w') as f:
        f.write('\n'.join(readme_parts))
    
    print(f"Updated: {readme_path}")

def process_directories(directories: List[str], project_root: str) -> None:
    """Process a list of directories to update their README files."""
    processed = set()
    
    for directory in directories:
        # Convert to absolute path
        abs_dir = os.path.abspath(directory)
        
        # Update README for this directory
        if abs_dir not in processed:
            update_readme(abs_dir, project_root)
            processed.add(abs_dir)
        
        # Also update parent directories up to project root
        current = Path(abs_dir).parent
        while current >= Path(project_root):
            if str(current) not in processed:
                update_readme(str(current), project_root)
                processed.add(str(current))
            if current == Path(project_root):
                break
            current = current.parent

def main():
    """Main entry point."""
    project_root = str(find_project_root())
    os.chdir(project_root)
    
    if len(sys.argv) > 1:
        if sys.argv[1] == '--top-level':
            # Just generate top-level README
            generate_top_level_readme(project_root)
        else:
            # Process specific directories from command line or stdin
            if sys.argv[1] == '-':
                # Read directories from stdin
                directories = [line.strip() for line in sys.stdin if line.strip()]
            else:
                # Get directories from arguments (could be multiline string)
                directories = sys.argv[1].strip().split('\n')
                directories = [d.strip() for d in directories if d.strip()]
            
            if directories:
                process_directories(directories, project_root)
    else:
        # Process all directories with D2 files or relevant markdown files
        all_dirs = set()
        for root, dirs, files in os.walk(project_root):
            # Skip hidden directories and diagrams directories
            dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'diagrams']
            
            # Include directories that have:
            # - D2 files
            # - Numbered companion markdown files (01-*.md, 02-*.md, etc.)
            # - Directory-level markdown files (directory.md, {dirname}.md, 00-{dirname}.md)
            has_d2 = any(f.endswith('.d2') for f in files)
            has_companion_md = any(re.match(r'^\d{2}-.*\.md$', f) for f in files)
            
            # Check for directory-level markdown
            dir_name = os.path.basename(root)
            has_dir_md = any(f in files for f in [
                f'{dir_name}.md',
                f'00-{dir_name}.md',
                'directory.md'
            ])
            
            if has_d2 or has_companion_md or has_dir_md:
                all_dirs.add(root)
        
        if all_dirs:
            process_directories(list(all_dirs), project_root)
        
        # Always generate top-level README
        generate_top_level_readme(project_root)

if __name__ == '__main__':
    main()