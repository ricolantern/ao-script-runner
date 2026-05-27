const SelectionService = game:GetService("Selection")
const HistoryService = game:GetService("ChangeHistoryService")

const RunSource = require(script.RunSource)

const SCRIPT_EXT = ".cmd"
const PLUGIN_VERSION = "1.1.0"
const PLUGIN_NAME = `{string.match(script.Parent.Name, "user_(.+)%.rbxmx") :: string} v{PLUGIN_VERSION}`
const PLUGIN_DESC = `Run code in studio by first selecting any script ending with {SCRIPT_EXT} in Studio, then selecting the plugin.`
const PLUGIN_TOOLBAR = plugin:CreateToolbar(PLUGIN_NAME)
const OPT_RUN_NAME = "Run Script"
const OPT_RUN_BTN = PLUGIN_TOOLBAR:CreateButton(tostring(os.clock()), PLUGIN_DESC, "", OPT_RUN_NAME)
const PTRN_HAS_EXT = `.+%{SCRIPT_EXT}$`

const function Print<T...>(msg: string, ...: T...): ()
    print(`[{PLUGIN_NAME}] :: {msg}`, ...)
end

const function Warn<T...>(msg: string, ...: T...): ()
    warn(`[{PLUGIN_NAME}] :: {msg}`, ...)
end

OPT_RUN_BTN.Click:Connect(function()
    const selections = SelectionService:Get()

    if #selections > 1 then
        Warn(`Running more than 1 {SCRIPT_EXT} is not supported.`)
        print("\n\n")
        return
    elseif #selections == 0 then
        Warn(`You have nothing selected.`)
        print("\n\n")
        return
    end

    const selected = selections[1]

    if not selected:IsA("Script") and not selected:IsA("ModuleScript") then
        Warn(`{SCRIPT_EXT} scripts must be a valid inheritor of type Script or ModuleScript. {selected.Name} is of type {selected.ClassName} instead.`)
        print("\n\n")
        return
    end

    if not string.match(selected.Name, PTRN_HAS_EXT) then
        Warn(`You must select a script ending with "{SCRIPT_EXT}".`)
        print("\n\n")
        return
    end

    Print(`Initializing recording for change history... (You can undo/redo the script's changes after its completion)`)
   
    const recording = HistoryService:TryBeginRecording(OPT_RUN_NAME)

    if not recording then
        Warn(`Failed to initialize a recording for HistoryChangeService. A previous recording might still be running! Restart studio to fix.`)
        print("\n\n")
        return
    end

    Print(`Running script "{selected.Name}"...`)
    Print(`================= v {selected.Name} START OUTPUT v =================`)

    const startTs = tick()
    const ok, err = pcall(function()
        RunSource(selected)
    end)
    const elapsed = tick() - startTs

    Print(`================== ^ {selected.Name} END OUTPUT ^ ==================`)
    HistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)

    if not ok then
        const cleanedTrace = string.gsub(err :: string, "^%[.+%](:%d+: .+)", `[{selected.Name}]%1`) -- otherwise poops out the entire script content in traceback.

        Warn(`Script {selected.Name} ran into an error!\n`, cleanedTrace)
    end

    Print(`Finished running script "{selected.Name}" (took {elapsed}s to complete).`)
    print("\n\n")
end)
