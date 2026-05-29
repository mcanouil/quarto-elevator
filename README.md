# Elevator.js Extension for Quarto

This extension provides support and shortcode to [Elevator.js](https://github.com/tholman/elevator.js).

Animation is only available for HTML-based documents.

## Installation

```sh
quarto add mcanouil/quarto-elevator@1.4.0
```

This will install the extension under the `_extensions` subdirectory.

If you're using version control, you will want to check in this directory.

## Usage

To add an elevator button, use the `{{< elevator >}}` shortcode.

### Minimal

```markdown
{{< elevator >}}
```

### Custom text and scroll target

The first positional argument is the button label and the second is the id of an element to scroll to instead of the top of the page.

```markdown
{{< elevator "Back to header" my-header >}}
```

### Audio

`audio` is the looping music played during the scroll and `end` is the sound played once the scroll finishes.

```markdown
{{< elevator audio=music.mp3 end=ding.mp3 >}}
```

The built-in name `ding` resolves to the bundled `ding.mp3`, so `audio=ding` or `end=ding` works without copying the file into your project.

### Volume

`volume` accepts a number in the range [0.0, 1.0]. Out-of-range or non-numeric values are clamped and a warning is emitted at render time.

```markdown
{{< elevator audio=music.mp3 volume=0.5 >}}
```

### Loop control

`loop-audio` defaults to `true` (Elevator.js's own default). Set it to `false` to play the main audio just once. The extension overrides Elevator.js's internal `setAttribute('loop', 'false')` no-op so this option actually disables looping.

```markdown
{{< elevator audio=music.mp3 loop-audio=false >}}
```

### Keyboard shortcut

`shortcut` binds a single key (matched against `KeyboardEvent.key`) that triggers the elevator from anywhere on the page, except when the focus is inside an `<input>`, `<textarea>`, `<select>`, or any `contenteditable` element.

```markdown
{{< elevator audio=music.mp3 shortcut="t" >}}
```

### Global disable

Set `elevator: false` (or `elevator: { enabled: false }`) in the document YAML to suppress every `{{< elevator >}}` shortcode in that document.

```yaml
---
elevator: false
---
```

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

Output of `example.qmd`:

- [HTML](https://m.canouil.dev/quarto-elevator/)

---

[BossaBossa](BossaBossa.mp3) by Kevin MacLeod | <https://incompetech.com/>.
Music promoted by <https://www.chosic.com/free-music/all/>.
Creative Commons Creative Commons: By Attribution 3.0 License (<http://creativecommons.org/licenses/by/3.0/>).

[Elevator.js](https://github.com/tholman/elevator.js) by Tim Holman under MIT License.
