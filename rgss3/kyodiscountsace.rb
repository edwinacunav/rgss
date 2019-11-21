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
  MYSTERIOUSITEMS = [23,24,35]
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
  OPTIONS = 'Check Out'
  # Buy Stuff & Place Order & Pick Up Items Label
  BUYPLACEPICKUP = ['Buy Items', 'Place Order', 'Pick Up Items',
                    'Appraise', 'Invest']
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
    attr_accessor :store_id, :goods_id, :goods, :commissions
    attr_reader :steps
    def steps=(val) @steps = val.map {|n| n + rand((n / 2) + 2) } end
    def <<(val)
      @commissions += val
      @commissions = @commissions.flatten
    end
    def clear_all
      @store_id = 0
      @goods.clear
      @steps.clear
      @commissions.clear
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

  def reset_discount_item(item, n)
    return if item.class != RPG::Item or n == 0
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
  def max_item_number(item) KyoShop::NUMBERMAX end
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
  def command_126
    value = operate_value(@params[1], @params[2], @params[3])
    item = $data_items[@params[0]]
    $game_party.gain_item(item, value)
    $game_party.reset_discount_item(item, value)
  end

  def command_302
    return if $game_party.in_battle
    goods = [@params]
    while next_event_code == 605
      @index += 1
      goods << @list[@index].parameters
    end
    if $game_switches[KyoShop::GOODSSWITCHID]
      $game_switches[KyoShop::GOODSSWITCHID] = false
      KyoShopOrders.store_id = @event_id
      KyoShopOrders.goods += goods
    else
      SceneManager.call(Scene_Shop)
      SceneManager.scene.prepare(goods, @params[4])
    end
    Fiber.yield
  end
end

module WindowAppear
  def appear
    self.active = true
    self.visible = true
  end

  def disappear
    self.active = false
    self.visible = false
  end
end

class Window_ShopHelp < Window_Base
  def initialize(new_x, new_y, new_width)
    super(new_x, new_y, new_width, 48)
    self.z += 100
  end

  def set_text(text)
    @text = text
    refresh
  end

  def clear() set_text("") end
  def set_item(item) set_text(item ? item.description : "") end

  def refresh
    contents.clear
    draw_text_ex(4, 0, @text)
  end
end

class Window_ShopCommand
  def make_command_list
    add_command(KyoShopLabels::OPTIONS, :options)
    add_command(Vocab::ShopSell, :sell, !@purchase_only)
    add_command(Vocab::ShopCancel, :cancel)
  end
end

class Window_ShopNumber
  attr_writer :normal_price
  alias kyon_discounts_win_shopnumber_refresh refresh
  def refresh
    kyon_discounts_win_shopnumber_refresh
    return unless @normal_price
    width = contents_width - 8
    price_data = KyoShopLabels::PRICEDATA
    scarce_price = @normal_price * KyoShop.current_price_max / 100
    normal_price = (@normal_price + scarce_price) * @number
    fee = @price * @number - normal_price
    contents.draw_text(x + 40, price_y, width, 24, price_data[0])
    contents.draw_text(x + 40, price_y + 24, width, 24, price_data[1])
    contents.draw_text(x + 40, price_y + 48, width, 24, price_data[3])
    draw_currency_value(normal_price, @currency_unit, 4, price_y, width)
    draw_currency_value(fee, @currency_unit, 4, price_y + 24, width)
  end

  def draw_total_price
    width = contents_width - 8
    new_y = @normal_price ? price_y + 48 : price_y
    draw_currency_value(@price * @number, @currency_unit, 4, new_y, width)
  end
end

