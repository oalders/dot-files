local my_hotkeys = {"shift", "cmd"}

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

hs.hotkey.bind(my_hotkeys, 'c', nil, open_app_action('Google Chrome'))
hs.hotkey.bind(my_hotkeys, 'g', nil, chrome_tab_action('mail.google.com/mail/u/0','https://mail.google.com/mail/u/0/#inbox'))
hs.hotkey.bind(my_hotkeys, 'i', nil, open_app_action('iTerm'))
hs.hotkey.bind(my_hotkeys, 'l', nil, open_app_action('Slack'))
hs.hotkey.bind(my_hotkeys, 'm', nil, chrome_tab_action('https://meet.google.com/',''))
hs.hotkey.bind(my_hotkeys, 'o', nil, chrome_tab_action('https://www.irccloud.com/irc/','https://www.irccloud.com/irc/magnet/channel/metacpan'))
hs.hotkey.bind(my_hotkeys, 'p', nil, chrome_tab_action('https://www.pivotaltracker.com/','https://www.pivotaltracker.com/'))
