local my_hotkeys = { 'shift', 'cmd' }
local hyper = { 'ctrl', 'alt', 'cmd', 'shift' }

local open_app_action = function(name)
    return function()
        hs.application.launchOrFocus(name)
    end
end

local applescript_action = function(script)
    return function()
        hs.osascript.applescript(script)
    end
end

local function chrome_tab_action(url_substring, url_to_visit_if_tab_not_found)
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

local function clean_up_tabs()
    return function()
        return hs.osascript.applescriptFromFile(
            os.getenv('HOME') .. '/dot-files/bin/chrome-tab-cleanup.scpt'
        )
    end
end

hs.hotkey.bind(hyper, 'h', function()
    hs.reload()
    hs.notify
        .new({ title = 'Hammerspoon', informativeText = 'config reloaded' })
        :send()
end)

local function currentSelection()
    local elem = hs.uielement.focusedElement()
    local sel = nil
    if elem then
        sel = elem:selectedText()
    end
    if (not sel) or (sel == '') then
        hs.eventtap.keyStroke({ 'cmd' }, 'c')
        hs.timer.usleep(20000)
        sel = hs.pasteboard.getContents()
    end
    return (sel or '')
end

local function replaceIt(thing)
    hs.pasteboard.setContents(thing)
    hs.timer.usleep(20000)
    hs.eventtap.keyStroke({ 'cmd' }, 'v')
end

-- Transform names via an inexact, but hopefully readable, substitution of
-- Greek letters. This allows me to use names in Slack without highlighting the
-- person in question.
-- Borrowed from https://nikhilism.com/post/2021/useful-hammerspoon-tips/
local function slackifyName()
    local name = currentSelection()
    local greek = {
        a = 'α',
        b = 'β',
        d = 'δ',
        D = 'Δ',
        e = 'ε',
        f = 'φ',
        F = 'Φ',
        --g = "γ",
        G = 'Γ',
        i = 'ι',
        k = 'κ',
        l = 'λ',
        m = 'μ',
        n = 'ν',
        O = 'Ω',
        o = 'ω',
        P = 'Π',
        p = 'π',
        ph = 'φ',
        t = 'τ',
        th = 'θ',
        v = 'φ',
    }
    for key, value in pairs(greek) do
        name = name:gsub(key, value)
    end

    replaceIt(name)
end

local function cpanAuthorLink()
    local name = currentSelection()
    name = string.format('[%s](https://metacpan.org/author/%s)', name, name)
    replaceIt(name)
end

local function cpanDocumentationLink()
    local name = currentSelection()
    name = string.format('[%s](https://metacpan.org/pod/%s)', name, name)
    replaceIt(name)
end

local function xpasswd()
    local output, _, _, rc = hs.execute('xpasswd', true)
    if rc == 0 then
        replaceIt(output)
    else
        hs.notify
            .new({ title = 'Hammerspoon', informativeText = 'xpasswd failed' })
            :send()
    end
end

hs.loadSpoon('SpoonInstall')
spoon.SpoonInstall.use_syncinstall = true
local Install = spoon.SpoonInstall

Install:andUse('BingDaily')
Install:andUse('CircleClock')
Install:andUse('EmmyLua')
Install:andUse('LookupSelection', { hotkeys = { lexicon = { hyper, 'd' } } })
Install:andUse('MicMute', {
    hotkeys = {
        toggle = { hyper, 'm' },
    },
})
Install:andUse('Seal', {
    hotkeys = { show = { hyper, 'space' } },
    fn = function(s)
        s:loadPlugins({
            'apps',
            'calc',
            'screencapture',
            'useractions',
        })
        s.plugins.useractions.actions = {
            ['CPAN Repo'] = {
                keyword = 'cr',
                fn = function(str)
                    local _, _, _, rc = hs.execute('cpan-repo ' .. str, true)
                    if rc ~= 0 then
                        hs.alert.show('CPAN Repo lookup failed')
                    end
                end,
            },
            ['Dad Jokes'] = {
                keyword = 'dj',
                fn = function()
                    local content, _, _, rc =
                        hs.execute('curl https://icanhazdadjoke.com', false)
                    if rc ~= 0 then
                        hs.alert.show('No dad joke for you')
                    else
                        hs.eventtap.keyStrokes(content)
                    end
                end,
            },
            ['Slackify Name'] = {
                keyword = 'sl',
                fn = function(str)
                    slackifyName(str)
                end,
            },
            ['xpasswd'] = {
                keyword = 'xp',
                fn = function()
                    local content, _, _, rc = hs.execute('xpasswd', true)
                    if rc ~= 0 then
                        hs.alert.show('xpasswd failed')
                    else
                        hs.eventtap.keyStrokes(content)
                    end
                end,
            },
        }
        s:refreshAllCommands()
    end,
    start = true,
})

