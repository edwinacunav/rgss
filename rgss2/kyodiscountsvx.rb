# * KyoDiscounts VX
#   Scripter : Kyonides-Arkanthos
#   v1.5.0 - 2019-01-17

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
#      Makes all Discount Cards expire as part of the game's plot.

#   $game_party.disc_card_expire(Card_ID)
#      Makes an specific Discount Card expire as part of the game's plot.

#   KyoShopOrders << [Percent1, Percent2, etc.]
#      Defines a Commission percent for every Item in the Place Order List.

#   KyoShopOrders.steps = [Steps1, Steps2, etc.]
#   KyoShopOrders.steps += [Steps5, Steps6, etc.]
#      Defines Steps required by every Order in the Place Order List.
#      The 2nd call will be required only if you couldn't include all steps.

#   KyoShop.scarcity_lvl = 0 or higher
#     Define all prices and maximum number of units per shop item.
#     0 means no scarcity, 1 or higher reflects how severe it is.
#     You also have to configure the @scarce_limits hash in order to predefine
#     :price and :max per scarcity level. The maximum scarcity level depends on
#     how many values you entered in both :price and :max arrays.
#     In few words, you define the maximum scarcity level ever possible!

module KyoShop
  # Maximum number of units for each shop item
  NUMBERMAX = 99
  # Button that will open the Discount window while on the shop menu
  DISCOUNTBUTTON = Input::A
  # Add Discount Card Object IDs
  DISCOUNT_IDS = [21, 22, 23]
  # Add Discount Coupon Object IDs
  COUPON_IDS = [24, 25, 26]
  # Maximum Steps before Discount Card expires : ID => Steps
  STEPS = { 21 => 500, 22 => 300, 23 => 150 }
  # Exclusive Stores In Game Variable ID
  STORECODEVARID = 1
  # Exclusive Stores List : Object ID => Exclusive Store Code
  EXCLUSIVESTORES = { 35 => 102 }
  # Switch ID : deactivates Store to add Goods found elsewhere
  GOODSSWITCHID = 1
  # Store IDs for stores where you have invested some gold
  INVESTSTOREIDS = [101]
  # Maximum Number of Shares & Share Price
  SHARESMAXMIN = [10000, 100]
  INVESTMENTS = {} # Store Investments - Do Not Edit This Line
  INVESTMENTS.default = {} # Do Not Edit This Line
  # Available Improvements #
  # :discount : [:discount, 25]
  # :goods    : [:goods, 'i10', 'w4', 'a6']
  # :orders   : [:orders, 'i11', 'w5', 'a7']
  # [Store ID] = { Shares => Prize, Shares => Another Prize, etc. }
  INVESTMENTS[101] = { 50 => [:goods,'i10','w5','a6'], 100 => [:discount,10] }
  APPRAISALS = {} # Do Not Edit This Line!
  # [Store ID] = { appraisal cost => $, estimate cost => $, success rate => %,
  # times you can help the a. => 0, bad result => "i1", goods => [item4, etc.] }
  APPRAISALS[101] = { :cost => 150, :test_cost => 75, :rate => 10,
      :default => 'i1', :help_limit => 5, :haggle => true,
      :target => { 'i9' => 1, 'i10' => 2 },
      :goods => ['i2','i3','i9','i10'], :extras => ['i11'] }
  # Add Item IDs for unknown shop goods that need to be appraised by experts
  MYSTERIOUSITEMS = []
  # Add Weapon IDs for unknown shop goods that need to be appraised by experts
  MYSTERIOUSWEAPONS = []
  # Add Armor IDs for unknown shop goods that need to be appraised by experts
  MYSTERIOUSARMORS = []
  @scarce_limits = {
    :price  => [0, 25, 50, 100, 250, 350, 500, 650, 800],
    :max => [NUMBERMAX, NUMBERMAX - 10, NUMBERMAX - 25, NUMBERMAX - 35,
        NUMBERMAX - 50, NUMBERMAX - 65, NUMBERMAX - 80, NUMBERMAX - 90, 1]
    #:item => [1, 2, 3, 4, 5, 6],
    #:weapon => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    #:armor => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  }
  @scarce_lvl = 0 # Initial Level
  def self.current_item_max() @scarce_limits[:max][@scarce_lvl] end
  def self.current_price_max() @scarce_limits[:price][@scarce_lvl] end
  def self.scarcity_limits() @scarce_limits end
  def self.scarcity_lvl() @scarce_lvl end
  def self.scarcity_lvl=(lvl) @scarce_lvl = lvl end
end


module KyoShopLabels
  # Buy Stuff & Place Order & Pick Up Items Label
  BUYPLACEPICKUP = ['Buy Items', 'Place Order', 'Pick Up Items', 'Invest']
  # Item Price Data Labels
  PRICEDATA = ['Basic Price', 'Commission', 'Discount', 'Total Price']
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
  APPLYDISCOUNT = 'Discount Applied'
  # Commission Fees Apply Label
  FEESAPPLY = 'Special Fees Apply'
  # Discount Card's Steps Left Label
  STEPSLEFT = " %s steps left."
  # Investment Label...
  INVESTMENT = 'Want to invest in this store?'
  # Share Number Label
  SHARES = 'Share Number'
  # Adquired or Purchased Shares Label
  TOTALSHARES = 'Total Shares'
  # Need a Discount Label
  NEEDADISCOUNT = 'Need a Discount?'
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
    "Would you accept some %s?"
  ]
