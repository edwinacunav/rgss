# * KLotto XP
#   Scripter : Kyonides Arkanthes
#   v1.0.6 - 2019-11-19

# This scriptlet will let you partake in raffles. Once the raffles are over, the
# scene will change back to the current map.

# * Script Calls *

# $scene = KLottoShop.new
#   Opens the shop with default values.

# $scene = KLottoShop.new(SOME_HASH)
# The following options you can use to replace SOME_HASH are optional.
#   :id => 1                   - Changes the shop ID.
#   :name => 'Claudia's Lotto' - Changes the shop's name.
#   :cost => 25                - Changes the ticket cost.
#   :prizes => [25000, 5000]   - Changes the amount of the prize.
#   :max => 5                  - Changes the number of columns aka digits.

# $game_system.winner_tickets
#   Array of Strings - List of previous winner tickets.

# $game_party.winner_tickets
#   Array of Strings - List of winner tickets the party has ever purchased.

# $game_party.purchase_lotto_tickets
# $game_party.purchase_lotto_tickets(Total)
#   Yes, via a script call you can let the player buy some tickets.
#   The Total number can be omitted, its default value is 1.

# $game_party.has_lotto_ticket?(String)
#   String should be a Number converted to a String by calling Number.to_s

# $game_party.discard_lotto_tickets
#   Forces the player to dispose of every single lotto ticket.

module KLotto
  TICKET_ITEM_ID = 31
  PREVIOUS_TICKETS_MAX = 10
  TICKET_PRICE = 10
  DEFAULT_GOLD = [10000, 5000, 2000]
  SPHERES_MIN = 3
  SPHERE_WIDTH = 32 # In Pixels
  FIRST_SPHERE_X = 280
  DISCARD_AFTER_ONE_RAFFLE = true # Discard Tickets after a raffle?
  FILENAME = 'spheres32'
  SE_STARTUP = '056-Right02'
  GENERIC_NAME = 'Generic Lotto'
  PRIZES = 'Current Prizes'
  PARTY_GOLD = 'Your Money'
  WINNING_TICKET_LABEL = 'Winning Ticket'
  PAST_WINNING_TICKETS_LABEL = 'Past Winning Tickets'
  NAME_FONT_SIZE = 32
  WINNING_LABEL_FONT_SIZE = 24
  WINNING_NUMBER_FONT_SIZE = 32
  PREVIOUS_TICKETS_FONT_SIZE = 24
  PRIZE_LABEL_FONT_SIZE = 24
  PRIZE_FONT_SIZES = [32, 28, 24]
end

module LottoSpriteMod
  attr_accessor :number
end

class KLottoTicket
  def initialize(number=nil)
    @number = number || rand(10).to_s + rand(10).to_s + rand(10).to_s
  end
  attr_reader :number
end

class Game_System
  alias :kyon_lotto_gm_sys_init :initialize
  def initialize
    kyon_lotto_gm_sys_init
    @winner_tickets = []
  end

  def tickets_maintenance
    length = @winner_tickets.size - KLotto::PREVIOUS_TICKETS_MAX
    length.times{ @winner_tickets.shift }
  end
  attr_reader :winner_tickets
end

class Game_Party
  alias :kyon_lotto_gm_party_init :initialize
  def initialize
    kyon_lotto_gm_party_init
    @lotto_tickets = []
    @winner_tickets = []
  end

  def purchase_lotto_tickets(total=1)
    return 0 if total < 1
    gain_item(KLotto::TICKET_ITEM_ID, total)
    total.times{ @lotto_tickets << KLottoTicket.new }
  end

  def discard_lotto_tickets
    gain_item(KLotto::TICKET_ITEM_ID, -@lotto_tickets.size)
    @lotto_tickets.clear
  end
  def has_lotto_ticket?(number) @lotto_tickets.include?(number) end
  attr_reader :lotto_tickets, :winner_tickets
end