local bellTV = 'https://tv.bell.ca'
local github = 'https://github.com/notifications'
local gmail = 'https://mail.google.com/mail/u/0/'
local ircCloud = 'https://www.irccloud.com/irc/'
local PT = 'https://www.pivotaltracker.com'
local remoteDesktop = 'https://remotedesktop.google.com'

hs.hotkey.bind(my_hotkeys, 'a', cpanAuthorLink)
hs.hotkey.bind(my_hotkeys, 'b', cpanDocumentationLink)
hs.hotkey.bind(my_hotkeys, 'c', nil, open_app_action('Google Chrome'))
hs.hotkey.bind(
    my_hotkeys,
    'g',
    nil,
    chrome_tab_action(gmail, gmail .. '#all')
)
hs.hotkey.bind(my_hotkeys, 'i', nil, open_app_action('wezterm'))
hs.hotkey.bind(my_hotkeys, 'l', nil, open_app_action('Slack'))
hs.hotkey.bind(
    my_hotkeys,
    'm',
    nil,
    chrome_tab_action('https://meet.google.com/', '')
)
hs.hotkey.bind(my_hotkeys, 'n', nil, chrome_tab_action(github, github))
hs.hotkey.bind(
    my_hotkeys,
    'o',
    nil,
    chrome_tab_action(ircCloud, ircCloud .. 'magnet/channel/metacpan')
)
hs.hotkey.bind(my_hotkeys, 'q', slackifyName)

hs.hotkey.bind(hyper, 'a', clean_up_tabs())
hs.hotkey.bind(hyper, 'b', chrome_tab_action(bellTV, bellTV))
hs.hotkey.bind(hyper, 'c', nil, open_app_action('Google Chrome'))
hs.hotkey.bind(hyper, 'g', nil, chrome_tab_action(gmail, gmail .. '#all'))
hs.hotkey.bind(hyper, 'i', nil, open_app_action('wezterm'))
hs.hotkey.bind(hyper, 'k', xpasswd)
hs.hotkey.bind(hyper, 'l', nil, open_app_action('Slack'))
hs.hotkey.bind(
    hyper,
    'm',
    nil,
    chrome_tab_action('https://meet.google.com/', '')
)
-- hs.hotkey.bind(hyper, "n", nil, chrome_tab_action(github, github))
hs.hotkey.bind(
    hyper,
    'o',
    nil,
    chrome_tab_action(ircCloud, ircCloud .. 'magnet/channel/metacpan')
)
hs.hotkey.bind(hyper, 'p', nil, chrome_tab_action(PT, PT))
hs.hotkey.bind(hyper, 'q', slackifyName)
hs.hotkey.bind(hyper, 'v', open_app_action('Visual Studio Code'))
hs.hotkey.bind(hyper, 'w', chrome_tab_action(remoteDesktop, remoteDesktop))

local open_slack_threads = function(name)
    return function()
        hs.application.launchOrFocus(name)
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.shift, true):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, true):post()
        hs.eventtap.event.newKeyEvent('T', true):post()
        hs.eventtap.event.newKeyEvent('T', false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
        hs.eventtap.event.newKeyEvent(hs.keycodes.map.shift, false):post()
    end
end
hs.hotkey.bind(hyper, 't', nil, open_slack_threads('Slack'))

-- Stolen from Lukas https://stackoverflow.com/a/58662204/406224
hs.hotkey.bind(hyper, 'n', function()
    -- get the focused window
    local win = hs.window.focusedWindow()
    -- get the screen where the focused window is displayed, a.k.a. current screen
    local screen = win:screen()
    -- compute the unitRect of the focused window relative to the current screen
    -- and move the window to the next screen setting the same unitRect
    win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
end)