end
# DO NOT EDIT ANYTHING ELSE #
module KyoShopOrders
  @goods = []
  @commissions = []
  @steps = []
  class << self
    attr_accessor :store_id, :goods_id, :goods
    attr_reader :steps, :commissions
    def steps=(val) @steps = val.map {|n| n + rand((n / 2) + 2) } end
    def <<(val)
      @commissions += val
      @commissions = @commissions.flatten
    end
  end
end

class Game_System
  attr_reader :placed_orders, :shop_shares, :shop_favors
  alias kyon_discounts_gm_sys_init initialize
  def initialize
    @placed_orders = {}
    @shop_shares = {}
    @shop_favors = {}
    @placed_orders.default = []
    @shop_shares.default = 0
    @shop_favors.default = 0
    kyon_discounts_gm_sys_init
  end

  def disc_store?(disc_id) !KyoShop::EXCLUSIVESTORES[disc_id] end

  def excl_disc_store?(disc_id)
    exclusive = KyoShop::EXCLUSIVESTORES[disc_id]
    exclusive == $game_variables[KyoShop::STORECODEVARID]
  end

  def check_shares(shop_id)
    results = []
    shares = @shop_shares[shop_id]
    investments = KyoShop::INVESTMENTS[shop_id]
    limits = KyoShop::INVESTMENTS[shop_id].keys.sort
    results = investments.select{|limit| shares >= limit[0] }.map {|r| r[1] }
  end
end

class Game_Party
  attr_reader :discounts
  alias kyon_discounts_gm_party_init initialize
  alias kyon_discounts_gm_party_gain_item gain_item
  def initialize
    @discounts = {}
    kyon_discounts_gm_party_init
  end

  def gain_item(item, n, equip=false)
    kyon_discounts_gm_party_gain_item(item, n, equip)
    return if item == nil or n == 0
    return unless KyoShop::DISCOUNT_IDS.include?(item.id)
    item_id = item.id
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
        return true if $game_system.disc_store?(did)
        return true if $game_system.excl_disc_store?(did)
      end
    end
    for cid in KyoShop::COUPON_IDS
      next unless @items[cid] and @items[cid] > 0
      return true if $game_system.disc_store?(cid)
      return true if $game_system.excl_disc_store?(cid)
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
  def item_include?(item_id) @items[item_id] and @items[item_id] > 0 end
end

class Game_Player
  alias kyon_discounts_coupons_gm_player_increase_steps increase_steps
  def increase_steps
    kyon_discounts_coupons_gm_player_increase_steps
    $game_party.decrease_discounts
  end
end

class Game_Interpreter
  alias kyon_discounts_game_inter_comm_302 command_302
  def command_302
    if $game_switches[KyoShop::GOODSSWITCHID]
      KyoShopOrders.store_id = @event_id
      $game_switches[KyoShop::GOODSSWITCHID] = false
      KyoShopOrders.goods = [@params[0,2]]
      loop do
        @index += 1
        if @list[@index].code == 605
          KyoShopOrders.goods << @list[@index].parameters
        else
          return false
        end
      end
    end
    kyon_discounts_game_inter_comm_302
  end
end

