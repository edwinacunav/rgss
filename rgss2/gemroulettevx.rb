# * Gem Roulette VX
#   Scripter : Kyonides-Arkanthos
#   v 1.0.7 - 2017-11-14

#   Script Calls

#   To open Gem Roulette :           $scene = Gem_Roulette.new

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
  # Icon filename for Losing HP or MP
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
  PRIZE_RVDATA = 'Data/GemRoulette.rvdata'
  PRIZES = {}
  @prizes = []
  @prize_points = []
  def self.prizes() @prizes end
  def self.prize_points() @prize_points end
  def self.get_prize_data
    if $TEST and File.exist?(PRIZE_FILENAME)
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
      File.open(PRIZE_RVDATA, 'wb') do |file|
        Marshal.dump(@prize_points, file)
        Marshal.dump(PRIZES, file)
      end
      return
    end
    File.open(PRIZE_RVDATA, 'rb') {|file|
      @prize_points = Marshal.load(file)
      PRIZES.merge!(Marshal.load(file))  }
  end

  def self.prize_kind(kind)
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
  self.get_prize_data
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

class Window_Roulette_Prizes < Window_Base
  def initialize
    super(456, 56, 88, 320)
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

class Window_Command
  def replace_command(index, command)
    @commands[index] = command
    refresh
  end
end

class Window_GRPLabel < Window_Base
  def initialize(w)
    super(0, 0, w, 64)
    self.contents = Bitmap.new(width - 32, height - 32)
    refresh
  end

  def refresh
    self.contents.clear
    self.contents.font.color = system_color
    points = GemRouletteSetup::POINTS
    self.contents.draw_text(0, 0, self.width - 32, 32, points)
    self.contents.font.color = normal_color
    points = $game_party.roulette_points.to_s
    self.contents.draw_text(0, 0, self.width - 32, 32, points, 2)
  end
end

class Gem_Roulette
  def initialize
    path = 'Graphics/Icons/'
    items = Dir[path + GemRouletteSetup::ICON_NAME_PREFIX+'*'].sort
    @items = items.map{|item| item.sub!(path, '') }
    @moving_frames = 15
    @steps = 60
    Audio.se_play("Audio/SE/" + GemRouletteSetup::SE_STARTUP, 80, 100)
    @item_sprites = []
    @cx = 320
    @cy = 240
    if @items.size < 10
      @items += items[0,(10 - @items.size)].dup
    elsif @items.size > 10
      @items = @items[0,10]
    end
    @item_max = @items.size
    @radius = 120
    @d = 2.0 * Math::PI / @item_max
    @item_max.times {|n| @item_sprites << Sprite_Blink.new
      @item_sprites[n].x = @cx - 70 - (@radius * Math.sin(@d * n)).round
      @item_sprites[n].y = @cy - 92 + (@radius * Math.cos(@d * n)).round
      @item_sprites[n].bitmap = Cache.old_icon(items[n % items.size]) }
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
    make_attempts_left_label
    @option_window = Window_Command.new(160, [GemRouletteSetup::SPIN_WHEEL])
    @option_window.x = 192
    @option_window.y = @prize_sprites[2].y + 36
  end

  def make_attempts_left_label
    @prize_sprites[2].bitmap.clear rescue nil
    @prize_sprites[2].bitmap = bitmap = Bitmap.new(220, 32)
    color = Color.new(25, 25, 25, 180)
    @prize_sprites[2].bitmap.fill_rect(0, 0, 220, 32, color)
    left = GemRouletteSetup::ATTEMPTS_LEFT
    attempts = left + $game_party.roulette_attempts.to_s
    bitmap.draw_text(0, 0, 220, 32, attempts, 1)
  end

  def main
    @spriteset = Spriteset_Map.new
    @points_window = Window_GRPLabel.new(172)
    @points_window.x = 640 - @points_window.width
    3.times {|n| @prize_sprites[n].z = 5000 }
    @item_max.times {|n| @item_sprites[n].z = 5000 }
    @prizes_window = Window_Roulette_Prizes.new
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      break if $scene != self
    end
    Graphics.freeze
    @prizes_window.dispose
    @option_window.dispose
    @xy.clear
    @prize_sprites.each {|sprite| sprite.dispose }
    @prize_sprites.clear
    @item_sprites.each {|sprite| sprite.dispose }
    @item_sprites.clear
    @prize_sprites = @item_sprites = @xy = nil
    @points_window.dispose
    @spriteset.dispose
  end

  def update
    @option_window.update
    @prizes_window.update
    @item_sprites.each {|sprite| sprite.update }
    if @move
      refresh_sprites
      return
    end
    if Input.trigger?(Input::B)
      exit_scene
      return
    elsif Input.trigger?(Input::C)
      if $game_party.roulette_attempts == 0
        if @result
          retrieve_new_prize
          exit_scene
        else
          Sound.play_buzzer
        end
        return
      end
      Sound.play_decision
      retrieve_new_prize
    end
  end

  def exit_scene
    Sound.play_buzzer
    GemRouletteSetup.prizes.clear
    $scene = Scene_Map.new
  end

  def retrieve_new_prize
    if !@move and !@result
      @item_sprites[@blink_index].blink_off
      @option_window.index = -1
      $game_party.roulette_attempts -= 1
      make_attempts_left_label
      @index = rand(@item_max)
      @move = true
      return
    end
    return unless @result
    GemRouletteSetup.prizes << @new_prize.icon_name if @new_prize
    @prizes_window.refresh
    @option_window.index = 0
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
    spin = $game_party.roulette_attempts > 0
    comm = spin ? GemRouletteSetup::SPIN_WHEEL : GemRouletteSetup::RUNOUT
    @option_window.replace_command(0,comm)
  end

  def refresh_sprites
    d1 = -@d / @moving_frames * 2
    @item_max.times {|n| m = n - @index
      d = @d * m + d1 * @steps
      @item_sprites[n].x = @cx - 20 - (@radius * Math.sin(d)).round
      @item_sprites[n].y = @cy - 60 + (@radius * Math.cos(d)).round }
    @steps -= 1
    if @steps == -1
      if rand(5) == 0
        @steps += 5
        return
      end
      Audio.se_play("Audio/SE/" + GemRouletteSetup::SE_STARTUP, 80, 100)
      @move = nil
      @steps = 1 + @moving_frames * (3 + rand(5))
      results = @item_sprites.map {|sprite| @xy == [sprite.x,sprite.y] }
      @blink_index = @result = results.index(true)
      @item_sprites[@blink_index].blink_on
      check_prize
    end
  end

  def check_prize
    $game_party.roulette_points += GemRouletteSetup.prize_points[@blink_index]
    @points_window.refresh
    prizes = GemRouletteSetup::PRIZES[@result]
    return no_prize if prizes.nil? or prizes[0].nil?
    @new_prize = case prizes.size
    when 1 then prizes[0][0] ? prize_kind(prizes[0][0], prizes[0][1]) : nil
    else
      index = prizes.size > 2 ? rand(prizes.size) : rand(4) % 2
      prize_kind(prizes[index][0], prizes[index][1])
    end
    return no_prize unless @new_prize
    @prize_sprites[0].draw_icon(@new_prize.icon_index)
    @prize_sprites[1].bitmap = bitmap = Bitmap.new(180, 24)
    bitmap.font.bold = true
    bitmap.font.size = 19
    bitmap.draw_text(0, 0, 180, 24, @new_prize.name, 1)
    @option_window.replace_command(0, GemRouletteSetup::COLLECT)
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
  end
end