require("resources/comms/human_command.lua")
require("resources/comms/human_merchant.lua")
require("resources/comms/human_mission_broker.lua")
require("resources/comms/human_upgrade_broker.lua")
require("resources/comms/human_hail.lua")

function MyPlayer(player)
    local player = player or PlayerSpaceship()

    Player:withStorage(player)
    Player:withStorageDisplay(player)

    Player:withMissionTracker(player)
    Player:withMissionDisplay(player)
    Player:withUpgradeTracker(player)
    Player:withUpgradeDisplay(player)

    return player
end

function MySpaceStation(station)
    local station = station or SpaceStation()

    Station:withUpgradeBroker(station)

    Station:withComms(station)
    station:setHailText(humanStationHail)
    station:addComms(humanMerchantComms)
    station:addComms(humanMissionBrokerComms)
    station:addComms(humanUpgradeBrokerComms)

    Station:withTags(station)

    return station
end

function MyCpuShip(ship)
    local ship = ship or CpuShip()

    Ship:withCaptain(ship, Person:newHuman())

    Ship:withComms(ship)
    ship:setHailText(humanShipHail)
    ship:addComms(humanCommandComms)

    Ship:withTags(ship)

    return ship
end

function KraylorSpaceStation(station)
    local station = station or SpaceStation()
    station:setFaction("Kraylor")

    return station
end
function KraylorCpuShip(ship)
    local ship = ship or CpuShip()
    ship:setFaction("Kraylor")

    return ship
end

function MyMiner(size)
    size = size or math.random(1,3)
    local ship = CpuShip():setTemplate("Goods Freighter " .. size):setFaction("Independent")
    ship:setBeamWeapon(0, 30, 0, 2000, 20, 20) -- it is slow firing, but strong
    ship:setDescription("Das Schiff sieht ausgemergelt und verschmutzt aus.")

    return ship
end