class Window_Base
  def appear
    self.active = true
    self.visible = true
  end

  def disappear
    self.active = false
    self.visible = false
  end

  def draw_currency_value(value, x, y, width)
    c = self.contents
    cx = c.text_size(Vocab::gold).width
    c.font.color = normal_color
    c.draw_text(x - 8, y, width-cx-2, WLH, value, 2)
    c.font.color = system_color
    c.draw_text(x, y, width, WLH, Vocab::gold, 2)
  end
end

class Window_KyoShopHelp < Window_Help
  def set_text(text, align=0)
    if KyoShop::DISCOUNT_IDS.include?(KyoShopOrders.goods_id)
      steps = $game_party.discounts[KyoShopOrders.goods_id].to_s
      text = sprintf(KyoShopLabels::STEPSLEFT, steps)
      KyoShopOrders.goods_id = nil
    end
    super(text, align)
  end
end

class Window_Item
  alias kyon_discounts_win_item_up_help update_help
  def update_help
    KyoShopOrders.goods_id = self.item.id
    kyon_discounts_win_item_up_help
  end
end

class AppraiseItemWindow < Window_Selectable
  def initialize
    super(0, 56, 544-160, 280)
    @column_max = 1
    refresh
    self.index = 0
  end

  def refresh
    self.contents.clear
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
    x = 4 + index % 2 * (288 + 32)
    y = index / 2 * 32
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
    super(384, 112, 160, 224)
    @data = KyoShop::APPRAISALS[store_id]
    @labels = KyoShopLabels::APPRAISALLABELS.dup
    @currency = Vocab.gold
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
    super(0, 334, 544, 84)
    @labels = KyoShopLabels::APPRAISALRESULTLABELS.dup
    @currency = Vocab.gold #draw_currency_value(value, x, y, width)
    self.contents = Bitmap.new(width - 32, height - 32)
  end

  def refresh(item)
    contents.clear
    result = sprintf(@labels[0], item.name)
    cost = sprintf(@labels[1], item.price) + " " + @currency
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
end

class Window_ShopBuyPlace < Window_Selectable
  attr_accessor :discount
  attr_reader :discounts
  def initialize(shop_goods, discounts=[])
    super(0, 112, 304, 248)
    @shop_goods = shop_goods
    @discount = 0
    @discounts = discounts
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

  def item() @data[self.index] end

  def refresh
    @data = []
    for goods_item in @shop_goods
      item = case goods_item[0]
      when 0 then $data_items[goods_item[1]]
      when 1 then $data_weapons[goods_item[1]]
      when 2 then $data_armors[goods_item[1]]
      end
      @data << item if item
    end
    @item_max = @data.size
    create_contents
    @item_max.times {|i| draw_item(i) }
  end

  def draw_item(index)
    item = @data[index]
    number = $game_party.item_number(item)
    enabled = (item.price <= $game_party.gold and number < 99)
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    draw_item_name(item, rect.x, rect.y, enabled)
    rect.width -= 4
    fee = @discounts.empty? ? @discount : @discounts[index]
    fee = item.price * fee / 100
    self.contents.draw_text(rect, item.price + fee, 2)
  end

  def update_help
    @help_window.set_text(item == nil ? "" : item.description)
  end
end

class Window_ShopNumber
  def initialize(x, y)
    super(x, y, 304, 248)
    @item = nil
    @max = 1
    @price = 0
    @number = 1
    @percent = 0
    @multiplier = 1
  end

  def reset_multiplier
    @multiplier = 1
    @number = 1
    refresh
  end

  def set(item, max, price, percent=0, multiplier=1)
    @item = item
    @max = max
    @price = price
    @number = 1
    @multiplier = multiplier
    @percent = percent
    refresh
  end

  def refresh
    self.contents.clear
    draw_item_name(@item, 0, 96)
    self.contents.font.color = normal_color
    if @multiplier == 1
      cx1, cx2, cx3, cw1, cw2 = [212, 240, 244, 28, 28]
    else
      cx1, cx2, cx3, cw1, cw2 = [196, 202, 212, 68, 64]
    end
    self.contents.draw_text(cx1, 96, 20, WLH, "")
    self.contents.draw_text(cx2, 96, cw1, WLH, @number, 2)
    self.cursor_rect.set(cx3, 96, cw2, WLH)
    if @percent == 0 or @multiplier > 1
      draw_currency_value(@price * @number, 4, 96 + WLH * 2, 264)
      return
    end
    draw_currency_value(@item.price * @number, 4, 72 + WLH * 2, 264)
    draw_percent_value(@percent, 4, 96 + WLH * 2, 264)
    end_price = @item.price + @item.price * @percent / 100
    draw_currency_value(end_price * @number, 4, 120 + WLH * 2, 264)
    draw_price_labels(x - 20, 120, 160)
  end

  def draw_percent_value(value, x, y, width)
    cx = contents.text_size(Vocab::gold).width
    self.contents.font.color = normal_color
    self.contents.draw_text(x - 8, y, width-cx-2, WLH, value, 2)
    text = KyoShopLabels::PRICEDATA[@percent < 0 ? 2 : 1]
    self.contents.draw_text(x + 40, y, width, WLH, text)
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, width, WLH, '%', 2)
  end

  def draw_price_labels(x, y, w)
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, w, WLH, KyoShopLabels::PRICEDATA[0], 2)
    self.contents.draw_text(x, y + 48, w, WLH, KyoShopLabels::PRICEDATA[3], 2)
  end
