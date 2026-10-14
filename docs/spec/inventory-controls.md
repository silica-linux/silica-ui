# Controls inventory

Every interface control of the reference inventory (CT IDs) with its state in silica_ui.

Status:

- **done**: implemented with the measured values.
- **provisional**: implemented; some values are estimates (marked in the code and in the linked
  spec page).
- **partial**: implemented in part, or the reference itself is only partly measured.
- **missing**: not in silica_ui yet.
- **app** / **shell** / **compositor**: lives outside silica_ui (in an app, the shell or Ossido).

## Buttons

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-BTN-01 | Push button, normal | `SilicaButton` | done | [buttons](buttons.md#push-buttons-ct-btn-01-02-03) |
| CT-BTN-02 | Push button, default (accent) | `SilicaButton(role: primary)` | done | [buttons](buttons.md#push-buttons-ct-btn-01-02-03) |
| CT-BTN-03 | Push button sizes (large, regular, small, mini) | `SilicaButton(size:)` | done | [buttons](buttons.md#push-buttons-ct-btn-01-02-03) |
| CT-BTN-04 | Bevel and small square buttons | `ButtonBezel.bevel` | provisional | [buttons](buttons.md#bevel-and-square-buttons-ct-btn-04) |
| CT-BTN-05 | Help button | `HelpButton` | done | [buttons](buttons.md#help-button-ct-btn-05) |
| CT-BTN-06 | Disclosure triangle | `DisclosureTriangle` | done | [buttons](buttons.md#disclosure-ct-btn-06-07) |
| CT-BTN-07 | Disclosure button | `DisclosureButton` | provisional (corner radius) | [buttons](buttons.md#disclosure-ct-btn-06-07) |
| CT-BTN-08 | Image button | `ImageButton` | done | [buttons](buttons.md#image-buttons-ct-btn-08) |
| CT-BTN-09 | Toggle button | `ToggleButton` | done | [buttons](buttons.md#toggle-buttons-ct-btn-09) |
| CT-BTN-10 | Calculator key | — | app | — |
| CT-BTN-11 | Toolbar capsule button | `ToolbarCapsule`, `ToolbarSegment` | done | [toolbar](toolbar.md#control-states-ct-btn-11-ct-seg-01) |
| CT-BTN-12 | Toolbar text button and overflow menu | — | app | [toolbar](toolbar.md#narrowing-mu-02) |
| CT-BTN-13 | Window buttons (close, minimize, zoom) | — | compositor | — |
| CT-BTN-14 | Round glass button | — | missing | [buttons](buttons.md#round-and-coloured-buttons-ct-btn-14-15) |
| CT-BTN-15 | Coloured capsule buttons (stopwatch) | — | app | [buttons](buttons.md#round-and-coloured-buttons-ct-btn-14-15) |
| CT-BTN-16 | Pop-up button | `PopUpButton` | provisional | [menus](menus.md#pop-up-button-and-pop-up-menu-ct-btn-16-ct-mn-03) |
| CT-BTN-17 | Pull-down button | `PullDownButton` | provisional | [menus](menus.md#pull-down-button-ct-btn-17) |
| CT-BTN-18 | Combo box | `ComboBox` | provisional | [menus](menus.md#combo-box-ct-btn-18) |
| CT-BTN-19 | In-app tip with close button | (`PopoverPanel`) | partial | [popovers](popovers.md) |

## Segmented controls

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-SEG-01 | Toolbar segmented group | `ToolbarSegment` | done | [toolbar](toolbar.md#control-states-ct-btn-11-ct-seg-01) |
| CT-SEG-02 | Section switch in a toolbar | `SegmentedControl` | partial (no collapse into a pop-up) | [segmented](segmented.md#section-switch-in-a-toolbar-ct-seg-02) |
| CT-SEG-03 | Small segmented control in content | `SegmentedControl` | partial | [segmented](segmented.md#small-segmented-controls-in-content-ct-seg-03-partial) |
| CT-SEG-04 | Scope pills | — | app | [segmented](segmented.md#scope-pills-ct-seg-04-partial) |
| CT-SEG-05 | Segmented control (all styles) | `SegmentedControl` | done | [segmented](segmented.md#standard-segmented-control-ct-seg-05) |

## Switches, checkboxes, radios

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-SW-01 | Switch | `SilicaSwitch` | provisional (knob animation and stretch) | [toggles](toggles.md#switch-ct-sw-01-02-03) |
| CT-SW-02 | Switch sizes | `SilicaSwitch(size:)` | done | [toggles](toggles.md#switch-ct-sw-01-02-03) |
| CT-SW-03 | Switch in Settings rows | `SilicaSwitch(size: mini)` | partial | [toggles](toggles.md#switch-ct-sw-01-02-03) |
| CT-CB-01 | Checkbox off / on / mixed | `SilicaCheckbox` | done | [toggles](toggles.md#checkbox-ct-cb-01-02) |
| CT-CB-02 | Checkbox states | `SilicaCheckbox` | done | [toggles](toggles.md#checkbox-ct-cb-01-02) |
| CT-RB-01 | Radio button | `SilicaRadio`, `SilicaRadioGroup` | done | [toggles](toggles.md#radio-button-ct-rb-01) |

## Sliders, steppers

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-SL-01 | Slider on glass | `SilicaSlider` | done | [sliders](sliders.md#linear-slider-ct-sl-01-02-03) |
| CT-SL-02 | Small slider | `SilicaSlider(size: small)` | done | [sliders](sliders.md#linear-slider-ct-sl-01-02-03) |
| CT-SL-03 | Regular slider | `SilicaSlider` | done | [sliders](sliders.md#linear-slider-ct-sl-01-02-03) |
| CT-SL-04 | Slider with tick marks | `SilicaSlider(ticks:)` | provisional | [sliders](sliders.md#slider-with-tick-marks-ct-sl-04) |
| CT-SL-05 | Circular slider | `SilicaCircularSlider` | provisional (indicator dot) | [sliders](sliders.md#circular-slider-ct-sl-05) |
| CT-SL-06 | Timer wheel | — | missing | [sliders](sliders.md#timer-wheel-ct-sl-06-partial) |
| CT-SL-07 | Stepper | `SilicaStepper` | provisional (radius, pressed halves, repeat timing) | [sliders](sliders.md#stepper-ct-sl-07-partial) |

## Text input

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-TF-01 | Text field | `SilicaTextField` | done | [fields](fields.md#text-field-ct-tf-01) |
| CT-TF-02 | Secure field | `SilicaTextField(secure: true)` | provisional | [fields](fields.md#secure-field-ct-tf-02) |
| CT-TF-03 | Search panel field | — | shell | [fields](fields.md#search-field-ct-tf-04-mu-70-mu-96) |
| CT-TF-04 | Search field | `SilicaSearchField` | done | [fields](fields.md#search-field-ct-tf-04-mu-70-mu-96) |
| CT-TF-05 | Search field with tokens | `SearchToken`, `SearchTokenChip` | provisional | [tokens](tokens.md#search-token-ct-tf-05) |
| CT-TF-06 | Token field | `SilicaTokenField` | provisional | [tokens](tokens.md#token-field-ct-tf-06) |
| CT-TF-07 | Multi-line text area | `SilicaTextField(maxLines:)` | provisional | [fields](fields.md#multi-line-text-area-ct-tf-07-partial) |
| CT-TF-08 | Inline rename field | — | app | [fields](fields.md#inline-rename-field-ct-tf-08) |
| CT-TF-09 | Focus ring | `FocusRing` | done | [focus and accent](focus-and-accent.md#focus-ring-ct-tf-09-mu-10-mu-32) |

## Pickers

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-DP-01 | Time field with parts | `SilicaDateField` | provisional | [pickers](pickers.md#time-field-with-parts-ct-dp-01-partial) |
| CT-DP-02 | Date picker (text, stepper, calendar) | `SilicaDateField`, `SilicaCalendar` | provisional (calendar cell size, square gray) |
 [pickers](pickers.md#date-picker-ct-dp-02) |
| CT-DP-03 | Colour well | `SilicaColorWell` | done | [pickers](pickers.md#colour-well-ct-dp-03) |
| CT-DP-04 | Colour panel | `SilicaColorPicker` | provisional | [pickers](pickers.md#colour-panel-ct-dp-04-partial) |
| CT-DP-05 | Unit picker popover | — | missing | [pickers](pickers.md#unit-picker-popover-ct-dp-05-partial) |

## Indicators

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-LV-01 | Level indicator | `SilicaLevelIndicator` | done (warning and critical colours provisional) | [indicators](indicators.md#level-indicator-ct-lv-01) |
| CT-PR-01 | Progress bar | `SilicaProgressBar` | done | [indicators](indicators.md#progress-bar-determinate-ct-pr-01) |
| CT-PR-02 | Indeterminate progress bar | `SilicaProgressBar(value: null)` | provisional | [indicators](indicators.md#progress-bar-indeterminate-ct-pr-02-partial) |
| CT-PR-03 | Spinner | `SilicaSpinner` | done (speed provisional) | [indicators](indicators.md#spinner-ct-pr-03) |
| CT-PR-04 | Circular progress ring | `SilicaProgressRing` | provisional | [indicators](indicators.md#circular-progress-ring-ct-pr-04-partial) |

## Lists and containers

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-TB-01 | Table with column headers | `TableView` | done | [lists](lists.md#table-with-column-headers-ct-tb-01) |
| CT-TB-02 | Outline view | `TableView` + `OutlineDelegate` | done | [lists](lists.md#outline-view-ct-tb-02) |
| CT-TB-03 | Collection view | `CollectionView` | done | [lists](lists.md#collection-view-ct-tb-03) |
| CT-TB-04 | Column view and gallery | — | app | — |
| CT-TB-05 | Grouped inset list | — | missing | [lists](lists.md#grouped-inset-list-ct-tb-05) |
| CT-SB-01 | Sidebar (source list) | `SourceList` | done | [lists](lists.md#sidebar--source-list-ct-sb-01) |
| CT-TV-01 | Window tab bar | `WindowTabBar` | done | [split and tabs](split-and-tabs.md#window-tab-bar-ct-tv-01) |
| CT-TV-02 | Tab view | `SilicaTabView` | provisional | [split and tabs](split-and-tabs.md#tab-view-ct-tv-02) |
| CT-SP-01 | Split view and divider | `SplitView` | partial | [split and tabs](split-and-tabs.md#split-view-ct-sp-01) |

## Popovers, sheets, alerts, panels

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-PO-01 | Popover, tip toward the anchor below | `PopoverAnchor`, `PopoverPanel` | done (TIP-01 outline) | [popovers](popovers.md) |
| CT-PO-02 | Popover, tip above | `PopoverPanel` | provisional | [popovers](popovers.md) |
| CT-PO-03 | Popover, tip left / right | `PopoverPanel` | done (TIP-01 outline) | [popovers](popovers.md#tip-outline-tip-01) |
| CT-PO-04 | Popover with a list | `PopoverPanel` | provisional | [popovers](popovers.md) |
| CT-SH-01 | Sheet attached to the toolbar | `showWindowSheet(style: attached)` | partial | [sheets and panels](sheets-and-panels.md#sheet-attached-to-the-toolbar-ct-sh-01-ct-tl-02) |
| CT-SH-02 | Compact card | `showWindowSheet(style: card)` | done | [sheets and panels](sheets-and-panels.md#compact-card-ct-sh-02) |
| CT-AL-01 | Alert | `SilicaAlert` | done | [alerts](alerts.md#modal-alert-with-a-header-ct-al-01) |
| CT-AL-02 | Alert with icon, checkbox, three buttons | `SilicaAlert` | partial | [alerts](alerts.md) |
| CT-PN-01 | Utility panel | `FloatingPanel` | provisional | [sheets and panels](sheets-and-panels.md#panels-ct-pn-01-ct-pn-03) |
| CT-PN-02 | Floating small panel (emoji) | — | missing | [sheets and panels](sheets-and-panels.md#panels-ct-pn-01-ct-pn-03) |
| CT-PN-03 | Open / save panel | — | missing | [sheets and panels](sheets-and-panels.md#panels-ct-pn-01-ct-pn-03) |

## Menus, toolbars, tooltips, scrollers, paths

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-MN-01 | Menu | `MenuHost`, `MenuPanel` | done | [menus](menus.md) |
| CT-MN-02 | Context menu | `MenuHost` | done | [menus](menus.md#context-menus-ct-mn-02) |
| CT-MN-03 | Pop-up menu with the checked item over the button | `PopUpButton` | partial | [menus](menus.md#pop-up-button-and-pop-up-menu-ct-btn-16-ct-mn-03) |
| CT-MN-04 | Menu with a section title | `MenuSection` | done | [menus](menus.md#menu-with-a-section-title-ct-mn-04-partial) |
| CT-TL-01 | Toolbar | `ToolbarCapsule`, `ToolbarScope` | done | [toolbar](toolbar.md) |
| CT-TL-02 | Customize-toolbar sheet | `ToolbarCustomizeSheet` | partial | [sheets and panels](sheets-and-panels.md#sheet-attached-to-the-toolbar-ct-sh-01-ct-tl-02) |
| CT-TL-03 | Veil under the toolbar | `ScrollUnderToolbar` | done | [toolbar](toolbar.md#the-veil-over-scrolling-content-ct-tl-03-r19) |
| CT-TT-01 | Tooltip | `SilicaTooltip` | provisional | [tooltips](tooltips.md) |
| CT-SC-01 | Overlay scroller | `SilicaScrollbar` | provisional | [scrollers](scrollers.md) |
| CT-SC-02 | Legacy scroller | `SilicaScrollbar(style: legacy)` | provisional | [scrollers](scrollers.md) |
| CT-SC-03 | Scroll elasticity | `SilicaScrollBehavior` | provisional | [scrollers](scrollers.md#not-measured) |
| CT-PA-01 | Path control | `PathControl` | done | — (file manager spec) |
| CT-PA-02 | Path pop-up menu | — | missing | — |
| CT-RE-01 | Rule editor | — | missing | — |

## Colours and appearance

| ID | Control | silica_ui | Status | Spec |
| --- | --- | --- | --- | --- |
| CT-CL-01 | Accent colour per element | `SilicaAccent`, `AccentColors`, `ControlAccent.palette` | done | [focus and accent](focus-and-accent.md#accent-colour-ct-cl-01) |
| CT-CL-02 | Controls in an inactive window | `WindowActiveScope` | done |
 [focus and accent](focus-and-accent.md#state-rules-control-gallery) |
| CT-CL-03 | Increase Contrast / Reduce Transparency | — | missing | [focus and accent](focus-and-accent.md#accessibility-variants-ct-cl-03-partial) |
