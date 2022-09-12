# Elevator.js Extension for Quarto

This extension provides support and shortcode to [Elevator.js](https://github.com/tholman/elevator.js).  
Animations are only available for HTML-based documents.

## Installing

```sh
quarto install extension mcanouil/quarto-elevator
```

This will install the extension under the `_extensions` subdirectory.  
If you're using version control, you will want to check in this directory.

## Using

To add an elevator button, use the `{{< elevator >}}` shortcode. For example:

- Mandatory:
  ``` markdown
  {{< elevator >}}
  ```

- Optional `<text-button>`, `<anchor-target>`, and `<audio=audio.mp3>`:
  ``` markdown
  {{< elevator <text-button> <anchor-target> <audio=audio.mp3> >}}
  ```

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

This is the output of `example.qmd` for [HTML](https://m.canouil.fr/quarto-elevator/).

---

[BossaBossa](_extensions/elevator/BossaBossa.mp3) by Kevin MacLeod | <https://incompetech.com/>.  
Music promoted by <https://www.chosic.com/free-music/all/>.
Creative Commons Creative Commons: By Attribution 3.0 License (<http://creativecommons.org/licenses/by/3.0/>).
