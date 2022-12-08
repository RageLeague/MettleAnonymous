local old_opt_fn = Widget.MettleOptionButton.Refresh

function Widget.MettleOptionButton:Refresh(...)
    local result = old_opt_fn(self, ...)

    if self.acquired then
        self:SetOnClickFn(self.onclick_acquired_fn)
    end

    return result
end

local old_compopt_fn = Widget.MettleCompendiumOptionButton.Refresh

function Widget.MettleCompendiumOptionButton:Refresh(...)
    local result = old_compopt_fn(self, ...)

    if self.acquired then
        self:SetOnClickFn(self.onclick_acquired_fn)
    end

    return result
end

local old_row_fn = Widget.MettleRowWidget.init

function Widget.MettleRowWidget:init(...)
    local result = old_row_fn(self, ...)

    for k, button in self.buttons:Children() do
        button.onclick_acquired_fn = function() self:OnDowngrade(k) end
        button:Refresh()
    end
    return result
end

function Widget.MettleRowWidget:OnDowngrade( option_index )
    -- AUDIO:PlayEvent("event:/ui/mettle_shop/unlock_mettle")
    if self.on_downgrade_fn then
        local widget = self.buttons.children[option_index]
        self.on_downgrade_fn( self.def.id, option_index )
    end
end

local old_compendium_fn = Widget.MettleCompendiumWidget.init

-- I'm fixing the ordering of the mettle in the compendium because it's very irritating
function Widget.MettleCompendiumWidget:init(...)
    local result = old_compendium_fn(self, ...)
    table.sort(self.graft_defs, function(a,b) return (a.sort_key or 0) < (b.sort_key or 0) end)
    return result
end

local old_screen_fn = Widget.MettleCompendiumWidget.RefreshContent

function Widget.MettleCompendiumWidget:RefreshContent(...)
    local result = old_screen_fn(self, ...)
    for k, row in ipairs( self.graft_widgets ) do
        row.on_downgrade_fn = function(...) self:OnMettleDowngraded(...) end
    end
    return result
end

function Widget.MettleCompendiumWidget:OnMettleDowngraded( graft_id, level )
    if TheGame:GetGameState() then
        return -- Can only do it outside of a game to prevent save scumming exploits
    end
    level = level - 1

    local character = self.series_filter_group:GetSelected():GetAgent()

    local mettle_def = Content.GetGraft( graft_id )
    local upgrades = TheGame:GetGameProfile():GetMettleUpgrades( character.id )
    local current_level = upgrades[graft_id] or 0
    local cost = 0
    for i = level + 1, current_level do
        cost = cost + (mettle_def.upgrade_costs[i] or 0)
    end
    -- Confirm acquisition
    TheGame:FE():PushScreen(
        Screen.YesNoPopup( "Undo Mettle Upgrade?", loc.format("Downgrade to level {1} and gain <#METTLE>{2#thousands}</> <p img='UI/mettle_screen.tex' scale=0.8>", level, cost) )
            :SetFn(
                function(res)
                    if res == Screen.YesNoPopup.YES then
                        -- Gain mettle
                        TheGame:GetGameProfile():AddMettlePointsOutOfGame( character.id, cost, graft_id )
                        -- Backtrack upgrade
                        TheGame:GetGameProfile():BuyMettleUpgrade( character.id, graft_id, level > 0 and level or nil )

                        -- local handler = self.owner:GetAspect("mettle_handler")

                        -- if handler then
                        --     handler:VerifyUpgrades()
                        -- end

                        -- -- Get available mettle
                        local mettle = TheGame:GetGameProfile():GetMettlePoints( character.id )
                        self.mettle_count:SetText( loc.format( LOC"UI.CARDCOMPENDIUM.METTLE_AMOUNT", character:GetName(), mettle ) )

                        -- Get owned upgrades
                        local upgrades = TheGame:GetGameProfile():GetMettleUpgrades( character.id )

                        -- Refresh all rows
                        for k, row in ipairs( self.graft_widgets ) do
                            local upgraded_level = upgrades[row.def.id] or 0
                            row:SetCurrentMettle(mettle)
                                :SetCurrentLevel(upgraded_level)
                        end

                    end
                end
            )
        )
end

function GameProfile:AddMettlePointsOutOfGame( character_id, points, source )
    local mettle_points = self:GetSetting( "mettle_points" )
    mettle_points[character_id] = (mettle_points[character_id] or 0) + points
    self.dirty = true
end
