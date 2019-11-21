# * KyoDiscounts XP - Unique Wyvern Version
#   Scripter : Kyonides-Arkanthes
#   v1.8.3 - 2019-07-22

#   Whenever you obtain a discount card, such discount will be applied to all
#   of your purchases if you have picked a card till it expires after a certain
#   number of steps. Additional steps will be quickly added to your current card
#   whenever you purchase any additional card of the same kind.

#   One coupon will be spent every single time you purchase any specific item,
#   you will need another one to purchase a different item later on.
#   The discount card or coupon price is used to calculate the corresponding
#   discount on every single purchase the player makes with it.

#   Place this script below KItemRefill XP or KyoScriptPack Item XP if you
#   included any of those scripts in your current game project.

#   Now you can also setup exclusive store discount cards as well. Just keep in
#   mind that you will need to setup the in game variable you picked so it will
#   be able to store the Exclusive Store Code (an Integer) before you can add
#   the shop event command. Common stores don't need any Store Code at all.

#   Besides the player can also place orders to get an item that is supposed to
#   be found at another store only. The player will be charged an extra fee, but
#   he or she won't need to go back to another store. The player would only need
#   to keep walking for a while before the goods are available at the store.
#   Now the required steps for each placed order will be automatically increased
#   between 0% and 50%, making it look a bit random but also kind of realistic.

# * Unknown Item or Weapon or Armor Appraisals *

#   Use the Game Variable defined in the STORECODEVARID Constant to store the
#   Shop ID that will include the appraisal service.
#   Use the MYSTERIOUS series of Arrays to include as many IDs of unknown items
#   or weapons or armors that will serve as fillers till they get replaced by
#   the actual goods they represent.
#   Follow the Instructions included in the APPRAISALS Hash to define all
#   conditions that will affect an appraiser's task of identifying the item.

#   Script Calls   #

#   $game_party.discount_cards_expire
#     Makes all Discount Cards expire as part of the game's plot.

#   $game_party.disc_card_expire(Card_ID)
#     Makes an specific Discount Card expire as part of the game's plot.

#   KyoShopOrders << [Percent1, Percent2, etc.]
#     Defines a Commission percent for every Item in the Place Order List.

#   KyoShopOrders.steps = [Steps1, Steps2, etc.]
#   KyoShopOrders.steps += [Steps5, Steps6, etc.]
#     Defines Steps required by every Order in the Place Order List.
#     The 2nd call will be required only if you couldn't include all steps.

#   KyoShop.id = Number
#     It lets you assign a store ID directly instead of using an event command.

#   KyoShop.no_card_sale = true or false
#     It defines whether or not the player can sell cards and coupons.

#   KyoShop.no_coupon_sale = true or false
#     It defines whether or not the player can sell coupons.

#   KyoShop.scarce_lvl = 0 or higher
#     Define all prices and maximum number of units per shop item.
#     0 means no scarcity, 1 or higher reflects how severe it is.
#     You also have to configure the @scarce_limits hash in order to predefine
#     :price and :max per scarcity level. The maximum scarcity level depends on
#     how many values you entered in both :price and :max arrays.
#     In few words, you define the maximum scarcity level ever possible!

#   KyoShop.scarce_orders = true or false
#     It tells the script whether or not the number of orders gets decreased in
#     case scarcity is supposed to overwhelm your tired heroes.

#   $game_system.setup_unique_shop_items
#     It will let you reset all of the Unique Shop Items Settings.

#   $game_system.reset_shop_items(ShopID)
#     It will let you reset a single shop's Unique Shop Items Settings.

module KyoShop
  # Maximum number of units for each shop item
  NUMBERMAX = 99
  # Button that will open the Detailed Item Data Window
  ITEMDATABUTTON = Input::CTRL
  # Button that will open the Discount window while on the shop menu
  DISCOUNTBUTTON = Input::A
  # Add Discount Card Object IDs
  DISCOUNT_IDS = [33, 34]
  # Add Discount Coupon Object IDs
  COUPON_IDS = [36, 37]
  # Maximum Steps before Discount Card expires : ID => Steps
  STEPS = { 33 => 500, 34 => 300, 35 => 150 }
  # Exclusive Stores List : Object ID => Exclusive Store Code
  EXCLUSIVESTORES = { 35 => 102 }
  # Exclusive Stores In Game Variable ID
  STORECODEVARID = 1
  # Switch ID : deactivates Store to add Goods found elsewhere in your game
  # The script will turn off the switch automatically. This means you actually
  # use two consecutive shop processing event commands to first set the items
  # the player will be able to order and then the items he can buy right away.
  GOODSSWITCHID = 1
  # Switch ID that enables displaying the sale price modifier on screen
  SALEPRICESWID = 2
  # Investment: ShopID => [Maximum Number of Shares, Share Price], etc.
  SHARESMAXNPRICE = { 101 => [10000, 100] }
  SHARESMAXNPRICE.default = [5000, 50]
  INVESTMENTS = {} # Store Investments - Do Not Edit This Line
  # Available Improvements #
  # :discount : [:discount, 25]
  # :goods    : [:goods, 'i10', 'w4', 'a6']
  # :orders   : [:orders, 'i11', 'w5', 'a7']
  # [Store ID] = { Shares => Prize, Shares => Another Prize, etc. }
  INVESTMENTS[101] = { 50 => [:goods,'i10','w5','a6'], 100 => [:discount,10] }
  # Add Item IDs for unknown shop goods that need to be appraised by experts
  MYSTERIOUSITEMS = [39,40,41]
  # Add Weapon IDs for unknown shop goods that need to be appraised by experts
  MYSTERIOUSWEAPONS = []
  # Add Armor IDs for unknown shop goods that need to be appraised by experts
  MYSTERIOUSARMORS = []
  @scarce_limits = {
    # PriceIncreases => [Percent1, etc.],
    :price  => [0, 110, 120, 135, 155, 200, 250, 310, 500],
    :max => [NUMBERMAX, NUMBERMAX - 10, NUMBERMAX - 25, NUMBERMAX - 35,
        NUMBERMAX - 50, NUMBERMAX - 65, NUMBERMAX - 80, NUMBERMAX - 90, 1]
  }
  @scarce_lvl = 0 # Initial Level
  # Apply Decrease in Max No. of orders of a single item during scarcity?
  @scarce_orders = false
  SALE_PRICE_MODIFIER = {} # Do Not Edit This Line!
  # ShopID => Percent (An Integer) - Cannot be 0!
  SALE_PRICE_MODIFIER[101] = 70
  # Allow the player to sell cards?
  @no_card_sale = true # true or false
  # Allow the player to sell coupons?
  @no_coupon_sale = true # true or false
end

module KyoShopLabels
  # Basic Shop Command Labels
  BASIC = ["Buy", "Sell", "Exit"]
  MOREOPTIONS = "Options"
  # Buy Stuff & Place Order & Pick Up Items Label
  BUYPLACEPICKUP = { :purchase => 'Buy Items',
                     :place    => 'Place Order',
                     :pickup   => 'Pick Up Items',
                     :appraise => 'Appraise',
                     :invest   => 'Invest' }
  # Press ItemDataButton to retrieve more information
  PRESSITEMDATABUTTON = 'LEFT or RIGHT to refresh data'
  NOINFOAVAILABLE = "No information available"
  OLDEQUIPMENT = "Equipped"
  NEWEQUIPMENT = "Selected"
  EVASION = "EVA"
  # Subtotal, Commission Percent and Total Amount
  PRICELABELS = ['Subtotal', 'Commission %', 'Total']
  # Total of Items of same kind you have purchased so far
  ITEMSPURCHASED = "Number in possession"
  # Place an Order Label
  PLACEORDER = 'Do you wish to place an order?'
  # Pick Up Order Label
  PICKUPORDER = 'Do you want to pick up an order?'
  # No Order Found Label
  NOORDERFOUND = 'There is nothing left, boss!'
  # Available Discounts Label
  SOMEDISCOUNTS = 'Press A to get a discount'
  # No Discount Available Label
  NODISCOUNTS = 'No Discount Available'
  # Select a Discount Card or Coupon Label
  SELECTDISCOUNT = 'Choose a Card or Coupon'
  # Apply Discount Label
  APPLYDISCOUNT = "Discount Applied %s%"
  # Warning about Extra Fees for Placing Orders
  FEESAPPLY = 'Extra Fees Apply'
  # Discount Card's Steps Left Label
  STEPSLEFT = " %s steps left."
  # Shopkeeper Pays Back Label :P
  SHOPKEEPERPAYSBACK = "Pays back"
  # Investment Label...
  INVESTMENT = 'Want to invest in this store?'
  # Share Number Label
  SHARES = 'Share Number'
  # Maximum Number of Shares for a specific Store
  SHARESMAX = 'Shares Maximum'
  # Adquired or Purchased Shares Label
  SHARESTOTAL = 'Total Shares'
  # Pick Item to be Appraised Label
  APPRAISALMENULABEL = "Appraisal Menu"
  # Appraisal Window Labels
  APPRAISALLABELS = ["Quick Test Cost", "Normal Cost"]
  # Appraisal Options Labels
  APPRAISALOPTIONS = ["Quick Test", "Detailed Test", "Cancel"]
  # Purchase Offer and Haggle Labels
  APPRAISALHAGGLEOPTIONS = ["Accept", "Haggle", "Decline"]
  # Appraisal End Result Labels
  APPRAISALRESULTLABELS = [
    "The item at hand is nothing else but... %s",
    "I think it might be worth some... %s",
    "I've been searching for some %s!",
    "Now I want to make a deal.",
    "What if I make a better offer?",
    "Would you accept some %s?",
    "I'm sorry but I'm not an expert at appraising some %s"
  ]
  ITEMATTRIBUTES = ['Scope', 'Occasion', 'Healing Stats', 'HP %', 'HP', 'SP %',
                    'SP', 'Other Stats', 'PDEF', 'MDEF']
  ITEMSCOPE = ['None', 'One Enemy', 'All Enemies', 'One Ally', 'All Allies',
               'One Dead Ally','All Dead Allies', 'User']
  ITEMOCCASION = ['Always', 'Only in Battle', 'Only from the Menu', 'Never']
  ITEMPARAMETERS = ['Increase', 'MAXHP', 'MAXSP']
