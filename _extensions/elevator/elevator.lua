--- @module elevator
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Load utils module
local utils = require(quarto.utils.resolve_path('_modules/utils.lua'):gsub('%.lua$', ''))

--- Elevator shortcode handler.
--- Creates a button that scrolls smoothly to the top of the page (or a target element)
--- with optional elevator music sound effects.
--- Also enhances Quarto's back-to-top button (when enabled via back-to-top-navigation: true).
---
--- @param args table Array of positional arguments (button text, optional target element ID)
--- @param kwargs table Named arguments (audio: main audio file, end: end audio file)
--- @return pandoc.RawInline|pandoc.Null HTML button with elevator functionality or Null for non-HTML formats
--- @usage {{< elevator >}}
--- @usage {{< elevator "Back to top" >}}
--- @usage {{< elevator "Go up" "header" audio="music.mp3" end="ding.mp3" >}}
local function elevator(args, kwargs)
  if quarto.doc.is_format('html:js') then
    -- Use utils module to ensure HTML dependencies
    utils.ensure_html_dependency({
      name = 'elevatorjs',
      version = '1.0.0',
      scripts = { 'elevator.min.js' }
    })

    --- @type string Text to display on the button
    local textButton = 'Return to the top!'
    --- @type string JavaScript code for target element (if specified)
    local targetAnchor = ''
    if #args > 0 then
      textButton = utils.stringify(args[1])
      if #args > 1 then
        targetAnchor = 'targetElement: document.querySelector("#' .. utils.stringify(args[2]) .. '"), '
      end
    end

    --- @type string Path to main audio file (played during scroll)
    local mainAudio = utils.stringify(kwargs['audio'])
    if utils.is_empty(mainAudio) then
      mainAudio = ''
    end

    --- @type string Path to end audio file (played when scroll completes)
    local endAudio = utils.stringify(kwargs['end'])
    if utils.is_empty(endAudio) then
      endAudio = 'ding.mp3'
      quarto.doc.add_format_resource(endAudio)
    end

    -- Create the initialization script that will run after page load
    local initScript =
      'window.addEventListener("load", function() {' ..
      '  console.log("Elevator: Initializing...");' ..
      '  var elevatorButton = document.querySelector(".elevator-button");' ..
      '  if (elevatorButton) {' ..
      '    console.log("Elevator: Found custom button");' ..
      '    var customElevator = new Elevator({' ..
      '      element: elevatorButton,' ..
      targetAnchor ..
      '      mainAudio: "' .. mainAudio .. '",' ..
      '      endAudio: "' .. endAudio .. '"' ..
      '    });' ..
      '  } else {' ..
      '    console.log("Elevator: Custom button not found");' ..
      '  }' ..
      '  var quartoBackToTop = document.querySelector("#quarto-back-to-top");' ..
      '  if (quartoBackToTop) {' ..
      '    console.log("Elevator: Found Quarto back-to-top button");' ..
      '    quartoBackToTop.removeAttribute("onclick");' ..
      '    quartoBackToTop.onclick = null;' ..
      '    var quartoElevator = new Elevator({' ..
      '      element: quartoBackToTop,' ..
      targetAnchor ..
      '      mainAudio: "' .. mainAudio .. '",' ..
      '      endAudio: "' .. endAudio .. '"' ..
      '    });' ..
      '  } else {' ..
      '    console.log("Elevator: Quarto back-to-top button not found");' ..
      '  }' ..
      '});'

    quarto.doc.include_text('after-body', '<script>' .. initScript .. '</script>')

    return pandoc.RawInline(
      'html',
      '<button class="btn btn-outline-primary elevator-button" type="submit">' .. textButton .. '</button>'
    )
  else
    return pandoc.Null()
  end
end

--- Module export table.
--- Defines the shortcode available to Quarto for elevator scroll-to-top functionality.
--- @type table<string, function>
return {
  ['elevator'] = elevator
}