class Window_SharesNumber < Window_ShopNumber
  def figures() 3 end
  def total_price() @price * @number end
  def change_number(amount) @number = [[@number + amount, @max].min, 0].max end
  def update_number
    change_number(10)   if Input.repeat?(:RIGHT)
    change_number(-10)  if Input.repeat?(:LEFT)
    change_number(100)  if Input.repeat?(:UP)
    change_number(-100) if Input.repeat?(:DOWN)
  end

  def set(item, max, price, currency_unit = nil)
    @item = item
    @max = max
    @price = price
    @currency_unit = currency_unit if currency_unit
    @number = 0
    refresh
  end

  def reset_number
    shares = $game_system.shop_shares[@shop_id]
    inv_max, inv_price = KyoShop::SHARESMAXMIN
    @max = [inv_max - shares, $game_party.gold / inv_price].min
    @number = 0
    refresh
  end
end

class Window_ShopStatus
  def draw_shares(shop_id)
    contents.clear
    rect = Rect.new(4, 0, contents.width - 8, line_height)
    change_color(system_color)
    draw_text(rect, Vocab::Possession)
    change_color(normal_color)
    draw_text(rect, $game_system.shop_shares[shop_id], 2)
  end
end

class Window_DiscountShopCommand < Window_Command
  def initialize
    super(200, 132)
    self.z += 100
  end

  def make_command_list
    labels = KyoShopLabels::BUYPLACEPICKUP
    symbols = [:buy, :place, :pickup, :appraise, :invest]
    shop_id = $game_variables[KyoShop::STORECODEVARID]
    all = KyoShop::INVESTSTOREIDS.include?(shop_id)? 5 : 4
    all.times {|index| add_command(labels[index], symbols[index]) }
  end
end

class Window_ShopBuy
  def deliver(goods)
    @shop_goods = goods
    if goods.size - 1 < @index
      @index = goods.size > 0 ? (@index + goods.size - 1) % goods.size : 0
      update_cursor
    end
    refresh
    self.index = 0
  end
end

class Window_DiscountShopBuy < Window_ShopBuy
  attr_accessor :discount
  def initialize(x, y, height, shop_goods)
    @discount = 0
    @enable_discount = $game_party.check_discounts
    super
  end

  def process_handling
    return unless open? && active
    return process_ok        if Input.trigger?(Input::C) and ok_enabled?
    return process_cancel    if Input.trigger?(Input::B) and cancel_enabled?
    return process_alternate if Input.trigger?(Input::A)
    return process_pagedown  if Input.trigger?(Input::R) and handle?(:pagedown)
    return process_pageup    if Input.trigger?(Input::L) and handle?(:pageup)
  end

  def process_alternate
    return Sound.play_buzzer unless @enable_discount
    Sound.play_ok
    @handler[:alternate].call
  end

  def price(item)
    this_price = @price[item] || 0
    scarce_cost = this_price * KyoShop.current_price_max / 100
    this_price + scarce_cost + this_price * -@discount / 100
  end

  def draw_item(index)
    item = @data[index]
    rect = Rect.new(0, index * item_height, item_width, item_height)
    draw_item_name(item, 0, rect.y, enable?(item))
    rect.width -= 4
    this_price = price(item)
    draw_text(rect, this_price, 2)
  end
end

class Window_ShopPickUp < Window_DiscountShopBuy
  def ok_enabled?() return true end
  def amount() @shop_goods[@index][2] end
  def steps() @shop_goods[@index][3] end
  def item_enabled?(this_item)
    this_item = @data[@index] if this_item == @index
    return false unless this_item
    number = $game_party.item_number(this_item)
    return (number + self.amount < 100 and self.steps <= $game_party.steps)
  end

  def draw_item(index)
    item = @data[index]
    number = $game_party.item_number(item)
    enough = item_enabled?(item)
    self.contents.font.color.alpha = enough ? 255 : 128
    y = index * 24
    draw_icon(item.icon_index, 0, y, enough)
    self.contents.draw_text(32, y - 4, 212, 32, item.name, 0)
    self.contents.draw_text(180, y - 4, 88, 32, self.amount.to_s, 2)
  end

  def process_ok
    return Sound.play_buzzer unless item_enabled?(@index)
    Sound.play_ok
    Input.update
    $game_party.gain_item(@data[@index], self.amount)
    @data.delete_at(@index)
    shop_id = [$game_map.map_id, KyoShopOrders.store_id]
    $game_system.placed_orders[shop_id].delete_at(@index)
    new_item = @data[@index]
    @help_window.set_item(new_item)
    @status_window.item = new_item
    refresh
  end