end
# Do Not Edit Anything Else!
module KyoShop
  class UniqueItem
    def initialize(new_max) @max, @total = new_max, 0 end
    def max() @max end
    attr_accessor :total
  end

  class UniqueItems
    def initialize
      @data = {}
      @step_max = 0
      @unit_max = 0
    end
    def data() @data end
    def reset() @data.each_value {|item| item.total = 0 } end
    def [](key) @data[key] end
    def []=(key, value) @data[key] = value end
    attr_accessor :step_max, :unit_max
  end
  UNIQUESHOPITEMS = load_data('Data/KyoDiscountsUniqueItems.rxdata')
  @appraisals = load_data('Data/KyoDiscountsAppraisals.rxdata')
  @options = []
  module_function
  def custom_prices() CUSTOMPRICES[@id] end
  def random_prices?() CUSTOMPRICES[@id][:random] end
  def current_item_max() @scarce_limits[:max][@scarce_lvl] end
  def current_price_max() @scarce_limits[:price][@scarce_lvl] end
  def get_order_max() @scarce_orders ? current_item_max : NUMBERMAX end
  def disc_store?(disc_id) !EXCLUSIVESTORES[disc_id] end
  def excl_disc_store?(disc_id) @id == EXCLUSIVESTORES[disc_id] end
  def no_card_sale?(cid) @no_card_sale and DISCOUNT_IDS.include?(cid) end
  def no_coupon_sale?(cid) @no_coupon_sale and COUPON_IDS.include?(cid) end
  def set_random_percent
    prices = CUSTOMPRICES[@id]
    perc_min = prices[:min]
    version = RUBY_VERSION.scan(/\d+/)[0].to_i
    if version > 1
      @random_percent = rand(perc_min..(prices[:max] + 1))
    else
      @random_percent = perc_min + rand(prices[:max] - perc_min + 1)
    end
  end
  class << self
    attr_accessor :id, :scarce_lvl, :scarce_orders, :options
    attr_accessor :no_card_sale, :no_coupon_sale, :random_percent
    attr_reader :appraisals, :options, :scarce_limits
  end
  INVESTMENTS.default = {} # No Editar Esta Línea
  CUSTOMPRICES = load_data('Data/KyoDiscountsCustomPrices.rxdata')
  CUSTOMPRICES.default = { 0 => {}, 1 => {}, 2 => {}, :random => false,
                           :min => 0, :max => 0 }
  SALE_PRICE_MODIFIER.default = 50
  @id = 0
  @random_percent = 0
end

module KyoShopOrders
  @commissions = []
  @steps = []
  class << self
    attr_accessor :store_event_id, :goods_id
    attr_reader :steps, :commissions
    def steps=(val) @steps = val.map {|n| n + rand((n / 2) + 2) } end
    def <<(val)
      @commissions += val
      @commissions = @commissions.flatten
    end
  end
end

module KScripts
  @names ||= []
  @names << :kyodiscounts
  def self.names() @names end
end

class RPG::Item
  def price
    new_price = KyoShop.custom_prices[0][@id] || 0
    @price + new_price #(new_price ? new_price : 0)
  end
  def type_index() 0 end
  def type() :item end
end

class RPG::Weapon
  def price
    new_price = KyoShop.custom_prices[1][@id] || 0
    @price + new_price #(new_price ? new_price : 0)
  end
  def type_index() 1 end
  def type() :weapon end
end

class RPG::Armor
  def price
    new_price = KyoShop.custom_prices[2][@id] || 0
    @price + new_price #(new_price ? new_price : 0)
  end
  def type_index() 2 end
  def type() :armor end
  alias element_set guard_element_set
end

module WindowModule
  def appear
    self.active = true
    self.visible = true
  end

  def disappear
    self.active = false
    self.visible = false
  end
end

class Game_System
  attr_accessor :shop_goods
  attr_reader :placed_orders, :shop_shares, :shop_favors
  alias kyon_discounts_gm_sys_init initialize
  def initialize
    kyon_discounts_gm_sys_init
    @shop_goods = []
    @placed_orders = {}
    @shop_shares = {}
    @shop_favors = {}
    @placed_orders.default = []
    @shop_shares.default = 0
    @shop_favors.default = 0
    setup_unique_shop_items
  end

  def setup_unique_shop_items
    @unique_items = {}
    KyoShop::UNIQUESHOPITEMS.each do |shop_id, this_shop|
      @unique_items[shop_id] = shop = KyoShop::UniqueItems.new
      shop.step_max = this_shop.step_max
      shop.unit_max = this_shop.unit_max
      this_shop.data.each do |key, item_data|
        shop[key] = KyoShop::UniqueItem.new(item_data.max)
      end
    end
  end

  def reset_shop_items(shop_id) @unique_items[shop_id].reset end

  def check_shares(shop_id)
    results = []
    shares = @shop_shares[shop_id]
    investments = KyoShop::INVESTMENTS[shop_id]
    limits = KyoShop::INVESTMENTS[shop_id].keys.sort
    results = investments.select{|limit| shares >= limit[0] }.map {|r| r[1] }
  end

  def buy_unique_item(shop_id, item, number)
    return unless (items = @unique_items[shop_id])
    key = [item.type_index, item.id]
    if (item = items[key])
      return if item.max < item.total + number
      return items[key].total = number
    end
    return if items.unit_max == 0
    @unique_items[shop_id][key] = it = KyoShop::UniqueItems.new(items.unit_max)
    it.total = number
  end

  def unique_item_max(shop_id, item)
    return KyoShop::NUMBERMAX unless @unique_items[shop_id]
    key = [item.type_index, item.id]
    switch = @unique_items[shop_id][key] || @unique_items[shop_id].unit_max
    switch == 0 ? KyoShop::NUMBERMAX : switch.max - switch.total
  end

  def shop_block_item?(shop_id, item)
    return unless (unique = @unique_items[shop_id])
    data = unique[[item.type_index, item.id]]
    data ? (data.total == data.max) : nil
  end
end

