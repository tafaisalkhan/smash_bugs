import os, sys

script_dir = os.path.dirname(os.path.abspath(__file__))
apply_script = os.path.join(script_dir, "apply_single_bug_icon.py")
os.system(f'python "{apply_script}"')
