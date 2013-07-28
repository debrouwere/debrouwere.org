import os

for root, dirs, files in os.walk('.'):
    for basename in files:
        if 'textile' in basename:
            filename = os.path.join(root, basename)
            file = open(filename, 'r')
            content = open(filename, 'r').read().split('\n')
            lines = [line for line in content if not line.startswith('layout:')]
            newc = "\n".join(lines)
            open(filename, 'w').write(newc)