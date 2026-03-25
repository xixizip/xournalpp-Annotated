-- AnnotatedPages Plugin for Xournal++
-- Extracts page numbers of annotated pages and copies them to clipboard.
-- Supports Windows, Linux (xclip / xsel / wl-copy) and macOS (pbcopy).
-- Author: xixizip  |  Version: 2.1.0

-- ─────────────────────────────────────────────────────────────
-- Detect operating system
-- ─────────────────────────────────────────────────────────────
local function get_os()
    local sep = package.config:sub(1, 1)
    if sep == "\\" then
        return "windows"
    end
    local f = io.popen("uname -s 2>/dev/null", "r")
    if f then
        local s = f:read("*l") or ""
        f:close()
        if s:match("Darwin") then
            return "macos"
        end
    end
    return "linux"
end

-- ─────────────────────────────────────────────────────────────
-- Copy text to clipboard (cross-platform)
-- ─────────────────────────────────────────────────────────────
local function copy_to_clipboard(text)
    local os_name = get_os()

    if os_name == "windows" then
        local tmp = (os.getenv("TEMP") or "C:\\Temp") .. "\\xpp_annotated.txt"
        local f = io.open(tmp, "w")
        if not f then
            return false, "Cannot open temp file"
        end
        f:write(text)
        f:close()
        local ok = os.execute('clip < "' .. tmp .. '"')
        os.remove(tmp)
        return (ok == 0 or ok == true), "clip.exe failed"

    elseif os_name == "macos" then
        local f = io.popen("pbcopy", "w")
        if not f then return false, "pbcopy not found" end
        f:write(text)
        f:close()
        return true

    else
        local function try_cmd(cmd)
            local f = io.popen(cmd, "w")
            if f then
                f:write(text)
                local ok = f:close()
                if ok then return true end
            end
            return false
        end
        if os.getenv("WAYLAND_DISPLAY") then
            if try_cmd("wl-copy") then return true end
        end
        if try_cmd("xclip -selection clipboard") then return true end
        if try_cmd("xsel --clipboard --input")   then return true end
        return false, "No clipboard tool found.\nInstall xclip, xsel or wl-clipboard."
    end
end

-- ─────────────────────────────────────────────────────────────
-- Collect annotated page numbers
-- NOTE: xournalpp source has a typo "isAnnoated" (missing 't')
-- We check both spellings for forward compatibility.
-- ─────────────────────────────────────────────────────────────
local function get_annotated_pages()
    local structure = app.getDocumentStructure()
    local pages     = structure["pages"]
    if not pages then
        return nil, "Cannot read document structure.\nIs a document open?"
    end

    local page_nums = {}
    for i = 1, #pages do
        local p = pages[i]
        if p["isAnnoated"] or p["isAnnotated"] then
            table.insert(page_nums, i)
        end
    end
    return page_nums
end

-- ─────────────────────────────────────────────────────────────
-- Build compact range string  {1,2,3,5,6,9} → "1-3,5-6,9"
-- ─────────────────────────────────────────────────────────────
local function to_range_string(nums)
    if #nums == 0 then return "" end
    local result      = {}
    local range_start = nums[1]
    local prev        = nums[1]
    for i = 2, #nums do
        local cur = nums[i]
        if cur == prev + 1 then
            prev = cur
        else
            table.insert(result, prev == range_start and tostring(range_start)
                                                      or range_start .. "-" .. prev)
            range_start = cur
            prev        = cur
        end
    end
    table.insert(result, prev == range_start and tostring(range_start)
                                              or range_start .. "-" .. prev)
    return table.concat(result, ",")
end

-- ─────────────────────────────────────────────────────────────
-- Main action
-- ─────────────────────────────────────────────────────────────
function run()
    local page_nums, err = get_annotated_pages()

    if not page_nums then
        app.openDialog("Error: " .. err, {[1] = "OK"}, "", true)
        return
    end

    if #page_nums == 0 then
        app.openDialog("No annotated pages found in the current document.", {[1] = "OK"}, "", false)
        return
    end

    local range_str      = to_range_string(page_nums)
    local ok, clip_err   = copy_to_clipboard(range_str)

    local msg
    if ok then
        msg = "Annotated pages (" .. #page_nums .. "):\n\n"
           .. range_str .. "\n\nCopied to clipboard!"
    else
        msg = "Annotated pages (" .. #page_nums .. "):\n\n"
           .. range_str .. "\n\nCould not copy to clipboard:\n" .. (clip_err or "unknown error")
    end

    app.openDialog(msg, {[1] = "OK"}, "", false)
end

-- ─────────────────────────────────────────────────────────────
-- Plugin registration
-- ─────────────────────────────────────────────────────────────
function initUi()
    app.registerUi({
        ["menu"]        = "Get Annotated Pages",
        ["callback"]    = "run",
        ["accelerator"] = "<Control><Shift>A",
    })
end
