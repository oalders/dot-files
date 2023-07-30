#!/usr/bin/osascript

say "starting tab cleanup"
set urls to {}

tell application "Google Chrome"
    activate

    repeat with theWindow in every window
        set toClose to {}
        set tabIndex to 1
        repeat with theTab in every tab of theWindow
            set tabIsDuplicate to false
            repeat with seen in urls
                if (seen as string = URL of theTab as string) then
                    copy tabIndex to the end of toClose
                    set tabIsDuplicate to true
                    exit repeat
                end if
            end repeat
            set tabIndex to tabIndex + 1

            if tabIsDuplicate is not true then
                copy URL of theTab as string to the end of urls
            end if

        end repeat

        set closing to reverse of toClose

        repeat with closeIndex in closing
            close tab closeIndex of theWindow
        end repeat
        set numberOfClosed to count of closing
        if numberOfClosed > 0 then
            say numberOfClosed
            say "tabs closed"
        end if
    end repeat
end tell
say "finished tab cleanup"
