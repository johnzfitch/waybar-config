# Waybar Notes

## Module Spacing

**To add spacing/padding around waybar module icons:** Add literal spaces in the `format` string, not CSS margins/padding.

CSS margins and padding on modules are often ignored or constrained by waybar's GTK layout algorithm. The reliable solution is to add spaces directly in the format string:

```json
// Instead of trying CSS:
"custom/mymodule": {
  "format": "󰌋"  // cramped
}

// Do this:
"custom/mymodule": {
  "format": "  󰌋  "  // spaces around icon
}
```

This works because the spaces become part of the rendered text content, forcing the module container to be wider.