end

class Window_ShopPickUp < Window_ShopBuyPlace
  def draw_item(index)
    item = @data[index]
    qty, steps = @shop_goods[index][2..3]
    number = $game_party.item_number(item)
    enough = (number + qty < 100 and steps <= $game_party.steps)
    self.contents.font.color.alpha = enough ? 255 : 128
    y = index * 24
    draw_icon(item.icon_index, 0, y, enough)
    self.contents.draw_text(32, y - 4, 212, 32, item.name, 0)
    self.contents.draw_text(180, y - 4, 88, 32, qty.to_s, 2)
  end
end

class Window_ShopDiscountAlert < Window_Base
  def initialize
    super(0, 360, 304, 56)
    self.contents = Bitmap.new(width - 32, height - 32)
  end

  def set_text(text)
    self.contents.clear
    self.contents.draw_text(0, 0, 272, 24, text)
  end
end

class Window_ShopDiscountCoupon < Window_Selectable
  def initialize
    super(0, 112, 304, 248)
    self.index = 0
    refresh
  end

  def item() @data[self.index] end

  def refresh
    @data = []
    gs = $game_system
    dc_ids = $game_party.discounts.keys.sort
    dc_ids.each {|i| next if $game_party.discounts[i] == 0
      next unless gs.disc_store?(i) or gs.excl_disc_store?(i)
      @data << $data_items[i] }
    KyoShop::COUPON_IDS.each {|i| next unless $game_party.item_include?(i)
      @data << $data_items[i] }
    @item_max = @data.size
    self.index -= 1 if @index > @item_max - 1
    create_contents
    @item_max.times {|i| draw_item(i) }
  end

  def draw_item(index)
    item = @data[index]
    number = $game_party.item_number(item)
    y = index * 24
    rect = Rect.new(4, y, self.width - 32, 32)
    self.contents.fill_rect(rect, Color.new(0, 0, 0, 0))
    enabled = $game_party.item_can_use?(item)
    draw_item_name(item, rect.x, rect.y, enabled)
    self.contents.draw_text(32, y, 236, 24, ': ' + number.to_s, 2)
  end

  def update_help
    KyoShopOrders.goods_id = self.item.id
    @help_window.set_text(self.item.description)
  end
end

class Window_ShopStatus
  alias kyon_discounts_win_shop_status_refresh refresh
  def investment=(bool)
    @investment = bool
    refresh
  end

  def refresh
    if @investment
      refresh_investment
      return
    end
    kyon_discounts_win_shop_status_refresh
  end

  def refresh_investment
    self.contents.clear
    shares = $game_system.shop_shares[$game_variables[KyoShop::STORECODEVARID]]
    contents.font.color = system_color
    contents.draw_text(0, 0, 200, 32, KyoShopLabels::TOTALSHARES)
    contents.font.color = normal_color
    contents.draw_text(0, 0, 208, 32, shares.to_s, 2)
  end
end