class Game_Party
  attr_reader :discounts
  alias kyon_discounts_gm_party_init initialize
  def initialize
    @discounts = {}
    kyon_discounts_gm_party_init
  end

  def reset_discount_item(item, n)
    return if item.type != :item or n == 0
    item_id = item.id
    return unless KyoShop::DISCOUNT_IDS.include?(item_id)
    if @discounts[item_id]
      @discounts[item_id] += KyoShop::STEPS[item_id]
      @items[item_id] = 1
    else
      @discounts[item_id] = KyoShop::STEPS[item_id]
    end
  end

  def check_discounts
    unless @discounts.empty?
      for did in KyoShop::DISCOUNT_IDS
        next unless @discounts[did] and @discounts[did] > 0
        return true if KyoShop.disc_store?(did)
        return true if KyoShop.excl_disc_store?(did)
      end
    end
    for cid in KyoShop::COUPON_IDS
      next unless item_number(cid) > 0
      return true if KyoShop.disc_store?(cid)
      return true if KyoShop.excl_disc_store?(cid)
    end
    return false
  end

  def decrease_discounts
    KyoShop::DISCOUNT_IDS.each {|n| next unless @discounts[n]
      @discounts[n] -= 1 if @discounts[n] > 0 }
  end

  def discount_cards_expire
    KyoShop::DISCOUNT_IDS.each {|n| @discounts[n] = 0 if @discounts[n] }
  end
  def disc_card_expire(dc_id) @discounts[dc_id] = 0 end
end

class Game_Event
  def name() @event.name end
end

class Game_Player
  alias kyon_discounts_coupons_gm_player_increase_steps increase_steps
  def increase_steps
    kyon_discounts_coupons_gm_player_increase_steps
    $game_party.decrease_discounts
  end
end

class Window_Selectable
  include WindowModule
end

class Window_Help
  def initialize
    super(0, 0, Graphics.width, 64)
    self.contents = Bitmap.new(width - 32, height - 32)
  end

  def set_text(item_id, text=nil, align=0)
    if item_id.is_a?(String)
      if KyoShop::DISCOUNT_IDS.include?(KyoShopOrders.goods_id)
        steps = $game_party.discounts[KyoShopOrders.goods_id].to_s
        text = item_id + sprintf(KyoShopLabels::STEPSLEFT, steps)
        KyoShopOrders.goods_id = item_id = nil
      end
    end
    if text.is_a?(String)
      text = text.gsub(/\\[Uu]/){$game_system.refill_items[item_id].sips.to_s}
    elsif text.is_a?(Integer)
      align = text
      text = item_id
    else
      text = item_id
    end
    if text != @text or align != @align
      self.contents.clear
      self.contents.font.color = normal_color
      self.contents.draw_text(4, 0, self.width - 40, 32, text, align)
      @text = text
      @align = align
      @actor = nil
    end
    self.visible = true
  end
end

class Window_Item
  alias kyon_discounts_win_item_up_help update_help
  def update_help
    it = self.item
    KyoShopOrders.goods_id = it.id if it
    kyon_discounts_win_item_up_help
  end
end

class AppraiseItemWindow < Window_Selectable
  def initialize
    super(0, 64, 480, 320)
    @column_max = 1
    refresh
    self.index = 0
  end

  def refresh
    self.contents.clear if self.contents != nil
    @data = []
    for n in KyoShop::MYSTERIOUSITEMS
      next if $game_party.item_number(n) == 0
      @data << $data_items[n]
    end
    for i in KyoShop::MYSTERIOUSWEAPONS
      next if $game_party.weapon_number(i) == 0
      @data << $data_weapons[i]
    end
    for i in KyoShop::MYSTERIOUSARMORS
      next if $game_party.armor_number(i) == 0
      @data << $data_armors[i]
    end
    @item_max = @data.size
    return if @item_max == 0
    self.contents = Bitmap.new(width - 32, row_max * 32)
    @item_max.times{|i| draw_item(i) }
  end

  def draw_item(index)
    item = @data[index]
    number = case item
    when RPG::Item then $game_party.item_number(item.id)
    when RPG::Weapon then $game_party.weapon_number(item.id)
    when RPG::Armor then $game_party.armor_number(item.id)
    end
    c = self.contents
    x = 4 + index * (288 + 32)
    y = index * 32
    rect = Rect.new(x, y, self.width / @column_max - 32, 32)
    c.fill_rect(rect, Color.new(0, 0, 0, 0))
    bit = RPG::Cache.icon(item.icon_name)
    c.blt(x, y + 4, bit, Rect.new(0, 0, 24, 24), 255)
    c.draw_text(x + 28, y, 212, 32, item.name, 0)
    c.draw_text(x + 240, y, 16, 32, ":", 1)
    c.draw_text(x + 256, y, 24, 32, number.to_s, 2)
  end
  def item() @data[@index] end
  def empty?() @data.empty? end
end

class AppraiseInfoWindow < Window_Base
  def initialize(store_id)
    super(480, 128, 160, 256)
    @data = KyoShop.appraisals[store_id]
    @labels = KyoShopLabels::APPRAISALLABELS.dup
    @currency = $data_system.words.gold
    self.contents = Bitmap.new(width - 32, height - 32)
    refresh
  end

  def refresh
    aw = width - 32
    contents.clear
    contents.font.color = system_color
    contents.draw_text(0, 0, aw, 24, @labels[0])
    contents.draw_text(0, 48, aw, 24, @labels[1])
    contents.draw_text(0, 24, aw, 24, @currency, 2)
    contents.draw_text(0, 72, aw, 24, @currency, 2)
    contents.font.color = normal_color
    contents.draw_text(0, 24, width - 48, 24, @data[:test_cost].to_s, 2)
    contents.draw_text(0, 72, width - 48, 24, @data[:cost].to_s, 2)
  end
end

class AppraiseResultWindow < Window_Base
  def initialize
    super(0, 384, 640, 96)
    @labels = KyoShopLabels::APPRAISALRESULTLABELS.dup
    @currency = $data_system.words.gold
    self.contents = Bitmap.new(width - 32, height - 32)
  end

  def refresh(item)
    contents.clear
    pr = item.price
    pr += pr * KyoShop.random_percent / 100 if KyoShop.random_prices?
    result = sprintf(@labels[0], item.name)
    cost = sprintf(@labels[1], pr) + " " + @currency
    contents.draw_text(0, 0, width - 32, 24, result)
    contents.draw_text(0, 24, width - 32, 24, cost)
  end

  def ask_favor(item)
    contents.clear
    result = sprintf(@labels[2], item.name)
    contents.draw_text(0, 0, width - 32, 24, result)
    contents.draw_text(0, 24, width - 32, 24, @labels[3])
  end

  def make_offer(overprice)
    contents.clear
    result = sprintf(@labels[5], overprice) + " " + @currency
    contents.draw_text(0, 0, width - 32, 24, @labels[4])
    contents.draw_text(0, 24, width - 32, 24, result)
  end

  def cannot_appraise(item)
    contents.clear
    result = sprintf(@labels[6], item.name)
    contents.draw_text(0, 24, width - 32, 24, result)
  end
end

class Window_ShopCommand
  def initialize
    super(0, 64, 480, 64)
    self.contents = Bitmap.new(width - 32, height - 32)
    @item_max = 3
    @column_max = 3
    @commands = KyoShopLabels::BASIC.dup
    @commands[0] = KyoShopLabels::MOREOPTIONS unless KyoShop.options.empty?
    refresh
    self.index = 0
  end
end

class Window_ShopBuy
  attr_accessor :discount
  def initialize(shop_goods)
    super(0, 128, 368, Graphics.height - 192)
    @shop_goods = shop_goods
    @discount = 0
    refresh
    self.index = 0
  end

  def deliver(goods)
    @shop_goods = goods
    if goods.size - 1 < @index
      @index = goods.size > 0 ? (@index + goods.size - 1) % goods.size : 0
      update_cursor_rect
    end
    refresh
    self.index = 0
  end

  def draw_item(index)
    item = @data[index]
    number = case item.type
    when :item then $game_party.item_number(item.id)
    when :weapon then $game_party.weapon_number(item.id)
    when :armor then $game_party.armor_number(item.id)
    end
    c = self.contents
    pr = item.price
    pr += pr * KyoShop.random_percent / 100 if KyoShop.random_prices?
    enough = (pr <= $game_party.gold and KyoShop::NUMBERMAX > number)
    if enough and !$game_system.shop_block_item?(KyoShop.id, item)
      c.font.color = normal_color
      opacity = 255
    else
      c.font.color = disabled_color
      opacity = 128
    end
    y = index * 32
    rect = Rect.new(4, y, self.width - 32, 32)
    c.fill_rect(rect, Color.new(0, 0, 0, 0))
    bitmap = RPG::Cache.icon(item.icon_name)
    c.blt(4, y + 4, bitmap, Rect.new(0, 0, 24, 24), opacity)
    c.draw_text(32, y, 212, 32, item.name, 0)
    end_price = pr - pr * @discount / 100
    c.draw_text(244, y, 88, 32, end_price.to_s, 2)
  end
end