class KLottoShop
  include KLotto
  def initialize(hsh={})
    @id = hsh.delete(:id) || 0
    @name = hsh.delete(:name) || GENERIC_NAME
    @cost = hsh.delete(:cost) || TICKET_PRICE
    @prizes = hsh.delete(:prizes) || DEFAULT_GOLD
    @spheres_max = hsh.delete(:total) || SPHERES_MIN
    @raffles_max = @prizes.size
    @raffles = 0
    @spheres = {}
    @indexes = Array.new(@spheres_max, 0)
    @radius_x = 24
    @radius_y = 64
    @d = 2.0 * Math::PI / @spheres_max
    @moving_frames = 15
    @cy = 208
    @x_offset = []
    @sprites = []
    @gold_label = $data_system.words.gold
    @stage = :main
  end

  def main
    @width = $HIDDENCHEST ? Graphics.width : 640
    h = 36
    @bg = Spriteset_Map.new
    @sprites << @shop_label = Sprite.new
    @shop_label.x = 120
    @shop_label.y = 4
    b = Bitmap.new(@width - 240, NAME_FONT_SIZE + 4)
    b.font.size = NAME_FONT_SIZE
    b.draw_text(b.rect, @name, 1)
    @shop_label.bitmap = b
    h = PRIZE_LABEL_FONT_SIZE + 4
    @sprites << @prize_label = Sprite.new
    @prize_label.x = @plx = @width - 208
    @prize_label.y = @ply = 32
    @prize_label.bitmap = b = Bitmap.new(200, h)
    b.font.size = PRIZE_LABEL_FONT_SIZE
    b.draw_text(b.rect, PRIZES, 1)
    make_prize_labels
    sprite = @sprites[-1]
    @sprites << @party_gold_label = Sprite.new
    @party_gold_label.x = sprite.x
    @party_gold_label.y = sprite.y + h + 8
    @party_gold_label.bitmap = b = Bitmap.new(200, h)
    b.font.size = PRIZE_LABEL_FONT_SIZE
    b.draw_text(b.rect, PARTY_GOLD, 1)
    @sprites << @gold_sprite = Sprite.new
    @gold_sprite.x = @party_gold_label.x
    @gold_sprite.y = @party_gold_label.y + h
    @gold_bitmap = Bitmap.new(200, h)
    refresh_party_gold
    @gold_sprite.bitmap = @gold_bitmap
    @sprites << @winner_label = Sprite.new
    @winner_label.x = 4
    @winner_label.y = 32
    @winner_label.bitmap = b = Bitmap.new(208, WINNING_LABEL_FONT_SIZE + 4)
    b.font.size = WINNING_LABEL_FONT_SIZE
    b.draw_text(b.rect, WINNING_TICKET_LABEL, 1)
    @sprites << @winner_ticket = Sprite.new
    @winner_ticket.x = 8
    @winner_ticket.y = 58
    @winner_bitmap = Bitmap.new(200, WINNING_NUMBER_FONT_SIZE + 4)
    @winner_bitmap.font.size = WINNING_NUMBER_FONT_SIZE
    @winner_ticket.bitmap = @winner_bitmap
    make_past_tickets
    refresh_past_tickets_list
    make_spheres
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      break if $scene != self
    end
    Graphics.freeze
    terminate
  end

  def terminate
    @spheres_max.times do |n|
      @spheres[n].each{|s| s.dispose }
    end
    @spheres.clear
    @sprites.each{|s| s.dispose }
    @sprites.clear
    @bg.dispose
    $game_party.discard_lotto_tickets
  end

  def make_prize_labels
    @raffles_max.times do |n|
      h = PRIZE_FONT_SIZES[n]
      @sprites << sprite = Sprite.new
      sprite.x = @plx
      sprite.y = @ply - 4 + h + n * 4 + 24 * n
      sprite.bitmap = bit = Bitmap.new(200, h)
      bit.font.size = h
      bit.draw_text(bit.rect, DEFAULT_GOLD[n].to_s, 1)
    end
  end

  def make_spheres
    spheres = RPG::Cache.picture(FILENAME)
    sh = spheres.height
    @spheres_max.times do |m|
      @spheres[m] = slot = []
      w = SPHERE_WIDTH * m
      @x_offset << offset = m * 36
      10.times do |n|
        sprite = Sprite.new
        sprite.extend(LottoSpriteMod)
        sprite.number = n.to_s
        rand(4) % 2 == 0 ? slot.push(sprite) : slot.unshift(sprite)
        sprite.x = FIRST_SPHERE_X + offset - 8
        sprite.y = @cy
        sprite.z = 1000
        sprite.bitmap = spheres.dup
        sprite.bitmap.draw_text(w, 0, SPHERE_WIDTH, 24, sprite.number, 1)
        sprite.src_rect.set(w, 0, SPHERE_WIDTH, sh)
      end
      @indexes[m] = slot[-1].number.to_i
    end
    spheres.dispose
  end

  def make_past_tickets
    @sprites << @past_tickets_label = Sprite.new
    @past_tickets_label.x = 8
    @past_tickets_label.y = @winner_ticket.y + PREVIOUS_TICKETS_FONT_SIZE + 16
    h = PREVIOUS_TICKETS_FONT_SIZE + 4
    @past_tickets_label.bitmap = b = Bitmap.new(200, h)
    b.draw_text(b.rect, PAST_WINNING_TICKETS_LABEL, 1)
    @sprites << @past_tickets = Sprite.new
    @past_tickets.x = 8
    @past_tickets.y = @past_tickets_label.y + 28
    @past_bitmap = Bitmap.new(200, PREVIOUS_TICKETS_MAX * 24 + 4)
    @past_tickets.bitmap = @past_bitmap
  end

  def refresh_past_tickets_list
    @past_bitmap.clear
    tickets = $game_system.winner_tickets
    max = tickets.size
    w = @past_bitmap.width
    max.times{|n| @past_bitmap.draw_text(0, n * 24, w, 24, tickets[n], 1) }
  end

  def refresh_party_gold
    @gold_bitmap.clear
    @gold_bitmap.font.size = PRIZE_LABEL_FONT_SIZE
    @gold_bitmap.draw_text(@gold_bitmap.rect, $game_party.gold.to_s, 1)
  end

  def update
    if @stage == :main
      update_start
    elsif @stage == :spin
      update_spheres
    elsif @stage == :fall
      update_fall
    elsif @stage == :standby
      update_stand_by
    else
      update_exit
    end
  end

  def update_start
    if Input.trigger?(Input::B)
      update_exit
      return
    elsif Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @raffles += 1
      @digits = ''
      @steps = 60 + rand(40)
      @stage = :spin
    end
  end

  def update_spheres
    d1 = -@d / @moving_frames * 2
    @spheres_max.times do |m|
      col = @spheres[m]
      10.times do |n|
        o = n - @indexes[m]
        d = @d * o + d1 * @steps
        sx = FIRST_SPHERE_X + @x_offset[m] - 20
        sphere = col[n]
        sphere.x = sx - (@radius_x * Math.sin(d)).round
        sphere.y = @cy - 60 + (@radius_y * Math.cos(d)).round
      end
    end
    @steps -= 1
    @stage = :fall if @steps == 0
  end

  def update_fall
    Audio.se_play("Audio/SE/" + SE_STARTUP, 80, 100)
    @spheres_max.times do |m|
      offset = @x_offset[m]
      col = @spheres[m]
      z_pos = []
      10.times do |n|
        z_order = rand(100)
        random = rand(50) % 3
        sprite = col[n]
        sprite.x = FIRST_SPHERE_X + offset - 8
        sprite.y = @cy
        sprite.z = 1000 + (rand(160) % 3 == 0 ? z_order : -z_order)
        z_pos = sprite.z
      end
      sprite = col.sort{|a,b| b.z <=> a.z }[0]
      @digits += sprite.number
    end
    @winner_bitmap.font.size = WINNING_NUMBER_FONT_SIZE
    @winner_bitmap.draw_text(@winner_bitmap.rect, @digits, 1)
    @stage = :standby
  end

  def update_stand_by
    return unless Input.trigger?(Input::B) or Input.trigger?(Input::C)
    $game_system.se_play($data_system.decision_se)
    $game_system.winner_tickets << @digits
    $game_system.tickets_maintenance
    refresh_past_tickets_list
    @winner_bitmap.clear
    if $game_party.has_lotto_ticket?(@digits)
      $game_party.winning_tickets << KLottoTicket.new(@digits)
      $game_party.gain_gold(@prizes[@raffles - 1])
      refresh_party_gold
      if DISCARD_AFTER_ONE_RAFFLE
        $game_party.discard_lotto_tickets
        return @stage = nil
      end
    end
    @stage = @raffles_max > @raffles ? :main : nil
  end

  def update_exit
    $game_system.se_play($data_system.cancel_se)
    $scene = Scene_Map.new
  end
end