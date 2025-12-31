--[[
    AutoCaptions for DaVinci Resolve
    Automatically transcribe and add subtitles using Whisper AI
]]

---------------------------------------------------------------------------
-- CONFIGURATION (Auto-detect install location)
---------------------------------------------------------------------------

-- Find where this script is installed
local function getScriptDir()
    -- Try to read the install location from config file
    local configLocations = {
        os.getenv("APPDATA") .. "\\AutoCaptions\\install_path.txt",
        os.getenv("LOCALAPPDATA") .. "\\AutoCaptions\\install_path.txt",
        os.getenv("USERPROFILE") .. "\\.autocaptions_path"
    }
    
    for _, configPath in ipairs(configLocations) do
        local f = io.open(configPath, "r")
        if f then
            local path = f:read("*l")
            f:close()
            if path and path ~= "" then
                return path
            end
        end
    end
    
    -- Fallback locations to check
    local fallbacks = {
        os.getenv("USERPROFILE") .. "\\Downloads\\AutoCaptions",
        os.getenv("USERPROFILE") .. "\\Desktop\\AutoCaptions",
        "C:\\AutoCaptions"
    }
    
    for _, path in ipairs(fallbacks) do
        local testFile = io.open(path .. "\\whisper_transcribe.py", "r")
        if testFile then
            testFile:close()
            return path
        end
    end
    
    return nil
end

local SCRIPT_DIR = getScriptDir()

if not SCRIPT_DIR then
    print("============================================================")
    print("ERROR: AutoCaptions installation not found!")
    print("")
    print("Please run install.bat first, or place the AutoCaptions")
    print("folder in one of these locations:")
    print("  - Downloads\\AutoCaptions")
    print("  - Desktop\\AutoCaptions")
    print("============================================================")
    return
end

local WHISPER_SCRIPT = SCRIPT_DIR .. "\\whisper_transcribe.py"
local GUI_SCRIPT = SCRIPT_DIR .. "\\autocaptions_gui.py"

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

local function getFileSize(path)
    local f = io.open(path, "rb")
    if not f then return 0 end
    local size = f:seek("end")
    f:close()
    return size or 0
end

local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

