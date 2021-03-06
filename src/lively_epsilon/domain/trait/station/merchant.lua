Station = Station or {}
-- enhances a station with the possibility to buy and sell products
Station.withMerchant = function (self, station, configuration)
    if not isEeStation(station) then
        error ("Expected a station but got " .. type(station), 2)
    end
    if not Station:hasStorage(station) then
        error ("station " .. station:getCallSign() .. " needs to have a storage configured", 2)
    end

    if Station:hasMerchant(station) then
        -- @TODO: ???
        error("can not reconfigure merchant", 2)
    end

    if type(configuration) ~= "table" then
        error("Expected a table with configuration, but got " .. type(configuration), 2)
    end

    local merchant = {}

    for product, conf in pairs(configuration) do
        local productId = Product:toId(product)

        if not station:canStoreProduct(product) then
            error("there is no storage for " .. product .. " configured in " .. station:getCallSign(), 2)
        end

        if conf.buyingPrice == nil and conf.sellingPrice == nil then
            error("configuration for " .. product .. " either needs a buyingPrice or a sellingPrice", 3)
        elseif conf.buyingPrice ~= nil and conf.sellingPrice ~= nil then
            error("configuration for " .. product .. " can only have a buyingPrice or a sellingPrice - not both", 3)
        elseif conf.buyingPrice ~= nil then
            local buyingPriceFunc
            if isNumber(conf.buyingPrice) or isNil(conf.buyingPrice) then
                buyingPriceFunc = function() return conf.buyingPrice end
            elseif isFunction(conf.buyingPrice) then
                buyingPriceFunc = conf.buyingPrice
            else error("buyingPrice needs to be a number or a function", 4)
            end
            merchant[productId] = {
                product = product,
                buyingPrice = buyingPriceFunc,
                buyingLimit = conf.buyingLimit or nil
            }
        elseif conf.sellingPrice ~= nil then
            local sellingPriceFunc
            if isNumber(conf.sellingPrice) or isNil(conf.sellingPrice) then
                sellingPriceFunc = function() return conf.sellingPrice end
            elseif isFunction(conf.sellingPrice) then
                sellingPriceFunc = conf.sellingPrice
            else error("sellingPrice needs to be a number or a function", 4)
            end
            merchant[productId] = {
                product = product,
                sellingPrice = sellingPriceFunc,
                sellingLimit = conf.sellingLimit or nil
            }
        end
    end

    local function getBuying(product, seller)
        product = Product:toId(product)
        local conf = merchant[product]
        if conf == nil or isNil(conf.buyingPrice) or isNil(conf.buyingPrice(station, seller)) then
            return nil
        else
            return conf
        end
    end

    local function getSelling(product, buyer)
        product = Product:toId(product)
        local conf = merchant[product]
        if conf == nil or isNil(conf.sellingPrice) or isNil(conf.sellingPrice(station, buyer)) then
            return nil
        else
            return conf
        end
    end

    station.getProductBuyingPrice = function (self, product, seller)
        local buying = getBuying(product, seller)

        if buying == nil then
            return nil
        elseif type(buying.buyingPrice) == "function" then
            return buying.buyingPrice(station, seller)
        else
            return buying.buyingPrice
        end
    end

    station.getMaxProductBuying = function (self, product, seller)
        local buying = getBuying(product, seller)

        if buying == nil then
            return nil
        else
            local limit = self:getMaxProductStorage(product)
            if isNumber(buying.buyingLimit) then
                limit = buying.buyingLimit
            end

            if limit <= self:getProductStorage(product) then
                return 0
            else
                return limit - self:getProductStorage(product)
            end
        end
    end

    station.isBuyingProduct = function (self, product, seller)
        return self:getProductBuyingPrice(product, seller) ~= nil
    end

    station.getProductsBought = function (self, seller)
        local products = {}

        for productId, merchant in pairs(merchant) do
            if self:isBuyingProduct(productId, seller) then
                products[productId] = merchant.product
            end
        end

        return products
    end

    station.getProductSellingPrice = function (self, product, buyer)
        local selling = getSelling(product, buyer)

        if selling == nil then
            return nil
        elseif type(selling.sellingPrice) == "function" then
            return selling.sellingPrice(station, buyer)
        else
            return selling.sellingPrice
        end
    end

    station.getMaxProductSelling = function (self, product, buyer)
        local selling = getSelling(product, buyer)

        if selling == nil then
            return nil
        else
            local limit = 0
            if isNumber(selling.sellingLimit) then
                limit = selling.sellingLimit
            end

            if limit >= self:getProductStorage(product) then
                return 0
            else
                return self:getProductStorage(product) - limit
            end
        end
    end

    station.isSellingProduct = function (self, product, buyer)
        return self:getProductSellingPrice(product, buyer) ~= nil
    end

    station.getProductsSold = function (self, buyer)
        local products = {}

        for productId, merchant in pairs(merchant) do
            if self:isSellingProduct(productId, buyer) then
                products[productId] = merchant.product
            end
        end

        return products
    end

end

--- checks if the given object has a merchant that buys or sells stuff
-- @param station
-- @return boolean
Station.hasMerchant = function(self, station)
    return isFunction(station.getProductBuyingPrice) and
            isFunction(station.getMaxProductBuying) and
            isFunction(station.isBuyingProduct) and
            isFunction(station.getProductsBought) and
            isFunction(station.getProductSellingPrice) and
            isFunction(station.getMaxProductSelling) and
            isFunction(station.isSellingProduct) and
            isFunction(station.getProductsSold)
end