"""
python validate_internal_links.py 1
"""

import os, re, requests, sys

try:
  verbose = int(sys.argv[1]) == 1
except:
  verbose = False

def findDocsLinks(_text):
  pattern = r'\]\(([^\()]+\.md(#?)[^\)]*)\)'
  match_list = []
  for match in re.findall(pattern, _text):
    match_list.append(match[0])

  return match_list

report = {}
count = 0
passed = 0

for dir_path, dir_names, file_names in os.walk(".."):
  if "\\_" in dir_path: continue

  for file_name in file_names:
    if not file_name.endswith(".md"): continue
    file_path = os.path.join(dir_path, file_name)
    
    print(file_path)
    if not file_path in report: 
      report[file_path] = []

    with open(file_path, 'r') as md_file:
      for link in findDocsLinks(md_file.read()):
        if link.startswith("http"): continue
        
        count += 1

        if verbose: print(link)

        link_path = os.path.abspath(
          os.path.join(dir_path, link.split("#")[0])
        )

        if os.path.isfile(link_path):
          passed += 1

        else:
          report[file_path].append(link)
        
result_line = f'Test complete. {passed} passed out of {count}.'
print('='*len(result_line))
print(result_line)
print('='*len(result_line))

for file_path in report.keys():
  if len(report[file_path]) > 0:
    print('-'*len(file_path))
    print(file_path)
    print('-'*len(file_path))

    for msg in report[file_path]:
      print(msg)
