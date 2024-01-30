#!/usr/bin/osascript

on run argv
    set target to item 1 of argv

    tell application "Google Chrome"
        activate
        repeat with w in windows
            repeat with i from (count of tabs of w) to 1 by -1
                set t to tab i of w
                set tabURL to URL of t
                if tabURL contains target then
                    close t
                end if
            end repeat
        end repeat
    end tell
end run