local function writeFile(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

local function deleteFile(path)
    os.remove(path)
end

local function getDownloadsFolder()
    local userProfile = os.getenv("USERPROFILE")
    if userProfile then
        return userProfile .. "\\Downloads"
    end
    return os.getenv("TEMP") or "C:\\Temp"
end

local function parseSubtitles(jsonStr)
    local segments = {}
    for startTime, endTime, text in jsonStr:gmatch('"start":%s*([%d%.]+).-"end":%s*([%d%.]+).-"text":%s*"([^"]*)"') do
        table.insert(segments, {
            start = tonumber(startTime),
            ["end"] = tonumber(endTime),
            text = text:gsub("\\n", "\n"):gsub('\\"', '"'):gsub("^%s+", ""):gsub("%s+$", "")
        })
    end
    return segments
end

local function countWords(text)
    local count = 0
    for _ in text:gmatch("%S+") do
        count = count + 1
    end
    return count
end

local function splitText(text, maxWords)
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local chunks = {}
    local i = 1
    while i <= #words do
        local chunk = {}
        for j = 1, maxWords do
            if i <= #words then
                table.insert(chunk, words[i])
                i = i + 1
            end
        end
        if #chunk > 0 then
            table.insert(chunks, table.concat(chunk, " "))
        end
    end
    return chunks
end

local function splitSegments(segments, maxWords)
    local result = {}
    
    for _, seg in ipairs(segments) do
        if not seg.text or seg.text == "" then
            goto continue
        end
        
        local wordCount = countWords(seg.text)
        
        if wordCount <= maxWords then
            -- Segment is small enough, keep as-is
            table.insert(result, seg)
        else
            -- Split this segment into smaller chunks
            local chunks = splitText(seg.text, maxWords)
            local segDuration = seg["end"] - seg.start
            local timePerChunk = segDuration / #chunks
            
            for i, chunkText in ipairs(chunks) do
                table.insert(result, {
                    start = seg.start + (i - 1) * timePerChunk,
                    ["end"] = seg.start + i * timePerChunk,
                    text = chunkText
                })
            end
        end
        
        ::continue::
    end
    
    return result
end

local function sleep(sec)
    local t = os.clock()
    while os.clock() - t < sec do end
end

local function writeStatus(statusPath, phase, progress, message, done, hasError, errorMsg, result)
    local parts = {}
    table.insert(parts, string.format('"phase": "%s"', phase or "idle"))
    table.insert(parts, string.format('"progress": %d', progress or 0))
    table.insert(parts, string.format('"message": "%s"', message or ""))
    table.insert(parts, string.format('"done": %s', done and "true" or "false"))
    table.insert(parts, string.format('"error": %s', hasError and "true" or "false"))
    if errorMsg then table.insert(parts, string.format('"error_message": "%s"', errorMsg)) end
    if result then table.insert(parts, string.format('"result": "%s"', result)) end
    writeFile(statusPath, "{\n  " .. table.concat(parts, ",\n  ") .. "\n}")
end

local function escapeJson(str)
    if not str then return "" end
    return str:gsub('\\', '\\\\'):gsub('"', '\\"')
end

local function findExportedFile(folder, baseName)
    local extensions = {".wav", ".mp3", ".aac", ".m4a", ".mp4", ".mov", ".mxf"}
    for _, ext in ipairs(extensions) do
        local path = folder .. "\\" .. baseName .. ext
        if fileExists(path) and getFileSize(path) > 1000 then
            return path
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- CONNECT TO RESOLVE
---------------------------------------------------------------------------

local resolve = _G.resolve
if not resolve and Resolve then
    local ok, res = pcall(Resolve)
    if ok and res then resolve = res end
end
if not resolve and bmd then
    local ok, res = pcall(function() return bmd.scriptapp("Resolve") end)
    if ok and res then resolve = res end
end

if not resolve then
    print("ERROR: Could not connect to DaVinci Resolve!")
    return
end

local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

if not project then
    print("ERROR: No project is open!")
    return
end

local timeline = project:GetCurrentTimeline()
if not timeline then
    print("ERROR: No timeline is selected!")
    return
end

local mediaPool = project:GetMediaPool()

---------------------------------------------------------------------------
-- FIND TEXT+ TEMPLATE AND EXTRACT PROPERTIES
---------------------------------------------------------------------------

-- Store template properties globally
local templateProperties = nil
local templateTimelineItem = nil

local function extractTextPlusProperties(fusionComp)
    local props = {}
    if not fusionComp then return nil end
    
    local tools = nil
    pcall(function() tools = fusionComp:GetToolList() end)
    if not tools then return nil end
    
    for _, tool in pairs(tools) do
        local toolId = ""
        pcall(function() toolId = tool:GetAttrs().TOOLS_RegID end)
        
        if toolId == "TextPlus" then
            pcall(function()
                -- Get ALL input properties
                local inputs = tool:GetInputList()
                for inputName, input in pairs(inputs) do
                    local val = nil
                    pcall(function() val = input:GetSource(0) end)
                    if val ~= nil then
                        props[inputName] = val
                    end
                end
            end)
            return props
        end
    end
    return nil
end

local function findTemplateOnTimeline(templateName)
    if not templateName or templateName == "(None - Use Subtitles)" then
        return nil, nil
    end
    
    -- Check if it's a timeline clip reference (starts with "[Timeline]")
    if templateName:sub(1, 10) == "[Timeline]" then
        local clipName = templateName:sub(12) -- Remove "[Timeline] " prefix
        
        local videoTrackCount = timeline:GetTrackCount("video")
        for trackIdx = 1, videoTrackCount do
            local items = timeline:GetItemListInTrack("video", trackIdx)
            if items then
                for _, item in ipairs(items) do
                    local name = ""
                    pcall(function() name = item:GetName() end)
                    if name == clipName or name:find("Text") or name:find("Fusion") then
                        local fusionComp = nil
                        pcall(function() fusionComp = item:GetFusionCompByIndex(1) end)
                        if fusionComp then
                            local props = extractTextPlusProperties(fusionComp)
                            if props then
                                return item, props
                            end
                        end
                    end
                end
            end
        end
    end
    
    return nil, nil
end

local function findTemplateInMediaPool(templateName)
    if not templateName or templateName == "(None - Use Subtitles)" then
        return nil
    end
    
    -- Skip timeline references
    if templateName:sub(1, 10) == "[Timeline]" then
        return nil
    end
    
    local function searchFolder(folder)
        if not folder then return nil end
        
        local clips = folder:GetClipList()
        if clips then
            for _, clip in ipairs(clips) do
                local name = ""
                pcall(function() name = clip:GetName() end)
                if name == templateName then
                    return clip
                end
            end
        end
        
        local subfolders = folder:GetSubFolderList()
        if subfolders then
            for _, subfolder in ipairs(subfolders) do
                local found = searchFolder(subfolder)
                if found then return found end
            end
        end
        
        return nil
    end
    
    return searchFolder(mediaPool:GetRootFolder())
end

---------------------------------------------------------------------------
-- SETUP PATHS
---------------------------------------------------------------------------

local tempDir = os.getenv("TEMP") or "C:\\Temp"
local downloadsDir = getDownloadsFolder()
local exportName = "AutoCaptions_Export"

local configPath = tempDir .. "\\autocaptions_config.json"
local controlPath = tempDir .. "\\autocaptions_control.json"
local statusPath = tempDir .. "\\autocaptions_status.json"
local subtitlesPath = tempDir .. "\\autocaptions_result.json"
local srtPath = tempDir .. "\\autocaptions_result.srt"

deleteFile(configPath)
deleteFile(controlPath)
deleteFile(statusPath)

for _, ext in ipairs({".wav", ".mp3", ".mp4", ".mov", ".aac", ".m4a"}) do
    deleteFile(downloadsDir .. "\\" .. exportName .. ext)
end

---------------------------------------------------------------------------
-- GATHER INFO
---------------------------------------------------------------------------

local audioTracks = {"All Audio"}
local audioTrackCount = timeline:GetTrackCount("audio")
for i = 1, audioTrackCount do
    table.insert(audioTracks, "Audio " .. i)
end

local templates = {"(None - Use Subtitles)"}

-- First, scan TIMELINE for Text+ clips (these are the best templates!)
local function scanTimelineForTextPlus()
    local videoTrackCount = timeline:GetTrackCount("video")
    local foundNames = {}
    
    for trackIdx = 1, videoTrackCount do
        local items = nil
        pcall(function() items = timeline:GetItemListInTrack("video", trackIdx) end)
        if items then
            for _, item in ipairs(items) do
                local name = ""
                pcall(function() name = item:GetName() end)
                
                -- Check if it has a Fusion composition with Text+
                local fusionComp = nil
                pcall(function() fusionComp = item:GetFusionCompByIndex(1) end)
                
                if fusionComp then
                    local hasTextPlus = false
                    pcall(function()
                        local tools = fusionComp:GetToolList()
                        for _, tool in pairs(tools) do
                            local toolId = ""
                            pcall(function() toolId = tool:GetAttrs().TOOLS_RegID end)
                            if toolId == "TextPlus" then
                                hasTextPlus = true
                                break
                            end
                        end
                    end)
                    
                    if hasTextPlus and name ~= "" and not foundNames[name] then
                        foundNames[name] = true
                        table.insert(templates, "[Timeline] " .. name)
                    end
                end
            end
        end
    end
end

pcall(scanTimelineForTextPlus)

-- Then scan Media Pool
local function scanFolder(folder)
    if not folder then return end
    local clips = folder:GetClipList()
    if clips then
        for _, clip in ipairs(clips) do
            local clipName = ""
            pcall(function() clipName = clip:GetName() or "" end)
            local props = nil
            pcall(function() props = clip:GetClipProperty() end)
            if props and clipName ~= "" then
                local clipType = props["Type"] or props["Clip Type"] or ""
                if clipType:find("Fusion") or clipType:find("Generator") or clipType:find("Title") or clipType:find("Compound") then
                    table.insert(templates, clipName)
                end
            end
        end
    end
    local subfolders = nil
    pcall(function() subfolders = folder:GetSubFolderList() end)
    if subfolders then
        for _, subfolder in ipairs(subfolders) do
            scanFolder(subfolder)
        end
    end
end

pcall(function() scanFolder(mediaPool:GetRootFolder()) end)

local audioArray = {}
for _, t in ipairs(audioTracks) do
    table.insert(audioArray, '"' .. escapeJson(t) .. '"')
end

local templateArray = {}
for _, t in ipairs(templates) do
    table.insert(templateArray, '"' .. escapeJson(t) .. '"')
end

local configJson = string.format([[
{
  "project": "%s",
  "current_timeline": "%s",
  "audio_tracks": [%s],
  "templates": [%s]
}
]], escapeJson(project:GetName()), escapeJson(timeline:GetName()), 
    table.concat(audioArray, ", "), table.concat(templateArray, ", "))

writeFile(configPath, configJson)

---------------------------------------------------------------------------
-- LAUNCH GUI
---------------------------------------------------------------------------

print("===========================================================")
print("  🎬 AutoCaptions")
print("===========================================================")
print("")
print("  Project:  " .. project:GetName())
print("  Timeline: " .. timeline:GetName())
print("  Export to: " .. downloadsDir)
print("")

local guiCmd = string.format('start "" python "%s" "%s" "%s" "%s"', 
    GUI_SCRIPT, configPath, controlPath, statusPath)
os.execute(guiCmd)

print("Waiting for user...")

local settings = nil
local maxWait = 600
local waited = 0

while waited < maxWait do
    if fileExists(controlPath) then
        local controlJson = readFile(controlPath)
        if controlJson then
            local command = controlJson:match('"command":%s*"([^"]*)"')
            if command == "start" then
                settings = {
                    audio_track = controlJson:match('"audio_track":%s*"([^"]*)"'),
                    output_track = controlJson:match('"output_track":%s*"([^"]*)"'),
                    template = controlJson:match('"template":%s*"([^"]*)"'),
                    model = controlJson:match('"model":%s*"([^"]*)"') or "base",
                    language = controlJson:match('"language":%s*"([^"]*)"') or "auto",
                    words_per_line = tonumber(controlJson:match('"words_per_line":%s*(%d+)')) or 8
                }
                break
            elseif command == "cancel" then
                print("Cancelled by user.")
                deleteFile(controlPath)
                return
            end
        end
    end
    sleep(0.5)
    waited = waited + 0.5
end

if not settings then
    print("Timeout.")
    return
end

deleteFile(controlPath)

print("")
print("Settings:")
print("  Model: " .. settings.model)
print("  Language: " .. settings.language)
print("  Audio: " .. (settings.audio_track or "All"))
print("  Words/line: " .. settings.words_per_line)
print("  Template: " .. (settings.template or "None"))
print("  Output: " .. (settings.output_track or "Subtitle Track"))
print("")

---------------------------------------------------------------------------
-- PREPARE AUDIO TRACKS
---------------------------------------------------------------------------

writeStatus(statusPath, "exporting", 5, "Preparing audio tracks...")

local fps = tonumber(timeline:GetSetting("timelineFrameRate")) or 24
local originalMuteStates = {}

if settings.audio_track and settings.audio_track ~= "All Audio" then
    local selectedNum = tonumber(settings.audio_track:match("Audio (%d+)"))
    if selectedNum then
        for i = 1, audioTrackCount do
            pcall(function()
                originalMuteStates[i] = timeline:GetIsTrackEnabled("audio", i)
                timeline:SetTrackEnable("audio", i, i == selectedNum)
            end)
        end
    end
end

---------------------------------------------------------------------------
-- EXPORT AUDIO
---------------------------------------------------------------------------

writeStatus(statusPath, "exporting", 10, "Setting up export...")

local originalPage = resolve:GetCurrentPage()
resolve:OpenPage("deliver")
sleep(0.8)

-- Clear ALL existing render jobs first!
print("Clearing old render jobs...")
local jobsCleared = 0
for attempt = 1, 3 do
    pcall(function()
        local jobs = project:GetRenderJobList()
        if jobs and #jobs > 0 then
            for i = #jobs, 1, -1 do
                local deleted = project:DeleteRenderJob(jobs[i])
                if deleted then jobsCleared = jobsCleared + 1 end
            end
        end
    end)
    sleep(0.2)
end
if jobsCleared > 0 then
    print("Cleared " .. jobsCleared .. " old render jobs")
end

local formatAttempts = {
    {format = "wav", codec = "LinearPCM"},
    {format = "mp3", codec = "mp3"},
    {format = "mp4", codec = "H.264"}
}

local jobAdded = false

for _, fmt in ipairs(formatAttempts) do
    local ok = pcall(function()
        project:SetCurrentRenderFormatAndCodec(fmt.format, fmt.codec)
        local renderSettings = {
            TargetDir = downloadsDir,
            CustomName = exportName,
            ExportAudio = true
        }
        if fmt.format == "mp4" or fmt.format == "mov" then
            renderSettings.ExportVideo = true
        else
            renderSettings.ExportVideo = false
        end
        project:SetRenderSettings(renderSettings)
    end)
    
    if ok then
        local jid = nil
        pcall(function() jid = project:AddRenderJob() end)
        if jid then
            jobAdded = true
            print("Export format: " .. fmt.format)
            break
        end
    end
end

if not jobAdded then
    for i, wasEnabled in pairs(originalMuteStates) do
        pcall(function() timeline:SetTrackEnable("audio", i, wasEnabled) end)
    end
    resolve:OpenPage(originalPage or "edit")
    writeStatus(statusPath, "exporting", 0, "", false, true, "Could not add render job")
    return
end

writeStatus(statusPath, "exporting", 15, "Rendering...")
pcall(function() project:StartRendering() end)

local timeout = 600
local elapsed = 0
local lastProgress = 0

while elapsed < timeout do
    local isRendering = false
    local progress = 0
    
    pcall(function()
        isRendering = project:IsRenderingInProgress()
        local jobs = project:GetRenderJobList()
        if jobs and #jobs > 0 then
            local status = project:GetRenderJobStatus(jobs[#jobs])
            if status and status.CompletionPercentage then
                progress = status.CompletionPercentage
            end
        end
    end)
    
    if progress > lastProgress then
        lastProgress = progress
        local pct = 15 + (progress * 0.75)
        writeStatus(statusPath, "exporting", math.floor(pct), string.format("Exporting... %d%%", math.floor(progress)))
    end
    
    if not isRendering and elapsed > 2 then
        break
    end
    
    sleep(0.3)
    elapsed = elapsed + 0.3
end

pcall(function()
    local jobs = project:GetRenderJobList()
    if jobs then
        for _, job in ipairs(jobs) do
            pcall(function() project:DeleteRenderJob(job) end)
        end
    end
end)

for i, wasEnabled in pairs(originalMuteStates) do
    pcall(function() timeline:SetTrackEnable("audio", i, wasEnabled) end)
end

resolve:OpenPage(originalPage or "edit")
sleep(0.5)

writeStatus(statusPath, "exporting", 95, "Locating exported file...")

local exportedFile = nil
for attempt = 1, 10 do
    exportedFile = findExportedFile(downloadsDir, exportName)
    if exportedFile then break end
    sleep(0.5)
end

if not exportedFile then
    writeStatus(statusPath, "exporting", 0, "", false, true, "Export file not found")
    return
end

writeStatus(statusPath, "exporting", 100, "Export complete!")
print("Exported: " .. exportedFile)
sleep(0.3)

---------------------------------------------------------------------------
-- TRANSCRIBE WITH WHISPER
---------------------------------------------------------------------------

writeStatus(statusPath, "transcribing", 5, "Loading Whisper AI...")
print("Starting transcription...")

local whisperCmd = string.format(
    'python "%s" "%s" "%s" %s %s',
    WHISPER_SCRIPT, exportedFile, subtitlesPath, settings.model, settings.language
)

os.execute(whisperCmd)
deleteFile(exportedFile)

if not fileExists(subtitlesPath) then
    writeStatus(statusPath, "transcribing", 0, "", false, true, "Transcription failed")
    return
end

local jsonContent = readFile(subtitlesPath)
if not jsonContent or jsonContent == "" then
    writeStatus(statusPath, "transcribing", 0, "", false, true, "Empty result")
    deleteFile(subtitlesPath)
    return
end

writeStatus(statusPath, "transcribing", 100, "Transcription complete!")
print("Transcription done!")
sleep(0.3)

---------------------------------------------------------------------------
-- PARSE AND MERGE SUBTITLES
---------------------------------------------------------------------------

writeStatus(statusPath, "adding", 5, "Processing subtitles...")

local rawSegments = parseSubtitles(jsonContent)
deleteFile(subtitlesPath)

if #rawSegments == 0 then
    writeStatus(statusPath, "adding", 100, "Done", true, false, nil, "No speech detected")
    return
end

print("Raw segments: " .. #rawSegments)

-- Merge segments based on word count
local segments = splitSegments(rawSegments, settings.words_per_line)
print("Merged segments: " .. #segments)

---------------------------------------------------------------------------
-- ADD SUBTITLES TO TIMELINE
---------------------------------------------------------------------------

writeStatus(statusPath, "adding", 10, string.format("Adding %d subtitles...", #segments))

local addedCount = 0
local outputTrack = settings.output_track or "Subtitle Track"

-- Find template - check timeline first, then media pool
local templateItem, templateProps = findTemplateOnTimeline(settings.template)
local templateClip = nil

if not templateItem then
    templateClip = findTemplateInMediaPool(settings.template)
end

-- Only use Text+ if a template is found AND output is a video track (not subtitle track)
local useTextPlus = (templateItem ~= nil or templateClip ~= nil) and outputTrack ~= "Subtitle Track"

-- Determine output track number for video tracks
local outputTrackNum = 1
if outputTrack:match("Video (%d+)") then
    outputTrackNum = tonumber(outputTrack:match("Video (%d+)")) or 1
end

print("Output track: " .. outputTrack)
print("Using Text+ template: " .. tostring(useTextPlus))
if templateProps then
    print("Template properties extracted: YES")
end

-- Get timeline start frame offset (timelines often start at 01:00:00:00)
local timelineStartFrame = timeline:GetStartFrame() or 0
print("Timeline start frame: " .. timelineStartFrame)
print("FPS: " .. fps)

if useTextPlus and templateClip then
    -- Use Text+ template clips from Media Pool
    writeStatus(statusPath, "adding", 15, "Using Text+ template...")
    
    for i, seg in ipairs(segments) do
        if seg.text and seg.text:match("%S") then
            -- Calculate frame positions WITH timeline offset
            local startFrame = timelineStartFrame + math.floor(seg.start * fps)
            local endFrame = timelineStartFrame + math.floor(seg["end"] * fps)
            local duration = endFrame - startFrame
            
            if duration > 0 then
                local ok = pcall(function()
                    local added = mediaPool:AppendToTimeline({
                        {
                            mediaPoolItem = templateClip,
                            startFrame = 0,
                            endFrame = duration,
                            trackIndex = outputTrackNum,
                            recordFrame = startFrame
                        }
                    })
                    
                    if added and #added > 0 then
                        local timelineItem = added[1]
                        local fusionComp = nil
                        pcall(function() fusionComp = timelineItem:GetFusionCompByIndex(1) end)
                        
                        if fusionComp then
                            local tools = fusionComp:GetToolList()
                            for _, tool in pairs(tools) do
                                local toolId = ""
                                pcall(function() toolId = tool:GetAttrs().TOOLS_RegID end)
                                if toolId == "TextPlus" then
                                    -- Apply template properties if we have them
                                    if templateProps then
                                        for propName, propVal in pairs(templateProps) do
                                            if propName ~= "StyledText" then
                                                pcall(function() tool:SetInput(propName, propVal) end)
                                            end
                                        end
                                    end
                                    -- Set the subtitle text
                                    pcall(function() tool:SetInput("StyledText", seg.text) end)
                                    break
                                end
                            end
                        end
                        addedCount = addedCount + 1
                    end
                end)
            end
        end
        
        if i % 10 == 0 then
            local pct = 15 + (i / #segments * 80)
            writeStatus(statusPath, "adding", math.floor(pct), string.format("Adding... %d/%d", i, #segments))
        end
    end
else
    -- Use subtitle track - create SRT and import
    writeStatus(statusPath, "adding", 15, "Creating subtitle file...")
    
    local srtContent = ""
    for i, seg in ipairs(segments) do
        if seg.text and seg.text:match("%S") then
            local function formatTime(seconds)
                local hours = math.floor(seconds / 3600)
                local mins = math.floor((seconds % 3600) / 60)
                local secs = math.floor(seconds % 60)
                local ms = math.floor((seconds % 1) * 1000)
                return string.format("%02d:%02d:%02d,%03d", hours, mins, secs, ms)
            end
            
            srtContent = srtContent .. i .. "\n"
            srtContent = srtContent .. formatTime(seg.start) .. " --> " .. formatTime(seg["end"]) .. "\n"
            srtContent = srtContent .. seg.text .. "\n\n"
        end
    end
    
    writeFile(srtPath, srtContent)
    print("Created SRT: " .. srtPath)
    
    writeStatus(statusPath, "adding", 50, "Importing subtitles...")
    
    -- Try to import SRT
    local imported = false
    
    pcall(function()
        local result = timeline:ImportIntoTimeline(srtPath)
        if result then
            imported = true
            addedCount = #segments
        end
    end)
    
    if not imported then
        pcall(function()
            local clips = mediaPool:ImportMedia({srtPath})
            if clips and #clips > 0 then
                local result = mediaPool:AppendToTimeline(clips)
                if result then
                    imported = true
                    addedCount = #segments
                end
            end
        end)
    end
    
    if not imported then
        -- Keep SRT for manual import
        print("")
        print("SRT file created: " .. srtPath)
        print("Import manually: File > Import > Subtitle")
        addedCount = #segments
    else
        deleteFile(srtPath)
    end
end

-- Done!
local resultMsg
if addedCount > 0 then
    resultMsg = string.format("Added %d subtitles!", addedCount)
else
    resultMsg = "SRT created - import manually"
end

writeStatus(statusPath, "adding", 100, "Done", true, false, nil, resultMsg)

print("")
print("===========================================================")
print("  ✅ Done! " .. resultMsg)
print("===========================================================")