end

class Window_ShopOrder < Window_ShopBuy
  def initialize(x, y, height)
    if KyoShopOrders.commissions.empty?
      KyoShopOrders.commissions += [0] * KyoShopOrders.goods.size
    end
    super(x, y, height, KyoShopOrders.goods)
  end
  def steps() KyoShopOrders.steps[@index] end
  def commission() KyoShopOrders.commissions[@index] end
  def current_item_enabled?() $game_party.gold >= item_price end

  def normal_price
    price = @price[self.item]
    price + price * KyoShop.current_price_max / 100
  end

  def price(item)
    this_price = @price[item]
    pos = @data.index(item)
    percent = KyoShopOrders.commissions[pos] + KyoShop.current_price_max
    this_price + this_price * percent / 100
  end

  def item_price
    this_price = @price[self.item]
    percent = KyoShopOrders.commissions[@index] + KyoShop.current_price_max
    this_price + this_price * percent / 100
  end

  def place(number)
    steps = $game_party.steps + KyoShopOrders.steps[@index]
    order = [@shop_goods[@index][0], self.item.id, number, steps]
    shop_id = [$game_map.map_id, KyoShopOrders.store_id]
    $game_system.placed_orders[shop_id] << order
  end

  def draw_item(index)
    item = @data[index]
    rect = Rect.new(0, index * item_height, item_width, item_height)
    this_price = price(item)
    draw_item_name(item, 0, rect.y, $game_party.gold >= this_price)
    rect.width -= 4
    draw_text(rect, this_price, 2)
  end

  def process_ok
    return Sound.play_buzzer unless @data[@index]
    Sound.play_ok
    Input.update
    self.active = false
    @handler[:ok].call
  end
end

class Window_ShopDiscountCoupon < Window_Selectable
  def initialize
    super(0, 120, 304, 296)
    self.index = 0
    refresh
  end

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
    contents.fill_rect(rect, Color.new(0, 0, 0, 0))
    draw_item_name(item, rect.x, rect.y, true)
    contents.draw_text(32, y, 236, 24, ': ' + number.to_s, 2)
  end

  def update_help
    KyoShopOrders.goods_id = self.item.id
    @help_window.set_text(self.item.description)
  end
  def item() @data[@index] end
  def item_max() @item_max || 1 end
end

class AppraiseItemWindow < Window_Selectable
  include WindowAppear
  def initialize
    super(0, 120, 304, Graphics.height - 120)
    @column_max = 1
    refresh
    self.index = 0
  end

  def refresh
    self.contents.clear
    @data = []
    for n in KyoShop::MYSTERIOUSITEMS
      item = $data_items[n]
      next if $game_party.item_number(item) == 0
      @data << item
    end
    for i in KyoShop::MYSTERIOUSWEAPONS
      item = $data_weapons[i]
      next if $game_party.item_number(item) == 0
      @data << item
    end
    for i in KyoShop::MYSTERIOUSARMORS
      item = $data_armors[i]
      next if $game_party.item_number(item) == 0
      @data << item
    end
    @item_max = @data.size
    return if @item_max == 0
    self.contents = Bitmap.new(width - 32, row_max * 32)
    @item_max.times{|i| draw_item(i) }
  end

  def draw_item(index)
    item = @data[index]
    number = $game_party.item_number(item)
    c = self.contents
    iy = index * 24
    draw_icon(item.icon_index, 4, iy)
    c.draw_text(32, iy - 6, 212, 32, item.name, 0)
    c.draw_text(232, iy - 4, 16, 32, ":", 1)
    c.draw_text(214, iy - 4, 60, 32, number.to_s, 2)
  end

  def process_ok
    return Sound.play_buzzer unless @data[@index]
    Sound.play_ok
    Input.update
    self.active = false
    @handler[:ok].call
  end
  def item_max() @item_max || 1 end
  def item() @data[@index] end
  def empty?() @data.empty? end