class Scene_Shop
  def start
    @stage = :main
    @shop_id = $game_variables[KyoShop::STORECODEVARID]
    @goods = $game_temp.shop_goods.dup
    @orders = KyoShopOrders.goods.dup
    update_goods_orders_after_investment
    create_menu_background
    create_command_window
    make_basic_data_windows
    make_shop_windows
    make_discount_order_pickup_windows
    make_appraisal_windows
  end

  def make_basic_data_windows
    @help_window = Window_Help.new
    @gold_window = Window_Gold.new(384, 56)
    @dummy_window = Window_Base.new(0, 112, 544, 304)
    @status_window = Window_ShopStatus.new(304, 112)
    @status_window.visible = false
  end

  def make_shop_windows
    @buy_window = Window_ShopBuyPlace.new($game_temp.shop_goods)
    @buy_window.disappear
    @buy_window.help_window = @help_window
    @sell_window = Window_ShopSell.new(0, 112, 544, 304)
    @sell_window.disappear
    @sell_window.help_window = @help_window
    @number_window = Window_ShopNumber.new(0, 112)
    @number_window.disappear
  end

  def make_discount_order_pickup_windows
    @question_window = Window_ShopDiscountAlert.new
    @question_window.visible = false
    @discount_window = Window_ShopDiscountCoupon.new
    @discount_window.disappear
    @discount_window.help_window = @help_window
    commands = KyoShopLabels::BUYPLACEPICKUP.dup
    commands.pop unless KyoShop::INVESTSTOREIDS.include?(@shop_id)
    @extras_window = Window_Command.new(200, commands)
    @extras_window.x = (544 - 200) / 2
    @extras_window.y = 112
    @extras_window.disappear
    unless KyoShopOrders.goods.empty?
      goods = KyoShopOrders.goods
      @order_window = Window_ShopBuyPlace.new(goods, KyoShopOrders.commissions)
      @order_window.disappear
      @order_window.help_window = @help_window
    end
    @pack_id = [$game_map.map_id, KyoShopOrders.store_id]
    goods = $game_system.placed_orders[@pack_id]
    unless goods
      goods = []
      @no_orders = true
      @extras_window.draw_item(2, nil)
    end
    @pickup_window = Window_ShopPickUp.new(goods)
    @pickup_window.disappear
    @pickup_window.help_window = @help_window
  end

  def make_appraisal_windows
    if (@need_appraisal = KyoShop::APPRAISALS.keys.include?(@shop_id))
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
    else
      @extras_window.draw_item(3, nil)
    end
  end

  def update_goods_orders_after_investment
    gds = []
    orders = []
    stuff = $game_system.check_shares(@shop_id)
    return if stuff.empty?
    stuff.each {|b| gds += strings_goods_conversion(b[1..-1]) if b[0] == :goods
      orders += string_good_conversion(b[1..-1]) if b[0] == :orders }
    KyoShopOrders.goods = (@orders + orders).sort.uniq
    $game_temp.shop_goods = (@goods + gds).sort.uniq
  end

  def strings_goods_conversion(strings)
    data = []
    strings.each {|string| data << retrieve_item(string) }
    data
  end

  def retrieve_item(string)
    case string[0,1]
    when 'i' then [0, string[1..-1].to_i]
    when 'w' then [1, string[1..-1].to_i]
    when 'a' then [2, string[1..-1].to_i]
    end
  end

  def update_discount_message
    if @buy_window.discount < 0
      text = sprintf(KyoShopLabels::APPLYDISCOUNT, @discount_window.item.price)
    else
      cd = $game_party.check_discounts
      text = cd ? KyoShopLabels::SOMEDISCOUNTS : KyoShopLabels::NODISCOUNTS
    end
    @question_window.set_text(text)
  end

  def terminate
    dispose_menu_background
    dispose_command_window
    @discount_window.dispose
    @extras_window.dispose
    @order_window.dispose
    @pickup_window.dispose
    @question_window.dispose
    @help_window.dispose
    @gold_window.dispose
    @dummy_window.dispose
    @buy_window.dispose
    @sell_window.dispose
    @number_window.dispose
    @status_window.dispose
    if @need_appraisal
      @appraise_item_window.dispose
      @appraise_info_window.dispose
      @appraise_options.dispose
      @result_info_window.dispose
      @favor_options.dispose
    end
    KyoShopOrders.goods.clear
    KyoShopOrders.steps.clear
    KyoShopOrders.commissions.clear
    KyoShopOrders.store_id = 0
    @stage = @shop_id = nil
  end

  def update
    super
    update_menu_background
    @help_window.update
    @gold_window.update
    @number_window.update
    @status_window.update
    case @stage
    when :main then update_command
    when :option then update_extras
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
      Sound.play_cancel
      $scene = Scene_Map.new
      return
    elsif Input.trigger?(Input::C)
      case @command_window.index
      when 0  # buy
        Sound.play_decision
        @command_window.active = false
        @extras_window.appear
        @question_window.visible = true
        update_discount_message
        return @stage = :option
      when 1  # sell
        return Sound.play_buzzer if $game_temp.shop_purchase_only
        Sound.play_decision
        @command_window.active = false
        @dummy_window.visible = false
        @sell_window.appear
        @sell_window.refresh
        return @stage = :sell
      when 2  # Quit
        Sound.play_decision
        $scene = Scene_Map.new
      end
    end
  end

  def update_extras
    @extras_window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @extras_window.disappear
      @question_window.visible = false
      @command_window.active = true
      return @stage = :main
    elsif Input.trigger?(Input::C)
      if @no_orders and @extras_window.index == 2
        return Sound.play_buzzer
      end
      shares = $game_system.shop_shares[@shop_id]
      inv_max, inv_price = KyoShop::SHARESMAXMIN
      if @extras_window.index == 4 and inv_max == shares
        return Sound.play_buzzer
      end
      Sound.play_decision
      @extras_window.disappear
      @dummy_window.visible = false
      @status_window.visible = true
      @question_window.visible = @extras_window.index != 3
      update_discount_message
      case @extras_window.index
      when 0 # purchase
        @status_window.item = @buy_window.item
        @buy_window.appear
        @buy_window.refresh
        @last_stage = :option
        return @stage = :purchase
      when 1 # place order
        @status_window.item = @order_window.item
        @order_window.appear
        @question_window.set_text(KyoShopLabels::FEESAPPLY)
        return @stage = :place
      when 2 # pick up order
        @status_window.item = @pickup_window.item
        @pickup_window.appear
        return @stage = :pickup
      when 3 # appraisals
        @appraise_item_window.appear
        @appraise_info_window.visible = true
        @result_info_window.visible = true
        @dummy_window.visible = false
        @command_window.visible = false
        @number_window.visible = false
        @status_window.visible = false
        @help_window.set_text(KyoShopLabels::APPRAISALMENULABEL)
        return @stage = :appraise
      when 4 # investments
        @status_window.investment = @investment = true
        inv_max = [inv_max - shares, $game_party.gold / inv_price].min
        fake_item = RPG::Item.new
        fake_item.name = KyoShopLabels::SHARES
        @price = inv_price
        @number_window.set(fake_item, inv_max, inv_price, 0, 10)
        @number_window.appear
        @question_window.set_text(KyoShopLabels::INVESTMENT)
        @stage = :number
      end
    end
  end

  def update_purchase
    @buy_window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @buy_window.disappear
      @status_window.visible = false
      @question_window.visible = false
      @dummy_window.visible = true
      @extras_window.appear
      @status_window.item = nil
      @help_window.set_text("")
      return @stage = :option
    elsif Input.trigger?(Input::UP) or Input.trigger?(Input::DOWN)
      @status_window.item = @buy_window.item
      return
    elsif Input.trigger?(KyoShop::DISCOUNTBUTTON)
      unless $game_party.check_discounts
        return Sound.play_buzzer
      end
      Sound.play_decision
      @buy_window.disappear
      @discount_window.refresh
      @discount_window.appear
      @question_window.set_text(KyoShopLabels::SELECTDISCOUNT)
      return @stage = :discount
    elsif Input.trigger?(Input::C)
      @item = @buy_window.item
      number = $game_party.item_number(@item)
      shop_max = KyoShop.current_item_max
      if @item == nil or @item.price > $game_party.gold or number == shop_max
        return Sound.play_buzzer
      end
      Sound.play_decision
      max = @item.price == 0 ? shop_max : $game_party.gold / @item.price
      max = [max, shop_max - number].min
      @buy_window.disappear
      discount = @buy_window.discount < 0 ? @buy_window.discount : 0
      @number_window.set(@item, max, @item.price, discount)
      @number_window.appear
      @last_stage = :purchase
      @stage = :number
    end
  end

  def update_place_order
    @order_window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @status_window.disappear
      @order_window.disappear
      @extras_window.appear
      @dummy_window.visible = true
      @question_window.visible = false
      return @stage = :option
    elsif Input.trigger?(Input::UP) or Input.trigger?(Input::DOWN)
      @status_window.item = @order_window.item
      return
    elsif Input.trigger?(Input::C)
      @item = @order_window.item
      @price = @item.price
      percent = KyoShopOrders.commissions[@order_window.index]
      @price += percent * @item.price / 100 if percent > 0
      number = $game_party.item_number(@item)
      shop_max = KyoShop.current_item_max
      if @item == nil or @price > $game_party.gold or number == shop_max
        Sound.play_buzzer
        return
      end
      Sound.play_decision
      max = @price == 0 ? shop_max : $game_party.gold / @price
      max = [max, shop_max - number].min
      @order_window.disappear
      @number_window.set(@item, max, @price, percent)
      @number_window.appear
      @last_stage = :place
      @stage = :number
    end
  end

  def update_pickup_order
    @pickup_window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @status_window.disappear
      @pickup_window.disappear
      @extras_window.appear
      @dummy_window.visible = true
      @question_window.visible = false
      return @stage = :option
    elsif Input.trigger?(Input::UP) or Input.trigger?(Input::DOWN)
      @status_window.item = @pickup_window.item
      return
    elsif Input.trigger?(Input::C)
      unless (goods = $game_system.placed_orders[@pack_id])
        return Sound.play_buzzer
      end
      current_item = @pickup_window.item
      goods = goods[@pickup_window.index]
      unless current_item and goods[3] <= $game_party.steps
        return Sound.play_buzzer
      end
      Sound.play_decision
      number = goods[2]
      $game_party.gain_item(current_item, number)
      $game_system.placed_orders[@pack_id].delete_at(@pickup_window.index)
      @pickup_window.reload_goods($game_system.placed_orders[@pack_id])
      @last_stage = :pickup
      @stage = :number
    end
  end

  def update_discount
    @discount_window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @discount_window.disappear
      @buy_window.appear
      return @stage = :purchase
    elsif Input.trigger?(Input::C)
      Sound.play_decision
      @coupons_allowed = KyoShop::COUPON_IDS.include?(@discount_window.item.id)
      @buy_window.discount = -@discount_window.item.price
      @buy_window.refresh
      @discount_window.disappear
      @buy_window.appear
      update_discount_message
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
      Sound.play_cancel
      @appraise_item_window.disappear
      @appraise_info_window.visible = false
      @question_window.visible = false
      @result_info_window.visible = false
      @result_info_window.contents.clear
      @appraise_options.disappear
      @dummy_window.visible = true
      @command_window.visible = true
      @extras_window.appear
      @help_window.set_text("")
      return @stage = :option
    elsif Input.trigger?(Input::C)
      return Sound.play_buzzer if @appraise_item_window.empty?
      Sound.play_decision
      @appraise_options.appear
      @stage = :appraise_option
    end
  end

  def update_appraisal_option
    @appraise_options.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @appraise_options.disappear
      return @stage = :appraise
    elsif Input.trigger?(Input::C)
      data = KyoShop::APPRAISALS[@shop_id]
      price = case @appraise_options.index
      when 0 then data[:test_cost]
      when 1 then data[:cost]
      when 2 then -10
      end
      if price == -10 or $game_party.gold < price
        Sound.play_buzzer
        @appraise_options.disappear
        return @stage = :appraise
      end
      Sound.play_decision
      $game_party.lose_gold(price)
      $game_party.lose_item(@appraise_item_window.item, 1)
      if rand(100) < data[:rate]
        goods = data[:goods]
        favors = $game_system.shop_favors[@shop_id]
        goods += data[:extras] if data[:help_limit] <= favors
        key = goods[rand(goods.size)]
      else
        key = data[:default]
      end
      kind, id = retrieve_item(key)
      new_item = case kind
      when 0 then $data_items[id]
      when 1 then $data_weapons[id]
      when 2 then $data_armors[id]
      end
      if data[:target].has_key?(key)
        @appraise_options.disappear
        @favor_options.appear
        @result_info_window.ask_favor(new_item)
        @target_item = new_item
        @target_key = key
        @target_points = data[:target][key]
        @haggle_enabled = data[:haggle]
        @haggle_max = data[:overprice]
        return @stage = :appraise_favor
      end
      $game_party.gain_item(new_item, 1)
      @result_info_window.refresh(new_item)
      @appraise_item_window.refresh
      @gold_window.refresh
      @appraise_options.disappear
      @stage = :appraise
    end
  end

  def update_appraisal_favor
    @favor_options.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @favor_options.disappear
      return @stage = :appraise
    elsif Input.trigger?(Input::C)
      case @favor_options.index
      when 0
        if @overprice
          Sound.play_shop
          $game_system.shop_favors[@shop_id] += @target_points
          price = @overprice
          @target_points = nil
        else
          Sound.play_decision
          price = @target_item.price
        end
        $game_party.gain_gold(price)
        @overprice = @target_item = nil
      when 1
        return Sound.play_buzzer unless @haggle_enabled
        Sound.play_decision
        @haggle_enabled = nil
        @overprice = rand(@haggle_max) + 1
        @overprice = 25 if @overprice < 25
        @overprice += @target_item.price
        @result_info_window.make_offer(@overprice)
        return
      when 2
        Sound.play_decision
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

  def update_sell
    @sell_window.update
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @dummy_window.visible = true
      @sell_window.disappear
      @status_window.item = nil
      @help_window.set_text("")
      return @stage = :main
    elsif Input.trigger?(Input::C)
      @item = @sell_window.item
      @status_window.item = @item
      if @item == nil or @item.price == 0
        return Sound.play_buzzer
      end
      Sound.play_decision
      max = $game_party.item_number(@item)
      @sell_window.disappear
      @number_window.set(@item, max, @item.price / 2)
      @number_window.appear
      @status_window.visible = true
      @stage = :number
    end
  end

  def update_number
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @number_window.disappear
      if @extras_window.index == 1
        @order_window.appear
        return @stage = :place
      elsif @extras_window.index == 4
        return update_cancel_investment
      end
      case @command_window.index
      when 0
        @buy_window.appear
        return @stage = :purchase
      when 1  # Sell
        @sell_window.appear
        @status_window.visible = false
        return @stage = :sell
      end
    elsif Input.trigger?(Input::C)
      decide_number_input
    end
  end

  def decide_number_input
    Sound.play_shop
    @number_window.disappear
    case @extras_window.index
    when 1
      decide_number_order
      return
    when 4
      decide_number_investment
      return
    end
    case @command_window.index
    when 0  # Buy
      percent = KyoShop.current_price_max
      price = @item.price + @item.price * percent / 100
      price += price * @buy_window.discount / 100
      $game_party.lose_gold(@number_window.number * price)
      $game_party.gain_item(@item, @number_window.number)
      if @coupons_allowed
        @coupons_allowed = nil
        $game_party.lose_item(@discount_window.item, 1)
        @buy_window.discount = 0
        update_discount_message
        @discount_window.refresh
      end
      @gold_window.refresh
      @buy_window.refresh
      @status_window.refresh
      @buy_window.appear
      return @stage = :purchase
    when 1  # sell
      $game_party.gain_gold(@number_window.number * (@item.price / 2))
      $game_party.lose_item(@item, @number_window.number)
      @gold_window.refresh
      @sell_window.refresh
      @status_window.refresh
      @sell_window.appear
      @status_window.visible = false
      @stage = :sell
    end
  end

  def decide_number_order
    percent = KyoShopOrders.commissions[@order_window.index]
    percent += KyoShop.current_price_max
    price = @item.price + @item.price * percent / 100
    $game_party.lose_gold(@number_window.number * price)
    steps = $game_party.steps + KyoShopOrders.steps[@order_window.index]
    order = [nil, @item.id, @number_window.number, steps]
    order[0] = case @item
    when RPG::Item then 0
    when RPG::Weapon then 1
    when RPG::Armor then 2
    end
    unless $game_system.placed_orders[@pack_id]
      @no_orders = nil
      @extras_window.draw_item(2, true)
    end
    $game_system.placed_orders[@pack_id] << order
    @pickup_window.reload_goods($game_system.placed_orders[@pack_id])
    @status_window.refresh
    @gold_window.refresh
    @order_window.refresh
    @order_window.appear
    @stage = :place
  end

  def decide_number_investment
    $game_system.shop_shares[@shop_id] += @number_window.number
    update_goods_orders_after_investment
    @order_window.deliver(KyoShopOrders.goods)
    @buy_window.deliver($game_temp.shop_goods)
    @gold_window.refresh
    update_cancel_investment
  end

  def update_cancel_investment
    @investment = nil
    @status_window.investment = nil
    @status_window.visible = false
    @question_window.visible = false
    @dummy_window.visible = true
    @number_window.reset_multiplier
    @number_window.disappear
    @extras_window.appear
    @stage = :option
  end
end