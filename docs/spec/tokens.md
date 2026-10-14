# Token fields and search tokens

IDs: CT-TF-05, CT-TF-06, MU-62, MU-70.

## Token field (CT-TF-06)

- Gallery: 220 × 22 field with tokens drawn as light-blue rounded rectangles (about `#c6d9f8`).
- Tag field in a save card: 232 × 27.
- Tag tokens in a popover field are **capsules 14 pt tall** in the tag colour (green tag: sRGB
  `#8adc98` light, `#31b54f` dark).
- Typing filters the list of known tags and completes the first match **inline** (the rest of
  the name selected); Return turns the text into a token; Esc cancels the edit. A name that does
  not exist yet offers to create it, with a row of colour choices (none plus seven).
- Deleting: the first backspace selects the last token, the second removes it (silica_ui
  behaviour; the reference was not tested on this point).

## Search token (CT-TF-05)

- About 15 pt tall, two parts: a label in small capitals with a down chevron, then the value on a
  lighter background.
- Label background `#bbbbbb` light, `#8f8f8f` dark.
- The label opens a small menu that changes what the token matches (for example "file name" or
  "everything").
- Gallery search field with tokens: 200 × 22.
- silica_ui's token height (15) and value colour are partly *provisional*.