end

class AppraiseInfoWindow < Window_Base
  def initialize(store_id)
    super(304, 120, Graphics.width - 304, Graphics.height - 120)
    @data = KyoShop::APPRAISALS[store_id]
    @labels = KyoShopLabels::APPRAISALLABELS.dup
    @currency = $data_system.currency_unit
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

class AppraiseCommandWindow < Window_Command
  include WindowAppear
  def make_command_list
    keys = [:quick, :full, :cancel]
    options = KyoShopLabels::APPRAISALOPTIONS.dup
    options.size.times {|n| add_command(options[n], keys[n], true) }
  end
end

class AppraiseFavorCommandWindow < Window_Command
  include WindowAppear
  def make_command_list
    keys = [:ok, :haggle, :cancel]
    options = KyoShopLabels::APPRAISALHAGGLEOPTIONS.dup
    options.size.times {|n| add_command(options[n], keys[n], true) }
  end

  def draw_command(index, enabled)
    change_color(normal_color, enabled)
    draw_text(item_rect_for_text(index), command_name(index), alignment)
  end

  def process_ok
    return Sound.play_buzzer if @index == 1 and !@list[@index][:enabled]
    Input.update
    self.active = false if @index != 1
    symbol = case @index
    when 0 then :ok
    when 1 then :haggle
    when 2 then :cancel
    end
    @handler[symbol].call
  end
end

