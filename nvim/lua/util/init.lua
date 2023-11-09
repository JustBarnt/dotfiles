_G.profile = function(cmd, times, flush)
    times = times or 100
    local start = vim.loop.hrtime()
    for _= 1, times, 1 do
        if flush then
            jit.flush(cmd, true)
        end
        cmd()
    end
    print(((vim.loop.hrtime() - start) / 1e6 / times) .. "ms")
end

local M = {}

function M.exists(fname)
    local stat = vim.loop.fs_stat(fname)
    return (stat and stat.type) or false
end

function M.version()
    local v = vim.version()
    if v and not v.prerelease then
        vim.notify(
            ("Neovim v%d.%d.%d"):format(v.major, v.minor, v.patch),
            vim.log.levels.WARN,
            {title = "Neovim: not runnign nightly!"}
        )
    end
end

function M.base64(data)
    data = tostring(data)
    local bit = require('bit')
    local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local b64, len = "", #data
    local rshift, lshift, bor = bit.rshift, bit.lshift, bit.bor

    for i = 1, len, 3 do
        local a, b, c = data:byte(i, i + 2)
        b = b or 0
        c = c or 0

        local buffer = bor(lshift(a, 16), lshift(b, 8), c)
        for j = 0, 3 do
            local index = rshift(buffer, (3-j) * 6) % 64
            b64 = b64 .. b64chars:sub(index +1, index + 1)
        end
    end
end

return M
