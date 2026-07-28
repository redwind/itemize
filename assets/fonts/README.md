# Fonts bundled for PDF reports

`Roboto-Regular.ttf` and `Roboto-Bold.ttf`, version 2.137, Copyright 2011 Google
Inc., licensed under the Apache License 2.0:
<https://www.apache.org/licenses/LICENSE-2.0>

## Why these are here

PDF's built-in Helvetica has no Unicode support. Without an embedded font the
report silently drops any character outside Latin-1 — which is every Vietnamese
item name, and the `₫` symbol the app offers as a currency. Roboto was picked
because it covers Vietnamese, French and German in full, carries `€ £ ¥ ₫`, and
is 168 KB per weight rather than the 2 MB a Noto variable font would add.

They are loaded by `lib/core/utils/pdf_service.dart`, not by the app's own
theme; Flutter already renders Vietnamese correctly on screen.
