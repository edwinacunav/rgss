# * Gem Roulette ACE - Stand Alone Version
#   Scripter : Kyonides-Arkanthos
#   v 1.0.7 - 2017-11-14

#   Script Calls

#   To open Gem Roulette : SceneManager.call(Gem_Roulette)

#   To increase Spinning Attempts :  $game_party.roulette_attempts += Number

#   This script will let you spin some gems as if they were part of a Wheel of
#   Fortune. Later on you will collect your prize. Previous prizes will be
#   displayed on the window on the right hand side.

#   Prizes are picked up randomly but you can configure what prizes they might
#   get if you edit the file named as shown on the PRIZE_FILENAME Constant below

#   There is the possibility of not letting the player get a prize depending on
#   then gem or slot selected by the script.

#   Don't forget to include the sprites needed for the 10 Gem-Slots.

module GemRouletteSetup
  # Gem Icon Sprite Name Prefix - will be used as Slots
  ICON_NAME_PREFIX = 'gem'
  # SE for Startup and Prize is ready to be collected
  SE_STARTUP = "056-Right02"
  # Prizes TXT Filename
  PRIZE_FILENAME = 'prizes.txt'
  # Label for Position or Slot
  POSITION_LABEL = 'Slot'
  # Label for No Prize for you
  NO_PRIZE = 'Nothing'
  # Label for Item as Prize
  ITEM_PRIZE   = 'Item'
  # Label for Weapon as Prize
  WEAPON_PRIZE = 'Weapon'
  # Label for Armor as Prize
  ARMOR_PRIZE  = 'Armor'
  # Label for Skill as Prize
  SKILL_PRIZE  = 'Skill'
  # Label for HP as Prize or Punishment
  HP_LOSS = 'HP'
  # Label for MP as Prize or Punishment
  MP_LOSS = 'MP'
  # Icon filename for Losing HP or SP
  STATS_LOSS_ICON = ''
  # Points Earned Label
  STATS_LOSS_LABEL = ' Earned: '
  # Attempts Left Label
  ATTEMPTS_LEFT = 'Attempts Left: '
  # Spin the Wheel String
  SPIN_WHEEL = 'Spin Wheel'
  # Collect Prize String
  COLLECT = 'Collect'
  # No More Spins Left String
  RUNOUT = 'No More Spins'
  # Better Luck Next Time String
  NEXT_TIME = 'Better Luck Next Time!'
  # Points Label
  POINTS = 'Points'
  # DO NOT EDIT ANYTHING BELOW THIS LINE
  PRIZE_RVDATA = 'Data/GemRoulette.rvdata2'
  PRIZES = {}
  @prizes = []
  @prize_points = []
  module_function
  def prize_points() @prize_points end
  def prizes() @prizes end
  def get_prize_data
    if File.exist?(PRIZE_FILENAME)
      lines = File.readlines(PRIZE_FILENAME)
      10.times do |n|
        pts = lines[0].scan(/\d+ #{POINTS}/)[0].sub!(/ #{POINTS}/,'')
        @prize_points << pts.to_i
        lines.shift
        PRIZES[n] = []
        regex = /[a-zA-Z]+/
        kinds = lines[0].scan(regex).map {|ln| self.prize_kind(ln) }
        indexes = lines[0].scan(/[0-9\-]+/).map {|ln| self.prize_kind(ln) }
        kinds.size.times {|m| PRIZES[n] << [kinds[m], indexes[m]] }
        lines.shift
      end
      File.open(PRIZE_RVDATA, 'wb') {|file|
        Marshal.dump(@prize_points, file)
        Marshal.dump(PRIZES, file)  }
      return
    end
    File.open(PRIZE_RVDATA, 'rb') do |file|
      @prize_points = Marshal.load(file)
      PRIZES.merge!(Marshal.load(file))
    end
  end

  def prize_kind(kind)
    regexp = /\d+/
    prize = case kind
    when ITEM_PRIZE then :item
    when WEAPON_PRIZE then :weapon
    when ARMOR_PRIZE then :armor
    when SKILL_PRIZE then :skill
    when HP_LOSS then :hp
    when MP_LOSS then :mp
    when regexp then kind.to_i
    end
    return prize
  end
  get_prize_data
end

class StatsItem
  attr_reader :name, :points, :icon_name
  def initialize(new_name, new_points)
    @name = new_name.to_s.upcase + ' ' + GemRouletteSetup::STATS_LOSS_LABEL
    @name += new_points.to_s
    @points = new_points
    @icon_name = GemRouletteSetup::STATS_LOSS_ICON
  end
end

module Cache
  def self.old_icon(filename) load_bitmap("Graphics/Icons/", filename) end
end

class Sprite
  def draw_icon(icon_index, x=0, y=0, enabled = true)
    self.bitmap = Bitmap.new(24, 24)
    bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    self.bitmap.blt(x, y, bitmap, rect, enabled ? 255 : 128)
  end
end

class Game_Party
  attr_accessor :roulette_attempts, :roulette_points
  alias kyon_gem_roulette_gm_party_init initialize
  def initialize
    @roulette_attempts = 0
    @roulette_points = 0
    @skills = {}
    kyon_gem_roulette_gm_party_init
  end

  def gain_skill(sid, n)
    return unless sid > 0
    @skills[sid] = [[skill_number(sid) + n, 0].max, 99].min
  end
  def lose_skill(sid, n) gain_skill(sid, -n) end
  def skill_number(sid) @skills.include?(sid)? @skills[sid] : 0 end
end

class Sprite_Blink < Sprite
  def update
    super
    if @_blink
      @_blink_count = (@_blink_count + 1) % 32
      alpha = 6 * (@_blink_count < 16 ? 16 - @_blink_count : @_blink_count - 16)
      self.color.set(255, 255, 255, alpha)
    end
    @@_animations.clear rescue nil
  end

  def blink_on
    return if @_blink
    @_blink = true
    @_blink_count = 0
  end

  def blink_off
    return unless @_blink
    @_blink = false
    self.color.set(0, 0, 0, 0)
  end
end

class Window_Base
  def dispose
    (contents.dispose unless disposed?) rescue nil
    super
  end
end

class Window_RoulettePrizes < Window_Base
  def initialize
    super(456, 64, 88, 320)
    @column_max = 2
    refresh
  end

  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    @data = GemRouletteSetup.prizes
    @item_max = @data.size
    return if @item_max == 0
    self.contents = Bitmap.new(width - 32, @item_max * 32)
    @item_max.times {|n| draw_item(n) }
  end

  def draw_item(index)
    x = index % 2 * 32
    y = index / 2 * 32
    icon_index = @data[index]
    bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    self.contents.blt(x, y, bitmap, rect, 255)
  end
end

class Window_SpinCommand < Window_Command
  def make_command_list
    add_command(GemRouletteSetup::SPIN_WHEEL, :spin, true)
  end

  def replace_command_list(index)
    clear_command_list
    opt = case index
    when 0 then GemRouletteSetup::SPIN_WHEEL
    when 1 then GemRouletteSetup::COLLECT
    when 2 then GemRouletteSetup::RUNOUT
    end
    add_command(opt, :spin, true)
    create_contents
    contents.clear
    draw_all_items
  end
end

class Window_GRPLabel < Window_Base
  def initialize(w)
    super(0, 0, w, 56)
    self.contents = Bitmap.new(width - 32, height - 32)
    refresh
  end

  def refresh
    self.contents.clear
    self.contents.font.color = system_color
    points = GemRouletteSetup::POINTS
    self.contents.draw_text(0, 2, self.width - 32, 24, points)
    self.contents.font.color = normal_color
    points = $game_party.roulette_points.to_s
    self.contents.draw_text(0, 2, self.width - 32, 24, points, 2)
  end
end

class Gem_Roulette < Scene_Base
  def initialize
    path = 'Graphics/Icons/'
    items = Dir[path + GemRouletteSetup::ICON_NAME_PREFIX+'*'].sort
    @items = @all_icons = items.map {|item| item.sub!(path, '') }
    @moving_frames = 15
    @steps = 60
    Audio.se_play("Audio/SE/" + GemRouletteSetup::SE_STARTUP, 80, 100)
    @item_sprites = []
    @cx = 320
    @cy = 240
    if @items.size < 10
      @items += @all_icons[0,(10 - @items.size)].dup 
    elsif @items.size > 10
      @items = @items[0,10]
    end
    @item_max = @items.size
    @radius = 120
    @d = 2.0 * Math::PI / @item_max
  end

  def start
    super
    create_background
    make_gem_sprites
    make_attempts_left_label
    @points_window = Window_GRPLabel.new(172)
    @points_window.x = 544 - @points_window.width
    @option_window = Window_SpinCommand.new(192, @prize_sprites[2].y + 36)
    @option_window.set_handler(:spin, method(:command_spin))
    @option_window.set_handler(:cancel, method(:on_personal_cancel))
    @prizes_window = Window_RoulettePrizes.new
  end

  def create_background
    @background_sprite = Sprite.new
    @background_sprite.bitmap = SceneManager.background_bitmap
    @background_sprite.color.set(16, 16, 16, 128)
  end

  def make_gem_sprites
    @item_max.times {|n| @item_sprites << Sprite_Blink.new
      @item_sprites[n].x = @cx - 70 - (@radius * Math.sin(@d * n)).round
      @item_sprites[n].y = @cy - 92 + (@radius * Math.cos(@d * n)).round
      @item_sprites[n].bitmap = Cache.old_icon(@all_icons[n % @all_icons.size])}
    @blink_index = 0
    @item_sprites[@blink_index].blink_on
    @xy = [@item_sprites[0].x, @item_sprites[0].y]
    @prize_sprites = []
    3.times { @prize_sprites << Sprite.new(@viewport3)
      @prize_sprites[-1].z = 5000 }
    @prize_sprites[0].x = @cx - 64
    @prize_sprites[0].y = @cy - 48
    @prize_sprites[1].x = @prize_sprites[0].x - 76
    @prize_sprites[1].y = @prize_sprites[0].y + 26
    @prize_sprites[2].x = 162
    @prize_sprites[2].y = 316
  end

  def make_attempts_left_label
    @prize_sprites[2].bitmap.clear rescue nil
    @prize_sprites[2].bitmap = bitmap = Bitmap.new(220, 32)
    color = Color.new(25, 25, 25, 180)
    @prize_sprites[2].bitmap.fill_rect(0, 0, 220, 32, color)
    total = GemRouletteSetup::ATTEMPTS_LEFT + $game_party.roulette_attempts.to_s
    bitmap.draw_text(0, 0, 220, 32, total, 1)
  end

  def terminate
    super
    @background_sprite.dispose
    @prize_sprites.each{|sprite| sprite.dispose rescue nil }
    @item_sprites.each{|sprite| sprite.dispose rescue nil }
    @xy.clear
    @prize_sprites.clear
    @item_sprites.clear
    @all_icons.clear
    @prize_sprites = @item_sprites = @all_icons = @xy = nil
  end

  def command_spin
    if $game_party.roulette_attempts == 0
      if @result
        retrieve_new_prize
        on_personal_cancel
      else
        Sound.play_buzzer
        @option_window.activate
      end
      return
    end
    Sound.play_ok
    retrieve_new_prize
  end

  def retrieve_new_prize
    if !@move and !@result
      @item_sprites[@blink_index].blink_off
      @option_window.select(-1)
      @option_window.deactivate
      $game_party.roulette_attempts -= 1
      make_attempts_left_label
      @index = rand(@item_max)
      @move = true
      return
    end
    return unless @result
    GemRouletteSetup.prizes << @new_prize.icon_index if @new_prize
    @prizes_window.refresh
    case @kind
    when :item, :weapon, :armor
      $game_party.gain_item(@new_prize, @new_prize.id, 1)
    when :skill then $game_party.gain_skill(@new_prize.id, 1)
    when :hp then $game_party.actors[0].hp += @new_prize.points
    when :mp then $game_party.actors[0].mp += @new_prize.points
    end
    @prize_sprites[0].bitmap.clear rescue nil
    @prize_sprites[1].bitmap.clear rescue nil
    @result = nil
    index = $game_party.roulette_attempts > 0 ? 0 : 2
    @option_window.replace_command_list(index)
    @option_window.activate
  end

  def on_personal_cancel
    GemRouletteSetup.prizes.clear
    return_scene
  end

  def update
    super
    @item_sprites.each {|sprite| sprite.update }
    if @move
      refresh_sprites
      return
    end
  end

  def refresh_sprites
    d1 = -@d / @moving_frames * 2
    @item_max.times {|n| m = n - @index
      d = @d * m + d1 * @steps
      @item_sprites[n].x = @cx - 70 - (@radius * Math.sin(d)).round
      @item_sprites[n].y = @cy - 92 + (@radius * Math.cos(d)).round }
    @steps -= 1
    return unless @steps == -1
    return @steps += 5 if rand(5) == 0
    Audio.se_play("Audio/SE/" + GemRouletteSetup::SE_STARTUP, 80, 100)
    @move = nil
    @steps = 1 + @moving_frames * (3 + rand(5))
    results = @item_sprites.map {|sprite| @xy == [sprite.x,sprite.y] }
    @blink_index = @result = results.index(true)
    @item_sprites[@blink_index].blink_on
    check_prize
  end

  def check_prize
    $game_party.roulette_points += GemRouletteSetup.prize_points[@blink_index]
    @points_window.refresh
    prizes = GemRouletteSetup::PRIZES[@result]
    if prizes.nil? or prizes[0].nil?
      no_prize
      return
    end
    @new_prize = case prizes.size
    when 1 then prizes[0][0] ? prize_kind(prizes[0][0], prizes[0][1]) : nil
    else
      index = prizes.size > 2 ? rand(prizes.size) : rand(4) % 2
      prize_kind(prizes[index][0], prizes[index][1])
    end
    unless @new_prize
      no_prize
      return
    end
    @prize_sprites[0].draw_icon(@new_prize.icon_index)
    @prize_sprites[1].bitmap = bitmap = Bitmap.new(180, 24)
    bitmap.font.bold = true
    bitmap.font.size = 19
    bitmap.draw_text(0, 0, 180, 24, @new_prize.name, 1)
    @option_window.select(0)
    @option_window.replace_command_list(1)
    @option_window.activate
  end

  def prize_kind(kind, index)
    @kind = kind
    case kind
    when :item then $data_items[index]
    when :weapon then $data_weapons[index]
    when :armor then $data_armors[index]
    when :skill then $data_skills[index]
    when :hp, :mp then StatsItem.new(kind, index)
    end
  end

  def no_prize
    @kind = nil
    @prize_sprites[1].bitmap = bitmap = Bitmap.new(200, 24)
    label = GemRouletteSetup::NEXT_TIME
    bitmap.font.bold = true
    bitmap.font.size = 19
    bitmap.draw_text(0, 0, 200, 24, label, 1)
    @option_window.select(0)
    @option_window.activate
  end
end