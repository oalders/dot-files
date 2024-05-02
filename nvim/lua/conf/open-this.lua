_G.OpenThis = function(fname)
    local cmd = 'ot --editor nvim --json ' .. vim.fn.shellescape(fname)
    local handle = io.popen(cmd)
    local result = handle:read('*a')
    handle:close()

    local jsonResult = vim.fn.json_decode(result)

    if jsonResult.success == true then
        local editorArgs = table.concat(jsonResult.editor_args, ' ')
        vim.cmd('e ' .. editorArgs)
    else
        print(
            'Error: '
                .. jsonResult.error
                .. (
                    jsonResult.details
                        and 'Details: ' .. jsonResult.details
                    or ''
                )
        )
    end

    -- Add the command to the command history
    vim.fn.histadd(
        ':',
        string.format(':lua OpenThis("%s")', vim.fn.escape(fname, '"\\'))
    )
end
