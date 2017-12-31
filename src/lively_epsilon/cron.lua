local now = 0.0
local events = {}

-- Cron is a component to handle code that is to be executed after a certain time
--
-- Its main goal is to reduce load during scripting. Not every condition has to be
-- checked on every tick. The enemies attacking your crew only half a second after
-- you got closer then 30u to them is not a difference the crew would notice, but
-- it reduces load on the server.
--
-- A nice side effect is also that it makes working with delays and timeouts very easy.

Cron = {
    tick = function(delta)
        now = now + delta

        for key, value in pairs(events) do
            if value.next <= now then
                local cronOverride
                local status, error = pcall(value.func)
                if not status then
                    if type(error) == "string" then
                        print("An error occured in Cron with " .. key .. ": " .. error)
                    else
                        print("An error occured in Cron with " .. key)
                    end
                elseif isNumber(error) then
                    cronOverride = error
                end

                -- if an error occurs we log it, but continue
                if value.cron ~= nil then
                    value.next = value.next + (cronOverride or value.cron)
                else
                    events[key] = nil
                end
            end
        end
    end,


    -- Example:
    --
    --   Cron.once("identifier", function() print("Hello World") end, 10)
    once = function(name, func, delay)
        if type(name) == "function" then
            delay = func
            func = name
            name = Util.randomUuid()
        end

        events[name] = {
            next = now + (delay or 0),
            func = func,
            cron = nil
        }
    end,

    regular = function(name, func, interval, delay)
        events[name] = {
            next = now + (delay or 0),
            func = func,
            cron = interval or 60
        }
    end,
    abort = function(name)
        events[name] = nil
    end
}