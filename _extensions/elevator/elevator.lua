--- @module "elevator"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Load modules
local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
local html_mod = require(quarto.utils.resolve_path('_modules/html.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))

--- Extension name used as a prefix for log messages.
--- @type string
local EXTENSION = 'elevator'

--- Default end-of-scroll audio file shipped with the extension.
--- @type string
local DEFAULT_END_AUDIO = 'ding.mp3'

--- Built-in named sound aliases mapped to their bundled audio paths.
--- Keys are user-facing names; values are filenames bundled with the extension.
--- @type table<string, string>
local NAMED_SOUNDS = {
  ding = 'ding.mp3',
}

--- Module-level guard preventing the default audio resource from being added
--- more than once per Quarto render (one process can host several shortcodes).
--- @type boolean
local default_audio_registered = false

--- Module-level guard ensuring the missing-default warning fires at most once
--- per Quarto render to avoid log spam when the shortcode is used repeatedly.
--- @type boolean
local missing_default_warned = false

--- Parse a value into a boolean.
--- Accepts native booleans plus the case-insensitive strings `true`, `yes`,
--- `1`, `on` (truthy) and `false`, `no`, `0`, `off` (falsy).
--- @param value any The value to parse
--- @param default boolean Fallback when the value is missing or unrecognised
--- @return boolean
local function parse_boolean(value, default)
  if value == nil then return default end
  if type(value) == 'boolean' then return value end
  local text = str.stringify(value)
  if str.is_empty(text) then return default end
  text = text:lower()
  if text == 'true' or text == 'yes' or text == '1' or text == 'on' then
    return true
  end
  if text == 'false' or text == 'no' or text == '0' or text == 'off' then
    return false
  end
  return default
end

--- Resolve an audio reference, expanding built-in named sounds to their
--- bundled filenames. Empty input returns an empty string.
--- @param reference string The raw audio value supplied by the user
--- @return string Resolved audio path (possibly the original value)
local function resolve_audio(reference)
  if str.is_empty(reference) then return '' end
  local key = reference:lower()
  local bundled = NAMED_SOUNDS[key]
  if bundled then
    quarto.doc.add_format_resource(bundled)
    return bundled
  end
  return reference
end

--- Validate and clamp a volume value to the range supported by HTMLAudioElement.
--- Emits a warning when the input is non-numeric or out of bounds.
--- @param raw_value string The raw user input
--- @return number|nil Clamped volume in [0.0, 1.0] or nil when not supplied
local function parse_volume(raw_value)
  if str.is_empty(raw_value) then return nil end
  local number = tonumber(raw_value)
  if not number then
    log.log_warning(EXTENSION, "Ignoring non-numeric volume '" .. raw_value .. "'.")
    return nil
  end
  if number < 0 or number > 1 then
    log.log_warning(
      EXTENSION,
      "Volume '" .. raw_value .. "' out of range [0.0, 1.0]; clamping."
    )
    if number < 0 then number = 0 end
    if number > 1 then number = 1 end
  end
  return number
end

--- Determine whether the document opts out of the elevator entirely via the
--- `extensions.elevator.enabled: false` metadata flag.
--- @param meta table|nil The document metadata passed by Quarto
--- @return boolean True when the shortcode should render nothing
local function is_globally_disabled(meta)
  if type(meta) ~= 'table' then return false end
  local ext = meta.extensions
  if type(ext) ~= 'table' then return false end
  local elevator_meta = ext.elevator
  if type(elevator_meta) ~= 'table' or elevator_meta.enabled == nil then
    return false
  end
  return not parse_boolean(elevator_meta.enabled, true)
end

--- Warn (once per render) when the default `ding.mp3` resource cannot be
--- located alongside this Lua filter. Returns the resolved path on success.
--- @return string|nil The resolved path to the default audio, or nil when missing
local function ensure_default_audio()
  local resolved = quarto.utils.resolve_path(DEFAULT_END_AUDIO)
  -- `resolve_path` returns a path even when the file does not exist, so probe
  -- the filesystem to confirm the resource ships with the extension.
  local handle = io.open(resolved, 'rb')
  if handle then
    handle:close()
    return resolved
  end
  if not missing_default_warned then
    log.log_warning(
      EXTENSION,
      "Default audio '" .. DEFAULT_END_AUDIO ..
      "' was not found alongside the extension; no end-of-scroll sound will play."
    )
    missing_default_warned = true
  end
  return nil
end

--- Build the JavaScript snippet wiring one DOM selector to an Elevator
--- instance.
--- All option fragments are passed pre-serialised so the caller controls
--- escaping; this helper only stitches the pieces together.
--- Each block is wrapped in its own IIFE so the local `instance` variable does
--- not collide with sibling blocks (`var` is function-scoped in JS).
--- @param config table Fields:
---   selector_js (string): JavaScript expression returning the element.
---   target_js (string): `targetElement: ...,` snippet (may be empty).
---   main_audio_js (string): `mainAudio: "...",` snippet (may be empty).
---   end_audio_js (string): `endAudio: "...",` snippet (may be empty).
---   loop_audio_js (string): `loopAudio: true|false,` snippet (may be empty).
---   volume_pre_js (string): `window.Audio` wrap installed before construction.
---   volume_post_js (string): `window.Audio` restore installed after construction.
---   shortcut_js (string): Keyboard-shortcut wiring (may be empty).
---   pre_init_js (string|nil): Extra JS run after the element is found, before construction.
---   missing_label (string|nil): Label for the `not found` console log; when nil, the else branch is omitted.
--- @return string A JavaScript block ready to embed inside a `<script>` tag.
local function build_wiring(config)
  local else_branch = ''
  if config.missing_label then
    else_branch =
      '  } else {' ..
      '    console.log("Elevator: ' .. config.missing_label .. ' not found");'
  end
  return
    '(function () {' ..
    '  var el = ' .. config.selector_js .. ';' ..
    '  if (el) {' ..
    (config.pre_init_js or '') ..
    config.volume_pre_js ..
    '    var instance = new Elevator({' ..
    '      element: el,' ..
    config.target_js ..
    config.main_audio_js ..
    config.end_audio_js ..
    config.loop_audio_js ..
    '    });' ..
    config.volume_post_js ..
    config.shortcut_js ..
    else_branch ..
    '  }' ..
    '})();'
end

--- Elevator shortcode handler.
--- Creates a button that scrolls smoothly to the top of the page (or a target
--- element) with optional elevator music sound effects. Also enhances Quarto's
--- back-to-top button when `back-to-top-navigation: true` is set.
---
--- @param args table Positional arguments (button text, optional target id)
--- @param kwargs table Named arguments
--- @param meta table Document metadata (used for the global disable flag)
--- @return pandoc.RawInline|pandoc.Null HTML button or Null for non-HTML formats
--- @usage {{< elevator >}}
--- @usage {{< elevator "Back to top" >}}
--- @usage {{< elevator "Go up" "header" audio="music.mp3" end="ding.mp3" volume=0.5 loop-audio=false shortcut="t" >}}
local function elevator(args, kwargs, meta)
  if not quarto.doc.is_format('html:js') then
    return pandoc.Null()
  end

  if is_globally_disabled(meta) then
    return pandoc.Null()
  end

  html_mod.ensure_html_dependency({
    name = 'elevatorjs',
    version = '1.0.0',
    scripts = { 'elevator.min.js' }
  })

  --- @type string Text to display on the button
  local text_button = 'Return to the top!'
  --- @type string JavaScript snippet selecting the target element (if any)
  local target_anchor_js = ''
  if #args > 0 then
    text_button = str.stringify(args[1])
    if #args > 1 then
      local target_id = str.stringify(args[2])
      target_anchor_js =
        '      targetElement: document.querySelector("#' ..
        str.escape_js_string(target_id) .. '"),'
    end
  end

  --- @type string Resolved path to the main audio file (played while scrolling)
  local main_audio = resolve_audio(str.stringify(kwargs['audio']))

  --- @type string Resolved path to the end audio file (played at completion)
  local end_audio_raw = str.stringify(kwargs['end'])
  local end_audio
  if str.is_empty(end_audio_raw) then
    end_audio = DEFAULT_END_AUDIO
    if not default_audio_registered then
      ensure_default_audio()
      quarto.doc.add_format_resource(end_audio)
      default_audio_registered = true
    end
  else
    end_audio = resolve_audio(end_audio_raw)
  end

  --- @type number|nil Audio playback volume in [0.0, 1.0]
  local volume = parse_volume(str.stringify(kwargs['volume']))

  --- @type boolean Whether the main audio loops while scrolling
  local loop_audio = parse_boolean(kwargs['loop-audio'], true)

  --- @type string Optional keyboard key that triggers the elevator
  local shortcut = str.stringify(kwargs['shortcut'])

  local main_audio_js = ''
  if not str.is_empty(main_audio) then
    main_audio_js = '      mainAudio: "' .. str.escape_js_string(main_audio) .. '",'
  end

  local end_audio_js = ''
  if not str.is_empty(end_audio) then
    end_audio_js = '      endAudio: "' .. str.escape_js_string(end_audio) .. '",'
  end

  local loop_audio_js = '      loopAudio: ' .. tostring(loop_audio) .. ','

  -- Elevator.js holds its `Audio` instances in private closure variables and
  -- internally calls `audio.setAttribute('loop', loopAudio)`. Because `loop`
  -- is a boolean HTML attribute, setting it to the literal string `"false"`
  -- still enables looping; volume cannot be tweaked from outside either.
  -- The wrappers below temporarily replace `window.Audio` so each newly built
  -- instance gets the requested `volume` and a real `loop = false` when
  -- needed, then restore the original constructor straight after `new
  -- Elevator`. The saved-original handle lives on `window` so the
  -- custom-button and back-to-top blocks can share one restore step.
  local volume_pre_js = ''
  local volume_post_js = ''
  if volume ~= nil or loop_audio == false then
    local body = '      var a = new window.__elevatorOrigAudio(src);'
    if volume ~= nil then
      body = body .. '      a.volume = ' .. tostring(volume) .. ';'
    end
    if loop_audio == false then
      body = body ..
        '      var origSetAttribute = a.setAttribute.bind(a);' ..
        '      a.setAttribute = function(name, value) {' ..
        '        if (name === "loop") { a.loop = (value === true || value === "true"); return; }' ..
        '        origSetAttribute(name, value);' ..
        '      };'
    end
    body = body .. '      return a;'
    volume_pre_js =
      '    window.__elevatorOrigAudio = window.__elevatorOrigAudio || window.Audio;' ..
      '    window.Audio = function(src) {' ..
      body ..
      '    };'
    volume_post_js = '    window.Audio = window.__elevatorOrigAudio;'
  end

  local shortcut_js = ''
  if not str.is_empty(shortcut) then
    local shortcut_key = str.escape_js_string(shortcut)
    shortcut_js =
      '    document.addEventListener("keydown", function(ev) {' ..
      '      var target = ev.target;' ..
      '      var tag = target && target.tagName ? target.tagName.toUpperCase() : "";' ..
      '      var editable = target && target.isContentEditable;' ..
      '      if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" || editable) { return; }' ..
      '      if (ev.key === "' .. shortcut_key .. '") {' ..
      '        ev.preventDefault();' ..
      '        instance.elevate();' ..
      '      }' ..
      '    });'
  end

  local shared_options = {
    target_js = target_anchor_js,
    main_audio_js = main_audio_js,
    end_audio_js = end_audio_js,
    loop_audio_js = loop_audio_js,
    volume_pre_js = volume_pre_js,
    volume_post_js = volume_post_js,
    shortcut_js = shortcut_js,
  }

  local custom_wiring = build_wiring(setmetatable({
    selector_js = 'document.querySelector(".elevator-button")',
    missing_label = 'Custom button',
  }, { __index = shared_options }))

  local quarto_wiring = build_wiring(setmetatable({
    selector_js = 'document.querySelector("#quarto-back-to-top")',
    pre_init_js = '    el.removeAttribute("onclick");    el.onclick = null;',
  }, { __index = shared_options }))

  local init_script =
    'window.addEventListener("load", function() {' ..
    custom_wiring ..
    quarto_wiring ..
    '});'

  quarto.doc.include_text('after-body', '<script>' .. init_script .. '</script>')

  return pandoc.RawInline(
    'html',
    '<button class="btn btn-outline-primary elevator-button" type="submit">' ..
    str.escape_html(text_button) ..
    '</button>'
  )
end

--- Module export table.
--- Defines the shortcode available to Quarto for elevator scroll-to-top functionality.
--- @type table<string, function>
return {
  ['elevator'] = elevator
}
