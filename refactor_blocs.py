import os
import re

def process_bloc_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if this file actually contains State or Event classes
    # We look for "abstract class XEvent" or "abstract class XState"
    basename = os.path.basename(filepath)
    prefix = basename.replace('_bloc.dart', '')
    
    event_file = filepath.replace('_bloc.dart', '_event.dart')
    state_file = filepath.replace('_bloc.dart', '_state.dart')
    
    # Simple heuristic to split the file
    # We'll split the content into imports, state classes, event classes, and bloc class
    # Since dart files can be formatted differently, we will use regex
    
    # Find all imports
    imports = re.findall(r"^import\s+['\"].*?['\"];?$", content, re.MULTILINE)
    
    # If the file already has 'part' or 'export' for event/state, skip
    if f"export '{prefix}_event.dart'" in content or f"part '{prefix}_event.dart'" in content:
        # File is already separated properly (or partially)
        # Let's check if there are still class definitions inside it
        pass
    
    # Let's manually parse. Usually they are at the top (imports), then state, then event, then bloc
    # Or Event then State.
    
    # We'll find the classes.
    class_pattern = re.compile(r"((?:abstract\s+)?class\s+(\w+)\s+(?:extends|implements).*?(?=\n(?:abstract\s+)?class |\Z))", re.DOTALL)
    
    classes = class_pattern.findall(content)
    
    if not classes:
        return

    states_code = []
    events_code = []
    bloc_code = []
    
    for full_match, class_name in classes:
        if class_name.endswith('State'):
            states_code.append(full_match)
        elif class_name.endswith('Event'):
            events_code.append(full_match)
        elif class_name.endswith('Bloc'):
            bloc_code.append(full_match)
        else:
            # Maybe it's a specific event or state like 'DealDetailLoadRequested'
            # Let's check the extends clause
            if 'extends' in full_match:
                if re.search(r'extends\s+\w+State', full_match):
                    states_code.append(full_match)
                elif re.search(r'extends\s+\w+Event', full_match):
                    events_code.append(full_match)
                else:
                    bloc_code.append(full_match)
            else:
                bloc_code.append(full_match)

    if not states_code and not events_code:
        return # Nothing to separate

    # Build the new contents
    # For Event and State files, they need the imports (like equatable, etc.)
    # We'll just put all imports in all files to be safe, dart will warn about unused but it will compile
    
    common_imports = "\n".join(imports)
    
    # Write event file
    if events_code:
        with open(event_file, 'w', encoding='utf-8') as f:
            f.write(common_imports + "\n\n")
            f.write("\n\n".join(events_code) + "\n")
            
    # Write state file
    if states_code:
        with open(state_file, 'w', encoding='utf-8') as f:
            f.write(common_imports + "\n\n")
            f.write("\n\n".join(states_code) + "\n")
            
    # Write bloc file
    if bloc_code:
        # Check if we should export them so that imports in UI don't break
        export_event = f"export '{prefix}_event.dart';"
        export_state = f"export '{prefix}_state.dart';"
        
        # Filter imports to exclude any relative paths that might point to themselves (unlikely)
        new_bloc_imports = common_imports
        if export_event not in new_bloc_imports:
            new_bloc_imports += f"\n{export_event}"
        if export_state not in new_bloc_imports:
            new_bloc_imports += f"\n{export_state}"
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_bloc_imports + "\n\n")
            f.write("\n\n".join(bloc_code) + "\n")

features_dir = r'c:\Users\IB-72\ib_projects\sales-prospecting-assistant-crm\lib\features'
for root, dirs, files in os.walk(features_dir):
    if 'bloc' in root.split(os.sep):
        for f in files:
            if f.endswith('_bloc.dart'):
                process_bloc_file(os.path.join(root, f))

print('Done')
