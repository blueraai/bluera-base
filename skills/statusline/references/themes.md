# Statusline Themes

Five built-in themes with consistent indicator mappings.

---

## Theme: default

Standard emoji theme - works in all modern terminals.

```bash
# Status indicators (3-level: good/warn/critical)
STATUS_OK="🟢"
STATUS_WARN="🟡"
STATUS_CRIT="🔴"

# Status indicators (4-level: good/fair/warn/critical)
STATUS_4_OK="🟢"
STATUS_4_FAIR="🔵"
STATUS_4_WARN="🟡"
STATUS_4_CRIT="🔴"

# Module icons
ICON_DIR="📁"
ICON_MODEL="🤖"
ICON_CONTEXT="📊"
ICON_GIT="🌿"
ICON_COST="💰"
ICON_RATE="⚡"
ICON_PROJECT="📦"
ICON_LINES="📝"
ICON_BATTERY="🔋"
ICON_CPU="💻"
ICON_MEM="🧠"
ICON_DOCKER="🐳"
ICON_TIME="🕐"
ICON_CCA="☁️"

# Separators
SEP=" | "
```

---

## Theme: minimal

Geometric shapes - clean and compact.

```bash
STATUS_OK="◦"
STATUS_WARN="○"
STATUS_CRIT="●"
STATUS_4_OK="◦"
STATUS_4_FAIR="◦"
STATUS_4_WARN="○"
STATUS_4_CRIT="●"

ICON_DIR="→"
ICON_MODEL=""
ICON_CONTEXT=""
ICON_GIT="⎇"
ICON_COST="$"
ICON_RATE="~"
ICON_PROJECT=""
ICON_LINES="±"
ICON_BATTERY="◐"
ICON_CPU=""
ICON_MEM=""
ICON_DOCKER="◫"
ICON_TIME=""
ICON_CCA="☁"

SEP=" "
```

---

## Theme: vibrant

Bold, colorful emoji - high visibility.

```bash
STATUS_OK="💚"
STATUS_WARN="💛"
STATUS_CRIT="🧡"
STATUS_4_OK="💚"
STATUS_4_FAIR="💙"
STATUS_4_WARN="💛"
STATUS_4_CRIT="❤️"

ICON_DIR="📂"
ICON_MODEL="🤖"
ICON_CONTEXT="🎯"
ICON_GIT="🔀"
ICON_COST="💵"
ICON_RATE="⚡"
ICON_PROJECT="🚀"
ICON_LINES="✏️"
ICON_BATTERY="🔌"
ICON_CPU="🖥️"
ICON_MEM="💾"
ICON_DOCKER="🐋"
ICON_TIME="⏰"
ICON_CCA="🌐"

SEP=" │ "
```

---

## Theme: monochrome

ASCII only - maximum compatibility.

```bash
STATUS_OK="[OK]"
STATUS_WARN="[~~]"
STATUS_CRIT="[!!]"
STATUS_4_OK="[OK]"
STATUS_4_FAIR="[--]"
STATUS_4_WARN="[~~]"
STATUS_4_CRIT="[!!]"

ICON_DIR="DIR:"
ICON_MODEL=""
ICON_CONTEXT="CTX:"
ICON_GIT="GIT:"
ICON_COST="$"
ICON_RATE="RATE:"
ICON_PROJECT="PRJ:"
ICON_LINES="+/-"
ICON_BATTERY="BAT:"
ICON_CPU="CPU:"
ICON_MEM="MEM:"
ICON_DOCKER="DOCK:"
ICON_TIME=""
ICON_CCA="CCA:"

SEP=" | "
```

---

## Theme: nerd

Nerd Font glyphs - requires [Nerd Fonts](https://www.nerdfonts.com/).

```bash
STATUS_OK=""
STATUS_WARN=""
STATUS_CRIT=""
STATUS_4_OK=""
STATUS_4_FAIR=""
STATUS_4_WARN=""
STATUS_4_CRIT=""

ICON_DIR=""
ICON_MODEL="󰚩"
ICON_CONTEXT=""
ICON_GIT=""
ICON_COST="󰄛"
ICON_RATE=""
ICON_PROJECT=""
ICON_LINES=""
ICON_BATTERY=""
ICON_CPU=""
ICON_MEM=""
ICON_DOCKER=""
ICON_TIME=""
ICON_CCA=""

SEP="  "
```
