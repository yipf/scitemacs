
# scitemacs - A scite version  by YIPF.

## Features: 
 - Smart tab: expanding snippet, path, fold according to context around the cursor. 
 - Smart selectors including: word, quoted, braced, line, paragraph, folding
 - A smart recommending system based bayes theory which support incremental learning which make it can evolve itself by analyzing contents.
 - Interactive spell checking and dictionary any where.
 - Key sequence support like `Ctrl+A a s p ...'
 - Basic mini-buffer simulator based on the output pane.
 - Small size (with less than 200 lines in core and less than 500 lines in whole project) while without no extern dependencies.
 - Clean and easy to extend code with high readability.
 - Sub mode including `bibtex' ...
 
## Dependencies:
 Scite 3.7.0+

## Install:
  1. Clone this project by git or zip.
  2. Open Scite, goto the menu: Options>Open User Option File, copy the content of `/path/to/scitemacs/.SciTEUser.properties' to it and save.
  2. Goto the menu: Options>Open Lua Startup Script, replace all content by `dofile("/path/to/scitemacs/init.lua")', save.
  4. Restart Scite and Enjoy.

## Usage:
  - `Tab' to expanding snippet, path, or fold at current cursor.
  - `Ctrl+Enter' input existing content in current document.
  - `Alt+x' to select something, press `?' to see help and `x' to exit selection.
  - `Alt+c' to list candidators according to current word and `Ctrl+Alt+c' to learn content in current selection.
  - `Alt+s' to perform spell check with current word and `Ctrl+Alt+s' to find out spell mistakes and refine then one by one.
  - `Alt+d' to search current word in dictionary and show result in ouput pane.
  - ...

## Todo
  - Documentation for sub modes.
  - More sub modes like org-mode, markdown mode, ...