class Window_ShopPickUp < Window_ShopBuy
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    @data = []
    for good in @shop_goods
      new_item = case good[0]
      when 0 then $data_items[good[1]]
      when 1 then $data_weapons[good[1]]
      when 2 then $data_armors[good[1]]
      end
      @data << new_item if new_item
    end
    @item_max = @data.size
    return if @item_max == 0
    self.contents = Bitmap.new(width - 32, row_max * 32)
    (0...@item_max).each {|i| draw_item(i) }
  end

  def draw_item(index)
    item = @data[index]
    qty, steps = @shop_goods[index][2..3]
    number = case item
    when RPG::Item then $game_party.item_number(item.id)
    when RPG::Weapon then $game_party.weapon_number(item.id)
    when RPG::Armor then $game_party.armor_number(item.id)
    end
    enough = (number + qty < 100 and steps <= $game_party.steps)
    self.contents.font.color = enough ? normal_color : disabled_color
    y = index * 32
    rect = Rect.new(4, y, self.width - 32, 32)
    self.contents.fill_rect(rect, Color.new(0, 0, 0, 0))
    bitmap = RPG::Cache.icon(item.icon_name)
    opacity = enough ? 255 : 128
    self.contents.blt(4, y + 4, bitmap, Rect.new(0, 0, 24, 24), opacity)
    self.contents.draw_text(32, y, 212, 32, item.name, 0)
    self.contents.draw_text(244, y, 88, 32, qty.to_s, 2)
  end
  undef discount, discount=
end

class Window_ShopNumber
  include WindowModule
  attr_writer :mode
  def initialize
    super(0, 128, 368, Graphics.height - 192)
    self.contents = Bitmap.new(width - 32, height - 32)
    @item = nil
    @max = 1
    @price = 0
    @number = @mode == :invest ? 0 : 1
    @multiplier = 1
  end

  def reset_multiplier
    @multiplier = 1
    @number = @mode == :invest ? 0 : 1
    refresh
  end

  def set(item, max, price, percent=nil, multiplier=1)
    @item = item
    @max = max
    @price = price
    @number = @mode == :invest ? 0 : 1
    @multiplier = multiplier
    @percent = percent
    refresh
  end

  def update
    super
    return unless self.active
    if Input.repeat?(Input::RIGHT) and @number < @max
      $game_system.se_play($data_system.cursor_se)
      @number += @multiplier
      refresh
    end
    if Input.repeat?(Input::LEFT) and @number > @multiplier
      $game_system.se_play($data_system.cursor_se)
      @number -= @multiplier
      refresh
    end
    if Input.repeat?(Input::UP) and @number < @max
      $game_system.se_play($data_system.cursor_se)
      @number = [@number + 10 * @multiplier, @max].min
      refresh
    end
    if Input.repeat?(Input::DOWN) and @number > @multiplier
      $game_system.se_play($data_system.cursor_se)
      @number = [@number - 10 * @multiplier, 1].max
      refresh
    end
  end

  def refresh
    c = self.contents
    c.clear
    draw_item_name(@item, 4, 96)
    c.font.color = normal_color
    if @multiplier == 1
      cx1, cx2, cx3, cw1, cw2 = [272, 308, 304, 24, 32]
    else
      cx1, cx2, cx3, cw1, cw2 = [260, 264, 272, 68, 64]
    end
    c.draw_text(cx1, 96, 32, 32, "")
    c.draw_text(cx2, 96, cw1, 32, @number.to_s, 2)
    self.cursor_rect.set(cx3, 96, cw2, 32)
    gold = $data_system.words.gold
    cx = contents.text_size(gold).width
    stotal = @item.price * @number
    stotal += stotal * KyoShop.random_percent / 100 if KyoShop.random_prices?
    total_price = @price * @number
    labels = KyoShopLabels::PRICELABELS
    if total_price > stotal and @multiplier < 2
      c.font.color = system_color
      c.draw_text(120, 128, 100, 32, labels[0], 2)
      c.draw_text(332-cx, 128, cx, 32, gold, 2)
      c.draw_text(80, 160, 140, 32, labels[1], 2)
      c.draw_text(328-cx, 160, cx + 4, 32, '%', 2)
      c.font.color = normal_color
      c.draw_text(4, 128, 328-cx-2, 32, stotal.to_s, 2)
      c.draw_text(4, 160, 328-cx-2, 32, @percent.to_s, 2)
    end
    if $game_switches[KyoShop::SALEPRICESWID] and @mode == :sale
      c.draw_text(126, 160, 110, 32, KyoShopLabels::SHOPKEEPERPAYSBACK, 2)
      c.draw_text(236, 160, 100, 32, @percent.to_s + '%', 2)
    end
    c.draw_text(4, 192, 328-cx-2, 32, total_price.to_s, 2)
    c.font.color = system_color
    c.draw_text(120, 192, 100, 32, labels[2], 2)
    c.draw_text(332-cx, 192, cx, 32, gold, 2)
  end
end

class Window_ShopBuyOptions < Window_Selectable
  def initialize
    options = KyoShop.options
    c = KyoShopLabels::BUYPLACEPICKUP
    @commands = [c[:purchase]]
    @options = [:purchase]
    if options.include?(:place)
      @commands << c[:place] << c[:pickup]
      @options << :place << :pickup
    end
    if options.include?(:appraise)
      @commands << c[:appraise].dup
      @options << :appraise
    end
    if KyoShop::SHARESMAXNPRICE.keys.include?(KyoShop.id)
      @commands << c[:invest].dup
      @options << :invest
    end
    super(206, 148, 220, @options.size * 32 + 32)
    @item_max = @options.size
    self.contents = Bitmap.new(self.width - 32, @item_max * 32)
    refresh
    self.index = 0
  end

  def refresh
    contents.clear
    @item_max.times {|i| draw_item(i, normal_color) }
  end

  def draw_item(pos, color)
    c = self.contents
    c.font.color = color
    rect = Rect.new(4, 32 * pos, c.width - 8, 32)
    c.fill_rect(rect, Color.new(0, 0, 0, 0))
    c.draw_text(rect, @commands[pos])
  end
  def option() @options[@index] end
end

class Window_ShopDiscountAlert < Window_Base
  def initialize
    wy = Graphics.height - 64
    super(0, wy, 368, 64)
    self.contents = Bitmap.new(width - 32, height - 32)
  end

  def set_text(text)
    self.contents.clear
    self.contents.draw_text(0, 0, width - 32, height - 32, text)
  end
end

class Window_ShopDiscountCoupon < Window_Selectable
  def initialize
    wh = Graphics.height == 480 ? 288 : 384
    super(0, 128, 368, wh)
    self.index = 0
    refresh
  end

  def item() @data[@index] end

  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    @data = []
    $game_party.discounts.keys.sort.each do |i|
      next if $game_party.discounts[i] == 0
      next if !KyoShop.disc_store?(i) and !KyoShop.excl_disc_store?(i)
      @data << $data_items[i]
    end
    KyoShop::COUPON_IDS.each do |i|
      next unless $game_party.item_number(i) > 0
      @data << $data_items[i]
    end
    @item_max = @data.size
    return if @item_max == 0
    self.index -= 1 if @index > @item_max - 1
    self.contents = Bitmap.new(width - 32, row_max * 32)
    (0...@item_max).each {|i| draw_item(i) }
  end

  def draw_item(index)
    item = @data[index]
    number = $game_party.item_number(item.id)
    x = 4
    y = index * 32
    rect = Rect.new(x, y, self.width - 32, 32)
    c = self.contents
    c.fill_rect(rect, Color.new(0, 0, 0, 0))
    bitmap = RPG::Cache.icon(item.icon_name)
    c.blt(x, y + 4, bitmap, Rect.new(0, 0, 24, 24), 255)
    c.draw_text(x + 28, y, 212, 32, item.name)
    c.draw_text(x + 28, y, 244, 32, ': ' + number.to_s, 2)
  end

  def update_help
    this_item = @data[@index]
    KyoShopOrders.goods_id = this_item.id
    @help_window.set_text(this_item.description)
  end
end

