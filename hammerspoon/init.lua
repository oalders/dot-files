local my_hotkeys = {"shift", "cmd"}
hyper = {"ctrl", "alt", "cmd", "shift"}

open_app_action = function(name)
    return function()
        hs.application.launchOrFocus(name)
    end
end

applescript_action = function(script)
    return function()
        hs.osascript.applescript(script)
    end
end

function chrome_tab_action( url_substring, url_to_visit_if_tab_not_found )
    return applescript_action([[

      tell application "Google Chrome"
          activate

          set foundWindow to false
          set theTabIndex to -1

          repeat with theWindow in every window
              set theTabIndex to 0
              repeat with theTab in every tab of theWindow
                  set theTabIndex to theTabIndex + 1
                  if theTab's URL contains "]] .. url_substring .. [[" then
                      set foundWindow to theWindow
                      set foundTabIndex to theTabIndex
                  end if
              end repeat
          end repeat

          if foundWindow is not false then
              set foundWindow's active tab index to foundTabIndex
              set index of foundWindow to 1
          else
              open location "]] .. url_to_visit_if_tab_not_found .. [["
          end if

      end tell

    ]])
end

hs.hotkey.bind(my_hotkeys, "r", function()
  hs.reload()
  hs.notify.new({title="Hammerspoon", informativeText="config reloaded"}):send()
end)

function currentSelection()
   local elem=hs.uielement.focusedElement()
   local sel=nil
   if elem then
      sel=elem:selectedText()
   end
   if (not sel) or (sel == "") then
      hs.eventtap.keyStroke({"cmd"}, "c")
      hs.timer.usleep(20000)
      sel=hs.pasteboard.getContents()
   end
   return (sel or "")
end

-- Transform names via an inexact, but hopefully readable, substitution of
-- Greek letters. This allows me to use names in Slack without highlighting the
-- person in question.
-- Borrowed from https://nikhilism.com/post/2021/useful-hammerspoon-tips/
function slackifyName()
    name = currentSelection()
    greek = {
        a = "α",
        b = "β",
        d = "δ",
        D = "Δ",
        e = "ε",
        f = "φ",
        F = "Φ",
        --g = "γ",
        G = "Γ",
        i = "ι",
        k = "κ",
        l = "λ",
        m = "μ",
        n = "ν",
        O = "Ω",
        o = "ω",
        P = "Π",
        p = "π",
        ph = "φ",
        t = "τ",
        th = "θ",
        v = "φ",
    }
    for key, value in pairs(greek) do
        name = name:gsub(key, value)
    end

    replaceIt(name)
end

function cpanAuthorLink()
    name = currentSelection()
    name = string.format("[%s](https://metacpan.org/author/%s)", name, name)
    replaceIt(name)
end

function cpanDocumentationLink()
    name = currentSelection()
    name = string.format("[%s](https://metacpan.org/pod/%s)", name, name)
    replaceIt(name)
end

function replaceIt(thing)
    hs.pasteboard.setContents(thing)
    hs.timer.usleep(20000)
    hs.eventtap.keyStroke({"cmd"}, "v")
end

function xpasswd()
    local output, status, type, rc = hs.execute("xpasswd", true)
    if rc == 0 then
        replaceIt(output)
    else
        hs.notify.new({title="Hammerspoon", informativeText="xpasswd failed"}):send()
    end
end

hs.loadSpoon('SpoonInstall')
spoon.SpoonInstall.use_syncinstall = true
Install=spoon.SpoonInstall

spoon.SpoonInstall:andUse('BingDaily')
spoon.SpoonInstall:andUse('CircleClock')

hs.hotkey.bind(my_hotkeys, 'a', cpanAuthorLink)
hs.hotkey.bind(my_hotkeys, 'b', cpanDocumentationLink)
hs.hotkey.bind(my_hotkeys, 'c', nil, open_app_action('Google Chrome'))
hs.hotkey.bind(my_hotkeys, 'g', nil, chrome_tab_action('mail.google.com/mail/u/0','https://mail.google.com/mail/u/0/#inbox'))
hs.hotkey.bind(my_hotkeys, 'i', nil, open_app_action('wezterm'))
hs.hotkey.bind(my_hotkeys, 'k', xpasswd)
hs.hotkey.bind(my_hotkeys, 'l', nil, open_app_action('Slack'))
hs.hotkey.bind(my_hotkeys, 'm', nil, chrome_tab_action('https://meet.google.com/',''))
hs.hotkey.bind(my_hotkeys, 'n', nil, chrome_tab_action('https://github.com/notifications','https://github.com/notifications'))
hs.hotkey.bind(my_hotkeys, 'o', nil, chrome_tab_action('https://www.irccloud.com/irc/','https://www.irccloud.com/irc/magnet/channel/metacpan'))
hs.hotkey.bind(my_hotkeys, 'p', nil, chrome_tab_action('https://www.pivotaltracker.com/','https://www.pivotaltracker.com/'))
hs.hotkey.bind(my_hotkeys, 'q', slackifyName)
