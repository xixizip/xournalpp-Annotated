function initUi()
    app.registerUi({
        menu = "智能导出：仅标注页面",
        callback = "smartExportAnnotated",
        accelerator = "<Ctrl><Shift>N"
    })
end

function smartExportAnnotated()
    local doc = app.getDocumentStructure()
    local pages = {}
    
    -- 收集有标注的页面
    for i, page in ipairs(doc.pages) do
        if page.isAnnotated then
            table.insert(pages, i)
        end
    end
    
    if #pages == 0 then
        app.openDialog("ℹ️ 未找到带标注的页面\n\n当前文档没有手写标注。", {"确定"}, "", true)
        return
    end
    
    -- 构建范围字符串
    local rangeStr = buildRangeString(pages)
    
    -- 清理文本（移除所有换行符）
    local cleanRange = rangeStr:gsub("[\r\n]", "")
    
    -- 生成统计信息
    local stats = string.format(
        "📊 统计信息\n" ..
        "━━━━━━━━━━━━━━━━━━━━━\n" ..
        "• 总页数: %d\n" ..
        "• 有标注页数: %d\n" ..
        "• 占比: %.1f%%\n\n" ..
        "📋 页面范围:\n%s\n\n" ..
        "💡 下一步操作:\n" ..
        "1. 点击【复制并打开导出】\n" ..
        "2. 在导出对话框粘贴范围\n" ..
        "3. 选择保存位置\n\n" ..
        "⚡ 快捷提示: 范围已自动复制到剪贴板",
        #doc.pages,
        #pages,
        (#pages / #doc.pages) * 100,
        cleanRange
    )
    
    -- 自动复制到剪贴板（清理后的文本）
    local copied = copyToClipboard(cleanRange)
    
    local buttons = copied 
        and {"复制并打开导出", "仅确定"} 
        or {"复制范围", "确定"}
    
    local result = app.openDialog(stats, buttons, "", true)
    
    if result == 1 then
        if not copied then
            copyToClipboard(cleanRange)
        end
        tryOpenExportDialog()
    end
end

-- 构建压缩的范围字符串
function buildRangeString(pages)
    if #pages == 0 then return "" end
    if #pages == 1 then return tostring(pages[1]) end
    
    table.sort(pages)
    local ranges = {}
    local start = pages[1]
    local prev = pages[1]
    
    for i = 2, #pages do
        if pages[i] ~= prev + 1 then
            if start == prev then
                table.insert(ranges, tostring(start))
            else
                table.insert(ranges, start .. "-" .. prev)
            end
            start = pages[i]
        end
        prev = pages[i]
    end
    
    -- 处理最后一个范围
    if start == prev then
        table.insert(ranges, tostring(start))
    else
        table.insert(ranges, start .. "-" .. prev)
    end
    
    return table.concat(ranges, ",")
end

-- Windows 剪贴板复制（无回车版本）
function copyToClipboard(text)
    -- 彻底清理：移除所有 \r 和 \n
    text = tostring(text):gsub("[\r\n]", "")
    
    -- 方案1: PowerShell（推荐，无换行符问题）
    local psCmd = string.format(
        [[powershell -NoProfile -Command "$text = '%s'; [System.Windows.Forms.Clipboard]::SetText($text)"]],
        text:gsub("'", "''")  -- 转义单引号
    )
    
    if os.execute(psCmd) == 0 then return true end
    
    -- 方案2: 备用方案（如果 PowerShell 失败）
    local tempFile = os.getenv("TEMP") .. "\\xournal_range.txt"
    local f = io.open(tempFile, "wb")  -- 二进制模式写入
    if f then
        f:write(text)  -- 纯文本，无换行
        f:close()
        
        -- 使用 type 命令配合 clip（避免 echo 的换行）
        local cmd = string.format('type "%s" | clip', tempFile)
        local result = os.execute(cmd)
        os.remove(tempFile)
        return result == 0
    end
    
    return false
end

-- 尝试打开导出对话框（预留接口）
function tryOpenExportDialog()
    -- 如果未来 Xournal++ 支持 uiAction，可以在这里调用
    -- 目前为占位函数
end