class Window_ShopStatus
  alias kyon_discounts_win_shop_status_refresh refresh
  def initialize
    wh = Graphics.height == 480 ? 352 : 416
    super(368, 128, 272, wh)
    self.contents = Bitmap.new(width - 32, height - 32)
    @item = nil
    refresh
  end

  def refresh
    @investment ? refresh_investment : kyon_discounts_win_shop_status_refresh
  end

  def investment=(bool)
    @investment = bool
    refresh
  end

  def refresh_investment
    c = self.contents
    c.clear
    sid = KyoShop.id
    shares = $game_system.shop_shares[sid].to_s
    c.font.color = system_color
    c.draw_text(0, 0, 240, 32, KyoShopLabels::SHARESTOTAL)
    c.draw_text(0, 28, 240, 32, KyoShopLabels::SHARESMAX)
    c.font.color = normal_color
    c.draw_text(0, 0, 240, 32, shares, 2)
    c.draw_text(0, 28, 240, 32, KyoShop::SHARESMAXNPRICE[sid][0].to_s, 2)
  end
end

class ShopDataWindow < Window_Base
  def initialize(x, y)
    super(x, y, 272, Graphics.height - 128)
    self.contents = Bitmap.new(width - 32, height - 32)
    @has_elements = KScripts.names.include?(:kelemres)
    @elements = $data_system.elements[1..-1]
    @page = 0
  end

  def item=(new_item)
    @item = new_item
    @page_max = @item.type == :item ? 2 : 3
    refresh
  end

  def refresh_page
    @page = (@page + 1) % @page_max
    refresh
  end

  def refresh
    return unless @item
    c = self.contents
    c.clear
    number = case @item.type
    when :item then $game_party.item_number(@item.id)
    when :weapon then $game_party.weapon_number(@item.id)
    when :armor then $game_party.armor_number(@item.id)
    end
    c.font.color = system_color
    c.draw_text(0, 0, 200, 24, KyoShopLabels::ITEMSPURCHASED)
    c.font.color = normal_color
    c.draw_text(204, 0, 32, 24, number.to_s, 2)
    if @item.type == :item
      case @page
      when 0 then show_item_data
      when 1 then show_elements
      end
      return
    end
    if @item.type == :weapon
      label, value = $data_system.words.atk, @item.atk.to_s
    elsif @item.type == :armor
      label, value = KyoShopLabels::EVASION, @item.eva.to_s
    end
    c.draw_text(0, 28, 240, 24, KyoShopLabels::PRESSITEMDATABUTTON, 1)
    case @page
    when 0 then show_equippable
    when 1 then show_equip_data(label, value)
    when 2 then show_elements
    end
  end

  def show_item_data
    c = self.contents
    attr = KyoShopLabels::ITEMATTRIBUTES
    c.font.color = system_color
    c.draw_text(0, 24, 100, 24, attr[0], 0)
    c.draw_text(0, 48, 100, 24, attr[1], 0)
    c.draw_text(0, 72, 240, 24, attr[2], 1)
    c.draw_text(0, 96, 60, 24, attr[3], 0)
    c.draw_text(124, 96, 60, 24, attr[4], 0)
    c.draw_text(0, 120, 60, 24, attr[5], 0)
    c.draw_text(124, 120, 60, 24, attr[6], 0)
    c.draw_text(0, 144, 240, 24, attr[7], 1)
    c.draw_text(0, 168, 60, 24, attr[8], 0)
    c.draw_text(124, 168, 60, 24, attr[9], 0)
    c.font.color = normal_color
    c.draw_text(100, 24, 140, 24, KyoShopLabels::ITEMSCOPE[@item.scope], 2)
    c.draw_text(100, 48, 140, 24, KyoShopLabels::ITEMOCCASION[@item.occasion],2)
    c.draw_text(0, 96, 116, 24, @item.recover_hp_rate.to_s, 2)
    c.draw_text(120, 96, 120, 24, @item.recover_hp.to_s, 2)
    c.draw_text(0, 120, 116, 24, @item.recover_sp_rate.to_s, 2)
    c.draw_text(120, 120, 120, 24, @item.recover_sp.to_s, 2)
    c.draw_text(0, 168, 116, 24, @item.pdef_f.to_s, 2)
    c.draw_text(120, 168, 120, 24, @item.mdef_f.to_s, 2)
    return unless @item.parameter_type > 0
    c.font.color = system_color
    terms = $data_system.words
    params = KyoShopLabels::ITEMPARAMETERS
    param = params + [terms.str, terms.dex, terms.agi, terms.int]
    c.draw_text(0, 192, 120, 24, params[0])
    c.draw_text(128, 192, 120, 24, param[@item.parameter_type])
    c.font.color = normal_color
    c.draw_text(120, 192, 120, 24, @item.parameter_points.to_s, 2)
  end

  def show_equippable
    c = self.contents
    actors = $game_party.actors
    actors.size.times do |i|
      actor = actors[i]
      equippable = actor.equippable?(@item)
      c.font.color = equippable ? normal_color : disabled_color
      c.draw_text(4, 64 + 64 * i, 120, 32, actor.name)
      if @item.is_a?(RPG::Weapon)
        item1 = $data_weapons[actor.weapon_id]
      elsif @item.kind == 0
        item1 = $data_armors[actor.armor1_id]
      elsif @item.kind == 1
        item1 = $data_armors[actor.armor2_id]
      elsif @item.kind == 2
        item1 = $data_armors[actor.armor3_id]
      else
        item1 = $data_armors[actor.armor4_id]
      end
      next unless equippable
      if @item.is_a?(RPG::Weapon)
        atk1 = item1 ? item1.atk : 0
        atk2 = @item ? @item.atk : 0
        change = atk2 - atk1
      end
      if @item.is_a?(RPG::Armor)
        pdef1 = item1 ? item1.pdef : 0
        mdef1 = item1 ? item1.mdef : 0
        pdef2 = @item ? @item.pdef : 0
        mdef2 = @item ? @item.mdef : 0
        change = pdef2 - pdef1 + mdef2 - mdef1
      end
      c.draw_text(124, 64 + 64 * i, 112, 32, sprintf("%+d", change), 2)
      next unless item1
      x = 4
      y = 64 + 64 * i + 32
      bitmap = RPG::Cache.icon(item1.icon_name)
      opacity = c.font.color == normal_color ? 255 : 128
      c.blt(x, y + 4, bitmap, Rect.new(0, 0, 24, 24), opacity)
      c.draw_text(x + 28, y, 212, 32, item1.name)
    end
  end

  def show_equip_data(term, stat)
    terms = $data_system.words
    c = self.contents
    c.font.color = system_color
    c.draw_text(0, 52, 120, 24, KyoShopLabels::NEWEQUIPMENT, 1)
    c.draw_text(120, 52, 120, 24, KyoShopLabels::OLDEQUIPMENT, 1)
    c.draw_text(0, 76, 120, 24, term)
    c.draw_text(0, 100, 120, 24, terms.pdef)
    c.draw_text(0, 124, 120, 24, terms.mdef)
    c.draw_text(0, 148, 120, 24, terms.str)
    c.draw_text(0, 172, 120, 24, terms.int)
    c.draw_text(0, 196, 120, 24, terms.agi)
    c.draw_text(0, 220, 120, 24, terms.dex)
    c.font.color = normal_color
    c.draw_text(0, 76, 120, 24, stat, 2)
    c.draw_text(0, 100, 120, 24, @item.pdef.to_s, 2)
    c.draw_text(0, 124, 120, 24, @item.mdef.to_s, 2)
    c.draw_text(0, 148, 120, 24, @item.str_plus.to_s, 2)
    c.draw_text(0, 172, 120, 24, @item.int_plus.to_s, 2)
    c.draw_text(0, 196, 120, 24, @item.agi_plus.to_s, 2)
    c.draw_text(0, 220, 120, 24, @item.dex_plus.to_s, 2)
  end

  def show_no_info
    self.contents.draw_text(0, 48, 240, 24, KyoShopLabels::NOINFOAVAILABLE, 1)
  end

  def show_elements
    c = self.contents
    c.font.color = system_color
    c.font.size = 17
    if @item.type == :armor
      resistances = (@has_elements and KElemRES.armor_resistances[@item.id])
      resistances ? show_armor_elements : show_item_elements
    else
      show_item_elements
    end
    c.font.size = 22
  end

  def show_item_elements
    set = @item.element_set
    return show_no_info if set.size == 0
    c = self.contents
    sy = -1
    set.each do |eid|
      sy += 1
      c.draw_text(0, 24 + 17 * sy, 120, 17, @elements[eid])
    end
  end

  def show_armor_elements
    set = KElemRES.armor_resistances[@item.id]
    return show_no_info if set.size == 0
    c = self.contents
    sy = -1
    set.each do |element|
      sy += 1
      c.draw_text(0, 24 + 17 * sy, 120, 17, @elements[eid])
      c.draw_text(0, 24 + 17 * sy, 200, 17, element.to_s, 2)
    end
  end
