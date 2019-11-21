# * KyoDiscounts Parsing Tool
#   Scripter : Kyonides-Arkanthes
#   2019-07-02

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
    def reset() @data.each {|item| item.total = 0 } end
    def [](key) @data[key] end
    def []=(key, value) @data[key] = value end
    attr_accessor :step_max, :unit_max
  end
  module_function
  def scan_int(line) line.scan(/\d+/).map{|d| d.to_i } end
  def parse_custom_prices
    custom_prices = {}
    default_regex = /default \w+ \w+ \w+. (-\d+|\d+)/i
    value_regex = /(-\d+|\d+)/
    id_value_regex = /(\d+) . (-\d+|\d+)/
    names = Dir['KyoDiscountsTXT/PriceChanges/shop *.txt'].sort
    names.each do |file|
      shop_id = file[/\d+/].to_i
      custom_prices[shop_id] = prices = { 0 => {}, 1 => {}, 2 => {} }
      lines = File.readlines(file)[1..-1]
      prices[:percent] = lines.shift[/yes/i] != nil
      prices[:random] = lines.shift[/yes/i] != nil
      line = lines.shift
      prices[:min], prices[:max] = scan_int(line) if prices[:random]
      lines.each do |line|
        kind = get_kind(line)
        if line[default_regex]
          prices[kind].default = line[value_regex].to_i
          puts prices[kind].default
        else
          line.scan(id_value_regex).flatten.join(", ")
          id, value = line.scan(id_value_regex).flatten.compact
          prices[kind][id.to_i] = value.to_i
        end
      end
    end
    filename = 'Data/KyoDiscountsCustomPrices.rxdata'
    custom_prices.default = { 0 => {}, 1 => {}, 2 => {}, :random => false }
    custom_prices[nil][0].default = 0
    custom_prices[nil][1].default = 0
    custom_prices[nil][2].default = 0
    puts custom_prices[101], custom_prices[1]
    File.open(filename,'wb') {|file| Marshal.dump(custom_prices, file) }
    print "Finished creating KyoDiscountsCustomPrices file!\n"
  end

  def get_kind(line)
    case line
    when /item/i then 0
    when /weapon/i then 1
    when /armor/i then 2
    end
  end

  def parse_appraisals
    appraisals = {}
    names = Dir['KyoDiscountsTXT/Appraisals/shop *.txt'].sort
    names.each do |name|
      shop_id = name.scan(/\d+/)[0].to_i
      lines = File.readlines(name)
      appraisals[shop_id] = appraisal = {}
      appraisal[:cost] = lines[0].scan(/\d+/)[0].to_i
      appraisal[:steps] = lines[1].scan(/\d+/)[0].to_i
      appraisal[:haggle] = lines[2][/yes/i] != nil
      appraisal[:items] = { 0 => [], 1 => [], 2 => [] }
      appraisal[:items][0] = scan_int(lines[4])
      appraisal[:items][1] = scan_int(lines[5])
      appraisal[:items][2] = scan_int(lines[6])
      appraisal[:extra_items] = { 0 => [], 1 => [], 2 => [] }
      appraisal[:extra_items][0] = scan_int(lines[8])
      appraisal[:extra_items][1] = scan_int(lines[9])
      appraisal[:extra_items][2] = scan_int(lines[10])
      items = {}
      weapons = {}
      armors = {}
      temp_items = lines[12].scan(/item \d+\: \w+ \d+/i)
      temp_items.each do |s|
        k, v = scan_int(s)
        items['i'+k.to_s] = v
      end
      temp_weapons = lines[12].scan(/weapon \d+\: \w+ \d+/i)
      temp_weapons.each do |s|
        k, v = scan_int(s)
        weapons['w'+k.to_s] = v
      end
      temp_armors = lines[12].scan(/armor \d+\: \w+ \d+/i)
      temp_armors.each do |s|
        k, v = scan_int(s)
        armors['a'+k.to_s] = v
      end
      appraisal[:target] = {}
      appraisal[:target].merge!(items)
      appraisal[:target].merge!(weapons)
      appraisal[:target].merge!(armors)
      appraisal[:goods] = results = {}
      rest = lines[14..-1]
      rest.each do |line|
        header = line.scan(/\w+ \d+/i)[0]
        rid = get_good_key(header)
        results[rid] = []
        goods = line[(header.size+3)..-1].chomp.downcase.split(",")
        goods.each {|good| results[rid] << get_good_value(good) }
      end
    end
    filename = 'Data/KyoDiscountsAppraisals.rxdata'
    File.open(filename,'wb') {|file| Marshal.dump(appraisals, file) }
    print "Finished creating KyoDiscountsAppraisals file!\n"
  end

  def get_good_key(header)
    id = header.scan(/\d+/)[0].to_i
    header = header.sub(/\s/i,'').downcase
    case header[0]
    when 'i' then [0, id]
    when 'w' then [1, id]
    when 'a' then [2, id]
    end
  end

  def get_good_value(good)
    good = good.gsub(/ /,'')
    case good[0]
    when 'i' then good.gsub(/tem/,'')
    when 'w' then good.gsub(/eapon/,'')
    when 'a' then good.gsub(/rmor/,'')
    end
  end

  def parse_unique_items
    unique_items = {}
    names = Dir['KyoDiscountsTXT/UniqueItems/shop *.txt'].sort
    names.each do |name|
      shop_id = name.scan(/\d+/)[0].to_i
      unique_items[shop_id] = items = UniqueItems.new
      lines = File.readlines(name)
      lines.shift
      line = lines.shift
      items.step_max = line[/none/i] ? 0 : line.scan(/\d+/)[0].to_i
      line = lines.shift
      items.unit_max = line[/none/i] ? 0 : line.scan(/\d+/)[0].to_i
      lines.each do |line|
        kind = get_kind(line)
        item_id, units = scan_int(line)
        items[[kind, item_id]] = item = UniqueItem.new(units)
      end
    end
    filename = 'Data/KyoDiscountsUniqueItems.rxdata'
    File.open(filename,'wb') {|file| Marshal.dump(unique_items, file) }
    print "Finished creating KyoDiscountsUniqueItems file!\n"
  end
  parse_custom_prices
  parse_appraisals
  parse_unique_items
end