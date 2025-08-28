# MDOutline

A NERDTree-like markdown outline viewer for Vim that displays a hierarchical table of contents in a sidebar panel.

## Features

- 📋 **Automatic outline generation** from markdown headers (`#`, `##`, `###`, etc.)
- 🌲 **Hierarchical display** with proper indentation matching header levels  
- ⚡ **Quick navigation** - jump to any header with Enter or double-click
- 🔄 **Auto-refresh** when the markdown file is saved
- ⚙️ **Configurable** sidebar position (left/right) and width
- 🎯 **Simple shortcuts** for toggling and navigation

## Installation

### Using vim-plug
```vim
Plug 'cegme/mdoutline'
```

### Using Vundle
```vim
Plugin 'cegme/mdoutline'
```

### Using Pathogen
```bash
cd ~/.vim/bundle && git clone https://github.com/cegme/mdoutline.git
```

## Usage

MDOutline works automatically when you open markdown files:

1. Open a markdown file (`.md`) 
2. The outline sidebar opens automatically (if `g:mdoutline_auto_open` is enabled)
3. Navigate through headers using arrow keys
4. Press `<Enter>` or double-click to jump to a header
5. Outline refreshes automatically when you save the file

## Commands

| Command | Description |
|---------|-------------|
| `:MDOutlineToggle` | Toggle outline sidebar |
| `:MDOutlineOpen` | Open outline sidebar |
| `:MDOutlineClose` | Close outline sidebar |
| `:MDOutlineRefresh` | Refresh outline content |

## Default Mappings

| Mapping | Action |
|---------|---------|
| `<Leader>mo` | Toggle outline sidebar |

### Within outline window:
| Mapping | Action |
|---------|---------|
| `<Enter>` | Jump to header |
| `<2-LeftMouse>` | Jump to header (double-click) |
| `q` | Close outline window |
| `r` | Refresh outline |

## Configuration

Add these to your `.vimrc`:

```vim
" Sidebar width (default: 30)
let g:mdoutline_width = 40

" Sidebar position: 'left' or 'right' (default: 'left')  
let g:mdoutline_position = 'right'

" Auto-open outline for markdown files (default: 1)
let g:mdoutline_auto_open = 0

" Custom toggle mapping
nmap <Leader>mt :MDOutlineToggle<CR>
```

## Example

When viewing a markdown file like this:
```markdown
# Introduction
Some content here...

## Getting Started
More content...

### Prerequisites
Details...

### Installation
Steps...

## Usage
How to use...

# Other stuff
Here is the other stuff.
```

The outline sidebar will show:
```
Introduction
  Getting Started
    Prerequisites  
    Installation
  Usage
```

## License

MIT License
