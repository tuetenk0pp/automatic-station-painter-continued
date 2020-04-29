--[[--
This was written with the idea that Automatic Train Painter (ATP)
was also installed. It's not necessary, but the comments reflect
how this interacts with ATP. If the user isn't playing with that
mod, the comments still apply.. *unless* another mod modifies the
train's color via event after this mod sets the station's color.
--]]--

local DEVELOP = false

script.on_init (function ()
    global.train_at_station = {}
end)

--[[--
TODO: If trains are picked up at stations, the train.id will remain
  in the global.train_at_station table. Consider handling the
  various mined events and remove the train.id from the table.
  Alternatively, always clear the table on reload.
--]]--


script.on_event (defines.events.on_tick, function(event)
    -- Useful for development to reset state.

    -- Tracks data about trains at stations. This is used to
    -- reference the last station the train was at once it leaves
    -- the station and ATP paints the train.
    if DEVELOP then
        global.train_at_station = {}
    end

    -- For debugging; see the topmost comment in this file.
    print (script.get_event_order())

    -- And then disable the event callback.
    script.on_event (defines.events.on_tick, nil)
end)


script.on_event (defines.events.on_train_changed_state, function (event)
    local train = event.train

    if train == nil or not train.valid then
        -- Nothing to do since we got an invalid
        -- train in the event.
    elseif train.state == defines.train_state.wait_station then
        -- Save off the station and information on the train at
        -- the time of its arrival. It'll be used in determining
        -- how to paint that said station.
        if train.station ~= nil and train.station.valid then
            local train_color, train_empty = train_color_info (train)

            global.train_at_station[train.id] = {
                train_color = train_color,
                train_empty = train_empty,
                station = train.station
            }
        end
    elseif train.state == defines.train_state.on_the_path
            and not train.manual_mode then
        -- Because ATS is optionally dependent on ATP, the event order will
        -- be what we require--ATP and then ATS. We can be confident that
        -- ATP has painted the train by time we process this event.

        -- The station to paint will be the previous station, which
        -- has been saved off in the global table.
        local station_data = global.train_at_station[train.id]
        if station_data ~= nil
                and station_data.station ~= nil
                and station_data.station.valid then
            paint_station (station_data, train)
        end
        global.train_at_station[train.id] = nil
    end
end)

function blend_colors (c1, c2, t)
    local blended = {}

    local blend_alpha = function (a1, a2)
        return (1-t) * a1 + t * a2
    end

    local blend_channel = function (ch1, ch2)
        return math.sqrt ((1-t) * ch1^2 + t* ch2^2)
    end

    blended.r = blend_channel (c1.r, c2.r)
    blended.g = blend_channel (c1.g, c2.g)
    blended.b = blend_channel (c1.b, c2.b)
    blended.a = blend_alpha (c1.a, c2.a)

    return blended
end

function normalize_colors (colors, scale)
    local new_colors = {}
    for index, value in pairs (colors) do
        new_colors[index] = value / scale
    end

    return new_colors
end


function paint_station (station_data, train)
    local train_prev_color = station_data["train_color"]
    local train_prev_empty = station_data["train_empty"]
    local station = station_data["station"]

    local train_color
    local train_curr_color, train_curr_empty = train_color_info (train)

    if train_prev_empty and train_curr_empty then
        -- In this case, we'll leave the station as-is.
    elseif train_curr_empty then
        -- The train dropped some goods off and the train was
        -- colored to reflect its cargo. We'll paint the station that
        -- color since this is a receiver.
        train_color = train_prev_color
    else
        -- The train has picked up some goods. ATP has painted
        -- the train the new color. We'll use that color.
        train_color = train_curr_color
    end

    if train_color then
        if station.color ~= nil then
            -- We continually mix the colors each time to account
            -- for stations that provide/receive different shipment types.
            -- Weigh it in favor of the train.
            local blend_ratio = settings.global["blend-ratio"].value

            station.color = blend_colors (station.color, train_color, blend_ratio)
        else
            -- If a color has never been set, default it to the color
            -- chosen by the train's contents (or lack thereof).
            station.color = train_color
        end
    end
end


function train_color_info (train)
    local locos = train.locomotives
    local train_color = { r=0, g=0, b=0, a=0 }

    if locos ~= nil then
        local target = locos['front_movers'][1] or locos['back_movers'][1]
        if target and target.valid then
            train_color = target.color
        end
    end

    local empty = train.get_item_count() == 0 and train.get_fluid_count() == 0
    return train_color, empty
end