end

class Interpreter
  def command_126
    value = operate_value(@parameters[1], @parameters[2], @parameters[3])
    item = $data_items[@parameters[0]]
    $game_party.gain_item(item.id, value)
    $game_party.reset_discount_item(item, value)
    return true
  end

  alias kyon_discounts_inter_comm_302 command_302
  def command_302
    if $game_switches[KyoShop::GOODSSWITCHID]
      KyoShopOrders.store_event_id = @event_id
      $game_switches[KyoShop::GOODSSWITCHID] = false
      $game_system.shop_goods = [@parameters]
      loop do
        @index += 1
        return false if @list[@index].code != 605
        $game_system.shop_goods << @list[@index].parameters
      end
    end
    kyon_discounts_inter_comm_302
  end
end

class Scene_Shop
  alias kyon_discounts_scn_shop_up update
  def main
    start
    Graphics.transition
    while @keep_loop
      Graphics.update
      Input.update
      update
    end
    Graphics.freeze
    terminate
  end

  def start
    @keep_loop = true
    @stage = :main
    if KyoShop.id and KyoShop.id > 0
      @shop_id = KyoShop.id
    else
      KyoShop.id = @shop_id = $game_variables[KyoShop::STORECODEVARID]
    end
    KyoShop.set_random_percent
    @goods = $game_temp.shop_goods.dup
    @orders = $game_system.shop_goods.dup
    update_goods_orders_after_investment
    @shop_name = $game_system.map_interpreter.get_character(0).name
    @help_window = Window_Help.new
    @help_window.set_text(@shop_name, 1)
    @discount_window = Window_ShopDiscountCoupon.new
    @discount_window.disappear
    @discount_window.help_window = @help_window
    if (@orders_enabled = !$game_system.shop_goods.empty?)
      KyoShop.options << :place << :pickup
      @order_window = Window_ShopBuy.new($game_system.shop_goods)
      @order_window.disappear
      @order_window.help_window = @help_window
    end
    @need_appraisal = KyoShop.appraisals.keys.include?(@shop_id)
    make_appraisal_windows if @need_appraisal
    @purchase_window = Window_ShopBuy.new($game_temp.shop_goods)
    @purchase_window.disappear
    @purchase_window.help_window = @help_window
    @pack_id = [$game_map.map_id, KyoShopOrders.store_event_id]
    goods = $game_system.placed_orders[@pack_id]
    goods ||= []
    @pickup_window = Window_ShopPickUp.new(goods)
    @pickup_window.disappear
    @pickup_window.help_window = @help_window
    @sell_window = Window_ShopSell.new
    @sell_window.disappear
    @sell_window.help_window = @help_window
    @number_window = Window_ShopNumber.new
    @number_window.disappear
    make_basic_windows
    @option_window = Window_ShopBuyOptions.new
    @option_window.z += 200
    @option_window.disappear
  end

  def update_goods_orders_after_investment
    goods = []
    orders = []
    stuff = $game_system.check_shares(@shop_id)
    return if stuff.empty?
    stuff.each do |b|
      case b.shift
      when :goods then goods += b.map {|str| retrieve_item(str) }
      when :orders then orders += b.map {|str| retrieve_item(str) }
      end
    end
    $game_system.shop_goods = (@orders + orders).sort.uniq
    $game_temp.shop_goods = (@goods + goods).sort.uniq
  end

  def retrieve_item(string)
    case string[0,1]
    when 'i' then [0, string[1..-1].to_i]
    when 'w' then [1, string[1..-1].to_i]
    when 'a' then [2, string[1..-1].to_i]
    end
  end

  def make_appraisal_windows
    KyoShop.options << :appraise
    @appraisal = KyoShop.appraisals[@shop_id]
    @appraise_item_window = AppraiseItemWindow.new
    @appraise_item_window.visible = false
    @appraise_info_window = AppraiseInfoWindow.new(@shop_id)
    @appraise_info_window.visible = false
    options = KyoShopLabels::APPRAISALOPTIONS.dup
    @appraise_options = Window_Command.new(160, options)
    @appraise_options.disappear
    @appraise_options.x = 240
    @appraise_options.y = 200
    @result_info_window = AppraiseResultWindow.new
    @result_info_window.visible = false
    options = KyoShopLabels::APPRAISALHAGGLEOPTIONS.dup
    @favor_options = Window_Command.new(160, options)
    @favor_options.disappear
    @favor_options.x = 240
    @favor_options.y = 200
  end

  def make_basic_windows
    @command_window = Window_ShopCommand.new
    @gold_window = Window_Gold.new
    @gold_window.x = 480
    @gold_window.y = 64
    @status_window = Window_ShopStatus.new
    @status_window.visible = false
    @status_window.z += 25
    wh = Graphics.height - 128
    @dummy_window = Window_Base.new(0, 128, Graphics.width, wh)
    @question_window = Window_ShopDiscountAlert.new
    @question_window.visible = false
    @data_window = ShopDataWindow.new(368, 128)
    @data_window.z += 125
    @data_window.visible = false
  end

  def terminate
    @help_window.dispose
    @command_window.dispose
    @gold_window.dispose
    @dummy_window.dispose
    @purchase_window.dispose
    @pickup_window.dispose
    @sell_window.dispose
    @number_window.dispose
    @status_window.dispose
    @question_window.dispose
    @discount_window.dispose
    @option_window.dispose
    @data_window.dispose
    $game_variables[KyoShop::STORECODEVARID] = 0
    if @need_appraisal
      @appraise_item_window.dispose
      @appraise_info_window.dispose
      @appraise_options.dispose
      @result_info_window.dispose
      @favor_options.dispose
    end
    if @orders_enabled
      @order_window.dispose
      $game_system.shop_goods.clear
      KyoShopOrders.commissions.clear
      KyoShopOrders.steps.clear
      KyoShopOrders.store_event_id = nil
    end
    KyoShop.options.clear
    KyoShop.random_percent = 0
    KyoShop.id = 0
    @stage = nil
  end

  def update_discount_message
    cd = $game_party.check_discounts
    text = cd ? KyoShopLabels::SOMEDISCOUNTS : KyoShopLabels::NODISCOUNTS
    @question_window.set_text(text)
  end

  def update
    @help_window.update
    @gold_window.update
    @dummy_window.update
    @status_window.update
    case @stage
    when :main then update_command
    when :option then update_option
    when :purchase then update_purchase
    when :place then update_place_order
    when :pickup then update_pickup_order
    when :discount then update_discount
    when :appraise then update_appraisal
    when :appraise_option then update_appraisal_option
    when :appraise_favor then update_appraisal_favor
    when :sell then update_sell
    when :number then update_number
    end
  end

  def update_command
    @command_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $scene = Scene_Map.new
      return @keep_loop = nil
    elsif Input.trigger?(Input::C)
      case @command_window.index
      when 0 # buy
        $game_system.se_play($data_system.decision_se)
        @command_window.active = false
        if $game_system.shop_goods.empty?
          @discount = 0
          @dummy_window.visible = false
          @question_window.visible = true
          @purchase_window.appear
          @purchase_window.refresh
          @data_window.item = @purchase_window.item
          @data_window.visible = true
          update_discount_message
          return @stage = :purchase
        else
          @option_window.appear
          return @stage = :option
        end
      when 1 # sell
        $game_system.se_play($data_system.decision_se)
        @command_window.active = false
        @dummy_window.visible = false
        @sell_window.appear
        @sell_window.refresh
        return @stage = :sell
      when 2 # quit
        $game_system.se_play($data_system.decision_se)
        $scene = Scene_Map.new
        @keep_loop = nil
      end
    end
  end

  def update_option
    @option_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @option_window.disappear
      @status_window.visible = false
      @command_window.active = true
      @dummy_window.visible = true
      @help_window.set_text(@shop_name, 1)
      return @stage = :main
    elsif Input.trigger?(Input::C)
      pos = @option_window.index
      if pos == 3 and !@need_appraisal
        return $game_system.se_play($data_system.buzzer_se)
      end
      shares = $game_system.shop_shares[@shop_id]
      inv_max, inv_price = KyoShop::SHARESMAXNPRICE[@shop_id]
      if pos == 4 and inv_max == shares
        return $game_system.se_play($data_system.buzzer_se)
      end
      $game_system.se_play($data_system.decision_se)
      @dummy_window.visible = false
      @option_window.disappear
      @question_window.visible = true
      @data_window.visible = true
      case @option_window.option
      when :purchase
        @discount = 0
        @purchase_window.discount = 0
        disc = $game_system.check_shares(@shop_id)
        disc.each {|b| @purchase_window.discount += b[1] if b[0] == :discount }
        @data_window.item = @purchase_window.item
        @purchase_window.refresh
        @purchase_window.appear
        update_discount_message
        return @stage = :purchase
      when :place
        @status_window.item = @order_window.item
        @order_window.appear
        @order_window.refresh
        @question_window.set_text(KyoShopLabels::PLACEORDER)
        return @stage = :place
      when :pickup
        @status_window.item = @pickup_window.item
        @pickup_window.appear
        @pickup_window.refresh
        @question_window.set_text(KyoShopLabels::PICKUPORDER)
        return @stage = :pickup
      when :appraise
        @appraise_item_window.appear
        @appraise_info_window.visible = true
        @result_info_window.visible = true
        @dummy_window.visible = false
        @command_window.visible = false
        @number_window.visible = false
        @status_window.visible = false
        @question_window.visible = false
        @help_window.set_text(KyoShopLabels::APPRAISALMENULABEL)
        return @stage = :appraise
      when :invest
        @status_window.investment = @investment = true
        inv_max = [inv_max - shares, $game_party.gold / inv_price].min
        fake_item = RPG::Item.new
        fake_item.name = KyoShopLabels::SHARES
        @price = inv_price
        @number_window.mode = :invest
        @number_window.set(fake_item, inv_max, inv_price, nil, 10)
        @number_window.appear
        @question_window.set_text(KyoShopLabels::INVESTMENT)
        @stage = :number
      end
    end
  end

  def update_purchase
    @purchase_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @discount = 0
      @purchase_window.discount = 0
      @dummy_window.visible = true
      @purchase_window.disappear
      @question_window.visible = false
      @data_window.visible = false
      @help_window.set_text(@shop_name, 1)
      if $game_system.shop_goods.empty?
        @command_window.active = true
        return @stage = :main
      else
        @option_window.appear
        return @stage = :option
      end
    end
    if Input.trigger?(Input::UP) or Input.trigger?(Input::DOWN)
      return @data_window.item = @purchase_window.item
    elsif Input.trigger?(Input::LEFT) or Input.trigger?(Input::RIGHT)
      return @data_window.refresh_page
    end
    if Input.trigger?(KyoShop::DISCOUNTBUTTON)
      unless $game_party.check_discounts
        return $game_system.se_play($data_system.buzzer_se)
      end
      $game_system.se_play($data_system.decision_se)
      @purchase_window.disappear
      @discount_window.refresh
      @discount_window.appear
      @question_window.set_text(KyoShopLabels::SELECTDISCOUNT)
      return @stage = :discount
    elsif Input.trigger?(Input::C)
      discount = @purchase_window.discount
      percent = KyoShop.current_price_max
      @item = @purchase_window.item
      pr = @item.price
      pr += pr * KyoShop.random_percent / 100 if KyoShop.random_prices?
      @price = pr + pr * percent / 100
      @price -= pr * discount / 100 if discount > 0
      gs = $game_system
      buzzer = $data_system.buzzer_se
      return gs.se_play(buzzer) if @item == nil or @price > $game_party.gold
      return gs.se_play(buzzer) if gs.shop_block_item?(@shop_id, @item)
      number = check_number
      shop_max = KyoShop.current_item_max
      return gs.se_play(buzzer) if number >= shop_max
      gs.se_play($data_system.decision_se)
      unique_max = gs.unique_item_max(@shop_id, @item)
      shop_max = unique_max if unique_max < shop_max
      max = @price == 0 ? shop_max : $game_party.gold / @price
      n = shop_max == unique_max ? shop_max : shop_max - number
      max = [max, n].min
      @purchase_window.disappear
      @number_window.mode = :purchase
      @number_window.set(@item, max, @price)
      @number_window.appear
      @last_stage = @stage
      @stage = :number
    end
  end

  def update_place_order
    @order_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @option_window.appear
      @dummy_window.visible = true
      @order_window.disappear
      @question_window.visible = false
      @status_window.visible = false
      @status_window.item = nil
      @help_window.set_text("")
      return @stage = :option
    end
    if Input.trigger?(Input::UP) or Input.trigger?(Input::DOWN)
      @status_window.item = @order_window.item
      return
    end
    if Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @item = @order_window.item
      @price = @item.price
      @price += @price * KyoShop.random_percent / 100 if KyoShop.random_prices?
      percent = KyoShopOrders.commissions[@order_window.index]
      percent += KyoShop.current_price_max
      @price += percent * @price / 100 if percent > 0
      if @item == nil or @price > $game_party.gold
        return $game_system.se_play($data_system.buzzer_se)
      end
      number = check_number
      shop_max = KyoShop.get_order_max
      if number == shop_max
        return $game_system.se_play($data_system.buzzer_se)
      end
      $game_system.se_play($data_system.decision_se)
      max = @price == 0 ? shop_max : $game_party.gold / @price
      max = [max, shop_max - number].min
      @order_window.disappear
      @place_order = true
      @number_window.set(@item, max, @price, percent)
      @number_window.appear
      @question_window.set_text(KyoShopLabels::FEESAPPLY)
      @last_stage = @stage
      @stage = :number
    end
  end

  def update_pickup_order
    @pickup_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @dummy_window.visible = true
      @question_window.visible = false
      @status_window.visible = false
      @pickup_window.disappear
      @option_window.appear
      return @stage = :option
    end
    if Input.trigger?(Input::UP) or Input.trigger?(Input::DOWN)
      @status_window.item = @pickup_window.item
      return
    end
    if Input.trigger?(Input::C)
      current_item = @pickup_window.item
      unless $game_system.placed_orders[@pack_id]
        return $game_system.se_play($data_system.buzzer_se)
      end
      goods = goods[@pickup_window.index]
      unless current_item and goods[3] <= $game_party.steps
        return $game_system.se_play($data_system.buzzer_se)
      end
      $game_system.se_play($data_system.decision_se)
      number = goods[2]
      case current_item
      when RPG::Item then $game_party.gain_item(current_item.id, number)
      when RPG::Weapon then $game_party.gain_weapon(current_item.id, number)
      when RPG::Armor then $game_party.gain_armor(current_item.id, number)
      end
      $game_system.placed_orders[@pack_id].delete_at(@pickup_window.index)
      @pickup_window.deliver($game_system.placed_orders[@pack_id])
    end
  end

  def update_discount
    @discount_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @discount_window.disappear
      @purchase_window.appear
      return @stage = :purchase
    elsif Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @coupons_allowed = KyoShop::COUPON_IDS.include?(@discount_window.item.id)
      @purchase_window.discount -= @discount
      @discount = @discount_window.item.price
      @discount_window.disappear
      @purchase_window.appear
      discount = @purchase_window.discount += @discount
      @purchase_window.refresh
      text = sprintf(KyoShopLabels::APPLYDISCOUNT, discount)
      @question_window.set_text(text)
      @stage = :purchase
    end
  end

  def update_appraisal
    @appraise_item_window.update
    if Input.trigger?(Input::UP) or Input.trigger?(Input::DOWN)
      @appraise_info_window.refresh
      return
    end
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @appraise_item_window.disappear
      @appraise_info_window.visible = false
      @result_info_window.visible = false
      @result_info_window.contents.clear
      @appraise_options.disappear
      @dummy_window.visible = true
      @command_window.visible = true
      @option_window.appear
      @help_window.set_text("")
      return @stage = :option
    elsif Input.trigger?(Input::C)
      if @appraise_item_window.empty?
        return $game_system.se_play($data_system.buzzer_se)
      end
      pts = $game_system.shop_favors[@shop_id]
      items = @appraisal[:items].dup
      items.merge!(@appraisal[:extra_items]) if @appraisal[:steps] >= pts
      item = @appraise_item_window.item
      item_included = case item.type
      when :item then items[0].include?(item.id)
      when :weapon then items[1].include?(item.id)
      when :armor then items[2].include?(item.id)
      end
      unless item_included
        $game_system.se_play($data_system.buzzer_se)
        @result_info_window.cannot_appraise(item)
        return
      end
      $game_system.se_play($data_system.decision_se)
      @appraise_item_window.active = false
      @appraise_options.appear
      @stage = :appraise_option
    end
  end

  def update_appraisal_option
    @appraise_options.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      return exit_appraisal_option
    elsif Input.trigger?(Input::C)
      if @appraise_options.index == 1
        $game_system.se_play($data_system.cancel_se)
        return exit_appraisal_option
      end
      if $game_party.gold < @appraisal[:cost]
        $game_system.se_play($data_system.buzzer_se)
        return exit_appraisal_option
      end
      $game_system.se_play($data_system.decision_se)
      item = @appraise_item_window.item
      case item.type
      when :item then $game_party.lose_item(item.id, 1)
      when :weapon then $game_party.lose_weapon(item.id, 1)
      when :armor then $game_party.lose_armor(item.id, 1)
      end
      $game_party.lose_gold(price)
      @appraise_item_window.refresh
      goods = @appraisal[:goods]
      key = goods[rand(goods.size)]
      kind, id = retrieve_item(key)
      new_item = case kind
      when 0 then $data_items[id]
      when 1 then $data_weapons[id]
      when 2 then $data_armors[id]
      end
      found = data[:target].has_key?(key)
      found ? make_offer(key, new_item) : no_offer(kind, id, new_item)
    end
  end

  def exit_appraisal_option
    @appraise_options.disappear
    @appraise_item_window.active = true
    @stage = :appraise
  end

  def make_offer(key, item)
    @appraise_options.disappear
    @favor_options.appear
    @result_info_window.ask_favor(item)
    @target_item = item
    @target_key = key
    @target_points = @appraisal[:target][key]
    @haggle_enabled = @appraisal[:haggle]
    @haggle_max = @appraisal[:overprice]
    @stage = :appraise_favor
  end

  def no_offer(kind, id, item)
    case kind
    when 0 then $game_party.gain_item(id, 1)
    when 1 then $game_party.gain_weapon(id, 1)
    when 2 then $game_party.gain_armor(id, 1)
    end
    @result_info_window.refresh(item)
    @appraise_item_window.refresh
    @gold_window.refresh
    exit_appraisal_option
  end

  def update_appraisal_favor
    @favor_options.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @favor_options.disappear
      return @stage = :appraise
    elsif Input.trigger?(Input::C)
      case @favor_options.index
      when 0
        if @overprice
          $game_system.se_play($data_system.shop_se)
          $game_system.shop_favors[@shop_id] += @target_points
          pr = @overprice
          @target_points = nil
        else
          $game_system.se_play($data_system.decision_se)
          pr = @target_item.price
          pr += pr * KyoShop.random_percent / 100 if KyoShop.random_prices?
        end
        $game_party.gain_gold(pr)
        @overprice = @target_item = nil
      when 1
        unless @haggle_enabled
          return $game_system.se_play($data_system.buzzer_se)
        end
        $game_system.se_play($data_system.decision_se)
        @haggle_enabled = nil
        @overprice = rand(@haggle_max) + 1
        @overprice = 25 if @overprice < 25
        pr = @target_item.price
        pr += pr * KyoShop.random_percent / 100 if KyoShop.random_prices?
        @overprice += pr
        @result_info_window.make_offer(@overprice)
        return
      when 2
        $game_system.se_play($data_system.decision_se)
        case @target_item.class
        when RPG::Item then $game_party.gain_item(@target_item.id, 1)
        when RPG::Weapon then $game_party.gain_weapon(@target_item.id, 1)
        when RPG::Armor then $game_party.gain_armor(@target_item.id, 1)
        end
        @target_item = nil
        @favor_options.disappear
      end
      return @stage = :appraise
    end
  end

  def check_number
    return number = case @item.type
    when :item then $game_party.item_number(@item.id)
    when :weapon then $game_party.weapon_number(@item.id)
    when :armor then $game_party.armor_number(@item.id)
    end
  end

  def update_sell
    @sell_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @dummy_window.visible = true
      @sell_window.disappear
      @status_window.item = nil
      @help_window.set_text("")
      @command_window.active = true
      return @stage = :main
    elsif Input.trigger?(Input::C)
      @item = @sell_window.item
      @status_window.item = @item
      if @item == nil or @item.price == 0
        return $game_system.se_play($data_system.buzzer_se)
      end
      iid = @item.id
      if KyoShop.no_card_sale?(iid) or KyoShop.no_coupon_sale?(iid)
        return $game_system.se_play($data_system.buzzer_se)
      end
      $game_system.se_play($data_system.decision_se)
      number = case @item.type
      when :item then $game_party.item_number(iid)
      when :weapon then $game_party.weapon_number(iid)
      when :armor then $game_party.armor_number(iid)
      end
      @sell_window.disappear
      @number_window.mode = :sale
      @modifier = KyoShop::SALE_PRICE_MODIFIER[@shop_id]
      cost = @item.price
      cost += cost * KyoShop.random_percent / 100 if KyoShop.random_prices?
      @price = cost * @modifier / 100
      @number_window.set(@item, number, @price, @modifier)
      @number_window.appear
      @status_window.visible = true
      @last_stage = :sell
      @stage = :number
    end
  end

  def update_number
    @number_window.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      case @command_window.index
      when 0 # buy or place order
        if @place_order
          @place_order = nil
          @order_window.appear
          @question_window.set_text(KyoShopLabels::PLACEORDER)
        elsif @investment
          return exit_investment
        else
          @purchase_window.appear
          discount = @purchase_window.discount
          if discount == 0
            update_discount_message
          else
            text = sprintf(KyoShopLabels::APPLYDISCOUNT, discount) + "%"
            @question_window.set_text(text)
          end
        end
      when 1 # sell
        update_discount_message
        @sell_window.appear
        @status_window.visible = false
      end
      @number_window.disappear
      @number_window.reset_multiplier
      @number_window.mode = nil
      @stage = @last_stage
      return @last_stage = nil
    elsif Input.trigger?(Input::C)
      $game_system.se_play($data_system.shop_se)
      @number_window.disappear
      case @command_window.index
      when 0 # buy
        $game_party.lose_gold(@number_window.number * @price)
        number = @number_window.number
        if @place_order
          update_number_place_order(number)
        elsif @investment
          update_number_investment(number)
        else
          $game_system.buy_unique_item(@shop_id, @item, number)
          update_number_purchase(number)
        end
        return
      when 1 # sell
        number = @number_window.number
        $game_party.gain_gold(number * (@price * @modifier).round)
        case @item.type
        when :item then   $game_party.lose_item(@item.id, number)
        when :weapon then $game_party.lose_weapon(@item.id, number)
        when :armor then  $game_party.lose_armor(@item.id, number)
        end
        @gold_window.refresh
        @sell_window.refresh
        @status_window.refresh
        @sell_window.appear
        @status_window.visible = false
        @modifier = nil
        @price = 0
        @stage = @last_stage
        return @last_stage = nil
      end
    end
  end

  def update_number_place_order(number)
    steps = $game_party.steps + KyoShopOrders.steps[@order_window.index]
    order = [nil, @item.id, number, steps]
    order[0] = case @item
    when RPG::Item then 0
    when RPG::Weapon then 1
    when RPG::Armor then 2
    end
    $game_system.placed_orders[@pack_id] ||= []
    $game_system.placed_orders[@pack_id] << order
    @pickup_window.deliver($game_system.placed_orders[@pack_id])
    @gold_window.refresh
    @status_window.refresh
    @place_order = nil
    @order_window.refresh
    @order_window.appear
    @question_window.set_text(KyoShopLabels::PLACEORDER)
    @stage = :place
  end

  def update_number_investment(number)
    $game_system.shop_shares[@shop_id] += number
    update_goods_orders_after_investment
    @order_window.deliver($game_system.shop_goods)
    @purchase_window.deliver($game_temp.shop_goods)
    @gold_window.refresh
    exit_investment
  end

  def exit_investment
    @investment = nil
    @status_window.investment = nil
    @question_window.visible = false
    @status_window.visible = false
    @number_window.visible = false
    @number_window.mode = nil
    @number_window.reset_multiplier
    @dummy_window.visible = true
    @option_window.appear
    @stage = :option
  end

  def update_number_purchase(number)
    case @item.type
    when :item then $game_party.gain_item(@item.id, number)
    when :weapon then $game_party.gain_weapon(@item.id, number)
    when :armor then $game_party.gain_armor(@item.id, number)
    end
    if @coupons_allowed
      @coupons_allowed = nil
      $game_party.lose_item(@discount_window.item.id, 1)
      update_discount_message
      @discount_window.refresh
      @purchase_window.discount = 0
      @discount = 0
    end
    @gold_window.refresh
    @status_window.refresh
    @purchase_window.refresh
    @purchase_window.appear
    @stage = :purchase
  end
end