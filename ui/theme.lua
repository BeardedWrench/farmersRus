local Theme = {}

Theme.font = 'assets/fonts/lucon.ttf'

Theme.palette = {
  background = { 0.12, 0.14, 0.18, 0.9 },
  panel = { 0.18, 0.2, 0.25, 0.94 },
  hudPanel = { 0.1, 0.11, 0.15, 0.92 },
  inventoryPanel = { 0.12, 0.13, 0.18, 0.94 },
  outline = { 1, 1, 1, 0.12 },
  outlineStrong = { 1, 1, 1, 0.18 },
  slotBackground = { 0.2, 0.21, 0.27, 0.92 },
  slotOutline = { 1, 1, 1, 0.1 },
  text = { 0.92, 0.94, 1.0, 1 },
  mutedText = { 0.7, 0.72, 0.78, 1 },
  accent = { 0.7, 0.85, 0.6, 1 },
  warning = { 0.95, 0.6, 0.45, 1 },
  success = { 0.4, 0.8, 0.5, 1 }
}

Theme.layout = {
  margin = 24,
  hud = {
    minWidth = 360,
    minHeight = 176,
    padding = { top = 22, right = 24, bottom = 20, left = 24 },
    lineSpacing = 8,
    textScale = 0.58
  },
  inventory = {
    minWidth = 460,
    minHeight = 400,
    padding = { top = 26, right = 26, bottom = 26, left = 26 },
    titleScale = 0.72,
    walletScale = 0.54,
    headerSpacing = 16,
    bodySpacing = 18,
    walletSpacing = 16,
    grid = {
      columns = 4,
      slotSize = 72,
      spacing = 16,
      textScale = 0.45,
      iconPadding = 10
    }
  }
}

Theme.radius = 12
Theme.padding = 8

return Theme