class Scene_Shop
  alias kyon_discounts_scn_shop_start start
  alias kyon_discounts_scn_shop_create_number_window create_number_window
  alias kyon_discounts_scn_shop_command_buy command_buy
  alias kyon_discounts_scn_shop_on_buy_ok on_buy_ok
  def start
    kyon_discounts_scn_shop_start
    @shop_id ||= $game_variables[KyoShop::STORECODEVARID]
    @orders = KyoShopOrders.goods.dup
    qwidth = Graphics.width - @gold_window.width
    @question_window = Window_ShopHelp.new(0, 72, qwidth)
    @question_window.hide
    create_extras_window
    create_cards_pickup_windows
    create_order_window
    create_appraisal_windows
    update_goods_orders_after_investment
  end

  def create_extras_window
    @extras_window = Window_DiscountShopCommand.new
    @extras_window.hide.deactivate
    @extras_window.set_handler(:buy, method(:command_buy))
    @extras_window.set_handler(:place, method(:command_place))
    @extras_window.set_handler(:pickup, method(:command_pickup))
    @extras_window.set_handler(:appraise, method(:command_appraise))
    @extras_window.set_handler(:invest, method(:command_invest))
    @extras_window.set_handler(:cancel, method(:command_cancel))
  end

  def create_cards_pickup_windows
    @cards_window = Window_ShopDiscountCoupon.new
    @cards_window.hide.deactivate
    @cards_window.set_handler(:ok, method(:on_card_ok))
    @cards_window.set_handler(:cancel, method(:on_card_cancel))
    key = [$game_map.map_id, KyoShopOrders.store_id]
    orders = $game_system.placed_orders[key]
    @pickup_window = Window_ShopPickUp.new(0, 120, 296, orders)
    @pickup_window.help_window = @help_window
    @pickup_window.status_window = @status_window
    @pickup_window.hide
    @pickup_window.set_handler(:cancel, method(:on_pickup_cancel))
  end

  def create_command_window
    @command_window = Window_ShopCommand.new(@gold_window.x, @purchase_only)
    @command_window.viewport = @viewport
    @command_window.y = @help_window.height
    @command_window.set_handler(:options, method(:command_options))#Changed
    @command_window.set_handler(:sell,    method(:command_sell))
    @command_window.set_handler(:cancel,  method(:return_scene))
  end

  def create_number_window
    kyon_discounts_scn_shop_create_number_window
    @shares_window = Window_SharesNumber.new(0, 120, 296)
    @shares_window.viewport = @viewport
    @shares_window.hide
    @shares_window.set_handler(:ok,     method(:on_shares_ok))
    @shares_window.set_handler(:cancel, method(:on_shares_cancel))
  end

  def create_buy_window
    @buy_window = Window_DiscountShopBuy.new(0, 120, 296, @goods)
    @buy_window.viewport = @viewport
    @buy_window.help_window = @help_window
    @buy_window.status_window = @status_window
    @buy_window.hide.deactivate
    @buy_window.set_handler(:ok, method(:on_buy_ok))
    @buy_window.set_handler(:cancel, method(:on_buy_cancel))
    @buy_window.set_handler(:alternate, method(:on_buy_card))
  end

  def create_order_window
    @order_window = Window_ShopOrder.new(0, 120, 296)
    @order_window.viewport = @viewport
    @order_window.help_window = @help_window
    @order_window.status_window = @status_window
    @order_window.hide.deactivate
    @order_window.set_handler(:ok,     method(:on_order_ok))
    @order_window.set_handler(:cancel, method(:on_order_cancel))
  end

  def create_appraisal_windows
    if (@need_appraisal = KyoShop::APPRAISALS.keys.include?(@shop_id))
      @appraise_item_window = AppraiseItemWindow.new
      @appraise_item_window.viewport = @viewport
      @appraise_item_window.visible = false
      @appraise_item_window.set_handler(:ok, method(:appraise_item_ok))
      @appraise_item_window.set_handler(:cancel, method(:appraise_item_cancel))
      @appraise_info_window = AppraiseInfoWindow.new(@shop_id)
      @appraise_info_window.viewport = @viewport
      @appraise_info_window.visible = false
      @appraise_options = AppraiseCommandWindow.new(240, 200)
      @appraise_options.viewport = @viewport
      @appraise_options.disappear
      @appraise_options.set_handler(:quick, method(:perform_appraisal))
      @appraise_options.set_handler(:full, method(:perform_appraisal))
      @appraise_options.set_handler(:cancel, method(:on_appraise_cancel))
      @favor_options = AppraiseFavorCommandWindow.new(240, 200)
      @favor_options.viewport = @viewport
      @favor_options.disappear
      @favor_options.set_handler(:ok, method(:on_favor_ok))
      @favor_options.set_handler(:haggle, method(:on_favor_haggle))
      @favor_options.set_handler(:cancel, method(:on_favor_cancel))
    else
      @extras_window.draw_item(3, nil)
    end
  end

  def update_goods_orders_after_investment
    goods = []
    orders = []
    stuff = $game_system.check_shares(@shop_id)
    return if stuff.empty?
    stuff.dup.each do |g|
      case g.shift
      when :goods then goods += g.map {|str| retrieve_item(str) }
      when :orders then orders += g.map {|str| retrieve_item(str) }
      end
    end
    KyoShopOrders.goods = (@orders + orders).sort.uniq
    @goods = (@goods + goods).sort.uniq
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

  def pre_terminate
    KyoShopOrders.clear_all
    @shop_id = nil
  end

  def hide_some_windows
    @extras_window.hide.deactivate
    @dummy_window.hide
    @command_window.hide
    @status_window.show
    @question_window.show
  end

  def show_extras_windows
    @status_window.hide
    @question_window.hide
    @dummy_window.show
    @command_window.show
    @extras_window.show.activate
    @status_window.item = nil
    @help_window.clear
  end

  def command_options
    @command_window.deactivate
    @extras_window.show.activate
  end

  def command_cancel
    @extras_window.hide.deactivate
    @command_window.activate
  end

  def command_buy
    @extras_window.hide.deactivate
    @command_window.hide
    @question_window.show
    update_discount_message
    kyon_discounts_scn_shop_command_buy
  end

  def command_place
    hide_some_windows
    @question_window.set_text(KyoShopLabels::PLACEORDER)
    @order_window.show.activate
  end

  def command_pickup
    hide_some_windows
    @question_window.set_text(KyoShopLabels::PICKUPORDER)
    @pickup_window.show.activate
  end

  def command_appraise
    hide_some_windows
    @status_window.visible = false
    @appraise_info_window.visible = true
    @question_window.set_text(KyoShopLabels::APPRAISALMENULABEL)
    @appraise_item_window.appear
  end

  def command_invest
    hide_some_windows
    @question_window.set_text(KyoShopLabels::INVESTMENT)
    shares = $game_system.shop_shares[@shop_id]
    fake_item = RPG::Item.new
    fake_item.name = KyoShopLabels::SHARES
    inv_max, inv_price = KyoShop::SHARESMAXMIN
    inv_max = [inv_max - shares, $game_party.gold / inv_price].min
    unit = @gold_window.currency_unit
    @shares_window.set(fake_item, inv_max, inv_price, unit)
    @shares_window.show.activate
    @status_window.draw_shares(@shop_id)
  end

  def on_buy_ok
    @number_window.normal_price = nil
    kyon_discounts_scn_shop_on_buy_ok
  end

  def on_buy_cancel
    @buy_window.hide
    show_extras_windows
  end

  def on_buy_card
    @buy_window.hide.deactivate
    @cards_window.show.activate
  end

  def on_card_ok
    @coupons_allowed = KyoShop::COUPON_IDS.include?(@cards_window.item.id)
    @cards_window.hide
    @buy_window.discount = @cards_window.item.price
    @buy_window.refresh
    @buy_window.show.activate
    update_discount_message
  end

  def on_card_cancel
    @cards_window.hide
    @buy_window.show.activate
  end

  def on_order_ok
    @item = @order_window.item
    price = @order_window.item_price
    @order_window.hide.deactivate
    unit = @gold_window.currency_unit
    max = $game_party.max_item_number(@item) - $game_party.item_number(@item)
    max_buy = price == 0 ? max : [max, $game_party.gold / price].min
    @number_window.normal_price = @order_window.normal_price
    @number_window.set(@item, max_buy, price, unit)
    @number_window.show.activate
  end

  def on_order_cancel
    @order_window.hide.deactivate
    show_extras_windows
  end

  def on_pickup_cancel
    @pickup_window.hide.deactivate
    show_extras_windows
  end

  def on_number_ok
    Sound.play_shop
    @number_window.hide
    if @command_window.current_symbol == :sell
      do_sell(@number_window.number)
      activate_sell_window
      @gold_window.refresh
      @status_window.refresh
      return
    end
    case @extras_window.current_symbol
    when :buy then do_purchase
    when :place then do_place
    end
    @gold_window.refresh
    @status_window.refresh
  end

  def on_number_cancel
    Sound.play_cancel
    @number_window.hide.deactivate
    if @command_window.current_symbol == :sell
      activate_sell_window
      return
    end
    case @extras_window.current_symbol
    when :buy then activate_buy_window
    when :place then @order_window.show.activate
    end
  end

  def appraise_item_ok() @appraise_options.appear end

  def appraise_item_cancel
    @appraise_info_window.visible = false
    @appraise_item_window.visible = false
    show_extras_windows
  end

  def perform_appraisal
    @appraise_options.disappear
    data = KyoShop::APPRAISALS[@shop_id]
    price = case @appraise_options.index
    when 0 then data[:test_cost]
    when 1 then data[:cost]
    when 2 then -10
    end
    return Sound.play_buzzer if price == -10 or $game_party.gold < price
    Sound.play_ok
    $game_party.lose_gold(price)
    @gold_window.refresh
    $game_party.lose_item(@appraise_item_window.item, 1)
    @appraise_item_window.refresh
    if rand(100) < data[:rate]
      goods = data[:goods]
      favors = $game_system.shop_favors[@shop_id]
      goods += data[:extras] if data[:help_limit] <= favors
      key = goods[rand(goods.size)]
    else
      key = data[:default]
    end
    kind, id = retrieve_item(key)
    @target_item = case kind
    when 0 then $data_items[id]
    when 1 then $data_weapons[id]
    when 2 then $data_armors[id]
    end
    data[:target].has_key?(key) ? make_offer(key, data) : no_offer
    @favor_options.draw_command(1, @haggle_enabled)
    @favor_options.appear
  end

  def make_offer(key, data)
    @target_key = key
    @target_points = data[:target][key]
    @haggle_enabled = data[:haggle]
    @haggle_max = data[:overprice]
    name, offer = KyoShopLabels::APPRAISALRESULTLABELS[2..3]
    @help_window.set_text(sprintf(name, @target_item.name) + "\n" + offer)
  end

  def no_offer
    $game_party.gain_item(@target_item, 1)
    name, price = KyoShopLabels::APPRAISALRESULTLABELS
    label = sprintf(name, @target_item.name) + "\n"
    label += sprintf(price, @target_item.price) + " "
    @help_window.set_text(label + $data_system.currency_unit)
  end

  def on_appraise_cancel
    @appraise_options.visible = false
    @appraise_item_window.active = true
  end

  def on_favor_ok
    if @overprice
      Sound.play_shop
      $game_system.shop_favors[@shop_id] += @target_points
      price = @overprice
      @target_points = nil
    else
      Sound.play_ok
      price = @target_item.price
    end
    $game_party.gain_gold(price)
    @overprice = @target_item = nil
    @favor_options.disappear
    @appraise_item_window.active = true
    @gold_window.refresh
  end

  def on_favor_haggle
    return Sound.play_buzzer unless @haggle_enabled
    Sound.play_ok
    @haggle_enabled = nil
    @favor_options.draw_command(1, nil)
    @overprice = rand(@haggle_max) + 1
    @overprice = 25 if @overprice < 25
    @overprice += @target_item.price
    question, price = KyoShopLabels::APPRAISALRESULTLABELS[4..5]
    text = question + "\n" + sprintf(price, @overprice) + " "
    @help_window.set_text(text + $data_system.currency_unit)
    @favor_options.active = true
  end

  def on_favor_cancel
    Sound.play_cancel
    $game_party.gain_item(@target_item, 1)
    @target_item = nil
    @favor_options.disappear
    @appraise_item_window.active = true
  end

  def on_shares_ok
    if $game_party.gold < KyoShop::SHARESMAXMIN[1]
      return Sound.play_buzzer
    end
    Sound.play_shop
    $game_system.shop_shares[@shop_id] += @shares_window.number
    update_goods_orders_after_investment
    @order_window.deliver(KyoShopOrders.goods)
    @buy_window.deliver(@goods)
    $game_party.lose_gold(@shares_window.total_price)
    @shares_window.reset_number
    @shares_window.show.activate
    @status_window.draw_shares(@shop_id)
    @gold_window.refresh
  end

  def on_shares_cancel
    Sound.play_cancel
    @shares_window.hide.deactivate
    show_extras_windows
  end

  def do_purchase
    do_buy(@number_window.number)
    if @coupons_allowed
      @coupons_allowed = nil
      $game_party.lose_item(@discount_window.item, 1)
      @buy_window.discount = 0
      @buy_window.refresh
      @cards_window.refresh
      update_discount_message
    end
    @buy_window.show.activate
  end

  def do_place
    number = @number_window.number
    $game_party.lose_gold(number * @order_window.item_price)
    @order_window.place(number)
    @pickup_window.refresh
    @order_window.show.activate
  end
end