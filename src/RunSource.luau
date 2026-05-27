--!nonstrict

export type ModuleSource = {any}|any

const baseEnv = getfenv()

const function GetEnv(module, overrides)
    local newEnv = overrides

    setmetatable(
        newEnv,
        {
            __index = function(_, key)
                if key ~= "plugin" then
                    return baseEnv[key]
                end

                return nil
            end
        }
    )

    newEnv.script = module

    local realDebug = debug

    newEnv.debug =
        setmetatable(
        {
            traceback = function(message)
                -- Block traces to prevent overly verbose TestEZ output
                return message or ""
            end
        },
        {__index = realDebug}
    )

    return newEnv
end

const function RunSource(container: ModuleScript|Script): ModuleSource
    local env = GetEnv(container, {
        require = RunSource, -- shadow the built-in require func to get rid of caching.
    })
    local execute = loadstring(container.Source)

    setfenv(execute, env)

    return execute()
end

return RunSource
