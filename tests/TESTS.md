# Tests

This folder contains test files to be run to validate aspects of these tutorial files.

## List of validation tests

### Internal links

From this `tests` folder, run the script `python validate_internal_links.py`.  This file searches all markdown files for internal `.md` references and checks that those files exist.

### External links

From this `tests` folder, run the script `python validate_external_links.py`.  This file searches all markdown files for external URLs and checks for a 200 status code using the `requests` library.

*That's all folks!*
