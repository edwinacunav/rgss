# * KRumors XP
#   Scripter : Kyonides-Arkanthes
#   v1.1.4 - 2019-03-11

#   Free for Non Commercial Games, You got to pay a fee for including them in
#   Commercial Games.

#   Warning!

#   Rumors the heroes have heard during their travels consists of stories and
#   the heroes' thoughts on them. They are Arrays of Strings (line of texts),
#   one slot (made out of 4 lines) per story page.

# * Module Setup *

#   If @hurt_heroes is true, you will let your reserves to get hurt after each
#   successful or failed mission. Set it to false or nil to avoid this.

# * Script Calls *

#   SceneManager.call(KRumorScene)

# Pick 1 out of 2 options for Adding a New Rumor Location
#   $game_party.add_rumor_place(LocationID)
#   KRumors.add_place(LocationID)

# To make sure whether or not all Rumors are repeatable
#   KRumors.repeatable = true  or  false

# To add a rumor an NPC told you about - script call only
# Boolean - true : get spoils, false : you're a mean game dev!
#   $game_party.add_story(RumorLandID, RumorIndex, Boolean)
#   $game_party.add_rumor(RumorLandID, RumorIndex, Boolean)

# Remove a Reserve aka Reservist (losing it in the process)
#   $game_party.remove_reserve(ActorID)

# Swap active Actors
#   $game_party.swap_actors(TeamPosition1, TeamPosition2)

# Swap an Actor and a Reserve
#   $game_party.swap_actor_reserve(ActorID, ReserveID)

# To prevent a Hero from collecting Rumors
#   $game_party.gossip_haters(ActorID1, etc.)

# To Allow a Hero to collect Rumors
#   $game_party.remove_haters(ActorID1, etc.)

# To Manually Force a Hero to Return from a Gossip Trip
#   $game_party.skip_travel(ActorID)

# Get Actor's Reputation
#   $game_actors[ActorID].reputation
#   $game_party.actors[GroupIndex].reputation

# Get All Actors' Reputation
#   $game_party.reputation

# Check if an Actor is a Reserve / Reservist
#   $game_party.reserve?(ActorID)

# Check if an Actor is a Traveler
#   $game_party.traveler?(ActorID)

# Change the permission to hurt the reserves while traveling
# Where boolean stands for true - hurt them! and false - don't!
#   KRumors.hurt_heroes = boolean

module KRumorSetup
  PARTY_MAX = 4
  MAX_RUMORS_PER_ATTEMPT = 2
  @hurt_heroes = true
  RECOVERY_TIME = 3 # Minutes
  HP_DMG_PERCENT = 10
  BACKDROP = 'bg quest menu'
  RUMOR_BACKDROP = 'scroll horz dark'
  WARNING_BACKDROP = 'scroll horizontal small'
  CANCEL_BACKDROP = 'scroll vertical small'
  STAGE_CURSOR = 'gem ruby mini'
  HERO_CURSOR = 'archery target mini'
  LOCATE_CURSOR = 'gem aquamarine mini'
  RUMOR_CURSOR = 'gem amethyst mini'
  CANCEL_ICON = 'feather icon'
  LIST_TITLE_ICON = 'title label medium'
  UPDATE_WARNING_PIC = 'inactive quest label'
  LIST_BACKDROP = 'vintage scroll'
  FAILED_PICTURE = 'failed medium'
  TITLE_FONT_NAME = 'IncisedBlack'
  TITLE_FONT_SIZE = 36
  GROUP_FONT_NAME = 'M+ 1c'
  RUMOR_INFO_FONT_NAME = 'M+ 1c'
  RUMOR_INFO_FONT_BOLD = true
  CANCEL_FONT_NAME = 'Moria Citadel'
  TITLE = 'Gossip Central'
  WELCOME = 'Please pick a group'
  NO_GROUP = 'There is no hero available!'
  STATUS = 'Status'
  STATUSES = { true  => 'Healthy', false => 'Hurt' }
  STAGES = ['Idle Heroes', 'Travelers', 'Rumors Found', 'Stories']
  BOOKS = 'Books'
  HERO_LVL = 'Level'
  HERO_NEEDS = 'EXP Needed'
  AVAILABLE_RUMORS = 'Available Rumors'
  HEROES_TOTAL = 'Heroes Total'
  RUMORS_TOTAL = 'Rumors Total'
  RIGHT_GUESS = 'Confirmed Rumors'
  FALSE_RUMORS = 'False Rumors'
  HOT_RUMORS = 'New Rumors'
  OLD_RUMORS = 'Reviewed'
  SPOILS_FOUND = 'Spoils Found'
  SPOILS_LIST = 'Available Spoils'
  NO_SPOILS = 'None'
  DESTINATION = 'Destination'
  DESTINATIONS = 'Destinations'
  NO_DESTINATION = 'No Destination was found!'
  NO_RUMORS_LEFT = 'We ran out of rumors!'
  UNKNOWN_DESTINATION = 'Unknown'
  RETURN_ETA = 'Returns in'
  RECOVERY_ETA  = 'Recovers in'
  HERO_IS_IDLE = 'Stand By'
  HERO_THOUGHTS = "%s's thoughts on this rumor:"
  UPDATE_WARNING = 'Updating Lists...'
  RUMORS = 'Rumors'
  SOURCES = 'Sources'
  PAGE_LABEL = 'Page'
  PENDING_QUESTS = 'Some quests are now available!'
  NO_QUEST_FOUND = 'No quest information is available!'
  CANCEL_TEXTS = ['Yes', 'No', 'Cancel Travel Now?', 'You will get no rewards!']
  MAIN_ACTIVE_COLOR = Color.new(255, 80, 0)
  MAIN_OTHER_COLOR = Color.new(0, 0, 0)
  GROUP_FONT_OUTLINE_COLOR = Color.new(255, 255, 255)
  GROUP_FONT_FILL_COLOR = Color.new(255, 80, 0)
  GROUP_DATA_FONT_OUTLINE_COLOR = Color.new(255, 255, 255)
  GROUP_DATA_FONT_FILL_COLOR = Color.new(90, 45, 0)
  INFO_TITLE_OUTLINE_COLOR = Color.new(90, 45, 0)
  INFO_TITLE_FILL_COLOR = Color.new(255, 255, 255)
  INFO_SPOILS_OUTLINE_COLOR = Color.new(255, 255, 255)
  INFO_SPOILS_FILL_COLOR = Color.new(120, 65, 0)
  WARNING_FILL_COLOR = Color.new(0, 0, 0)
  WARNING_OUTLINE_COLOR = Color.new(255, 255, 255)
  CANCEL_FONT_COLOR = Color.new(120, 120, 0)
end

class KRumorLocation
  attr_reader :id, :name, :map_id, :time
  attr_writer :ready
  def initialize(new_id, new_name, map_id, new_time)
    @id = new_id
    @name = new_name
    @map_id = map_id
    @time = (new_time * 60 * Graphics.frame_rate).round
  end
end

class KRumor
  def initialize(loc_id, sources, spoils, ids)
    @place_id = loc_id
    @injury_rate = 0
    @percent = 100
    @spoils_max = 1
    @sources = sources || []
    @spoils = spoils
    @spoils_found = []
    @quest_ids = ids || []
    @story = []
    @book = { :book => nil, :page => nil }
    @title = ''
    @subtitle = ''
    @description = ''
    @confirm = nil
    @read = false
  end
  def confirm!() @confirm = true end
  def book_contents() [@title, @subtitle, @story, @sources] end
  attr_reader :sources, :spoils, :spoils_found, :story, :confirm, :book
  attr_reader :quest_ids, :place_id
  attr_accessor :title, :subtitle, :description, :sources_total, :percent
  attr_accessor :spoils_max, :read, :injury_rate
end

class KRumorPage
  def initialize(new_id, contents)
    @id = new_id
    @title = contents.shift
    @subtitle = contents.shift
    @story = contents.shift
    @sources = contents.shift
    @hero_id = contents.shift
  end
  attr_reader :id, :hero_id, :title, :subtitle, :story, :sources
end

class KRumorBook
  def initialize(new_id)
    @id = new_id
    @title = KRumors.book_titles[new_id]
    @author = ''
    @pages = {}
  end
  def add_page(new_page) @pages[new_page.id] = new_page end
  attr_reader :id, :title, :author, :pages
end

class KFakeItem
  def initialize(kind, id, amount)
    @kind = kind
    @id = id
    @amount = amount
  end
  def ==(other) other.kind == @kind and other.id == @id end
  def amount=(new_amount) @amount = new_amount end
  attr_reader :kind, :id, :amount
end

module KRumors
  class << self
    attr_accessor :heroes, :locations, :index, :cancel_index, :locate_pos
    attr_accessor :book_titles, :rumor, :pages, :scroll_open, :scroll_close
    attr_accessor :y_offset, :not_enough_pages, :refresh, :stop_refresh
    attr_accessor :hurt_heroes, :cancel_cursor, :repeatable
    attr_reader :rumors, :rumor, :all_locations, :all_rumors, :npc_rumors
    attr_reader :rumor_opinions, :group_pos
    def grant_spoils(rumor)
      @rumors = $game_actors[hero_id].rumors
      return if rumor.read
      @rumor = rumor
      @rumor.read = true
      @hero.rumor_total += 1
      $game_party.rumor_total += 1
      $game_party.add_book_page(@rumor.book, @rumor.book_contents + [@hero.id])
      $game_system.add_quests(@rumor.quest_ids) if HAS_KUESTS
      retrieve_spoils if rand(100) < @rumor.percent
    end

    def retrieve_spoils
      spoils = @rumor.spoils
      return if spoils.empty?
      found = @rumor.spoils_found
      @rumor.spoils_max.times do |n|
        item = spoils[rand(spoils.size)]
        if n > 0
          m = found.select{|i| i == item }[0]
          m = found.index(m) || 9999
          m < n ? found[m].amount += item.amount : @rumor.spoils_found << item
        end
        case item.kind
        when :item, :weapon, :armor then $game_party.gain_item(item, item.amount)
        when :gold then $game_party.gain_gold(item.amount)
        when :exp then @hero.exp += item.amount
        when :rep, :reputation then $game_party.reputation += item.amount
        end
      end
      return true
    end

    def group_pos=(pos)
      if @index < 3 and @heroes[pos]
        @hero = $game_actors[@heroes[pos]]
        @rumors = @hero.rumors
      end
      @group_pos = pos
    end

    def clear_rumor_and_hero
      @rumor = nil
      @hero = nil
    end

    def clear_all
      clear_rumor_and_hero
      @cancel_cursor = nil
      @heroes = nil
      @rumors = nil
      @index = nil
      @not_enough_pages = nil
      @y_offset = nil
    end

    def clear_refresh
      @refresh = nil
      @stop_refresh = nil
    end
    def recovery_time() @hurt_heroes ? @minute * RECOVERY_TIME : 0 end
    def add_place(loc_id) @locations[loc_id] = @all_locations[loc_id].dup end
    def hero_id() @heroes[@group_pos] end
    def hero_and_rumor(hero, rumor) @hero, @rumor = hero, rumor end
    def timer(pos) @heroes[pos].timer end
    def no_hero?() @heroes[@group_pos] == nil end
    def travel_or_no_place?() @index == 1 or @locations.empty? end
    def sick_hero?() @index < 2 and @hero.hplow? end
    def no_rumor?() @index == 2 and @rumors.empty? end
    def cannot_send?() travel_or_no_place? or sick_hero? or no_rumor? end
  end
  @minute = Graphics.frame_rate * 60
  @all_locations = load_data('Data/KRumorsLocations.rvdata2')
  @all_rumors = load_data('Data/KRumors.rvdata2') rescue {}
  @npc_rumors = load_data('Data/KRumorsNPC.rvdata2') rescue {}
  @rumor_opinions = load_data('Data/KRumorsOpinions.rvdata2') rescue {}
  @book_titles = load_data('Data/KRumorsBookTitles.rvdata2') rescue {}
  if $HIDDENCHEST
    Scripts[:krumors] = [:kuests]
    HAS_KUESTS = Scripts.include?(:kuests)
  else
    HAS_KUESTS = Object.constants.include?(:Kuests)
  end
end

module Cache
  def self.icon(filename) load_bitmap('Graphics/Icons/', filename) end
end

class Game_Timer
  alias kyon_krumors_gm_timer_up update
  def update
    kyon_krumors_gm_timer_up
    $game_party.rumor_heroes.each {|rid| $game_actors[rid].update_timer }
  end
end

class Game_Actor
  alias kyon_krumors_gm_actor_init initialize
  def initialize(actor_id)
    kyon_krumors_gm_actor_init(actor_id)
    @timer = 0
    @reputation = 0
    @rumor_total = 0
    @rumor_place_id = 0
    @rumors = []
  end

  def add_rumor(rumor)
    @rumors << rumor
    @rumors = @rumors.compact
  end
  def next_exp_lvl_str() $data_classes[@class_id].exp_for_level(@level + 1) end
  def no_new_rumors() @rumors.empty? or @rumors.reject{|r| r.read }.empty? end
  def update_timer() @timer > 0 ? @timer -= 1 : @timer = 0 end
  def hplow?() self.mhp / 4 > @hp end
  attr_accessor :timer, :reputation, :rumors, :rumor_place_id, :rumor_total
end

class Game_Party
  attr_reader :reserves, :travelers, :returners, :rumor_places, :destinations
  attr_reader :all_rumors, :rumor_results, :books
  attr_accessor :rumor_total
  alias kyon_krumors_gm_party_init initialize
  def initialize
    kyon_krumors_gm_party_init
    @all_rumors = KRumors.all_rumors.dup
    @npc_rumors = KRumors.npc_rumors.dup
    @reserves = []
    @travelers = []
    @returners = []
    @non_gossipers = []
    @destinations = {}
    @rumor_results = { :right => 0, :wrong => 0 }
    @rumor_total = 0
    @books = {}
    KRumors.locations = @rumor_places = {}
  end

  def add_rumor(rumor_id, rumor_pos, find_spoils=nil)
    rumor = @npc_rumors[rumor_id][rumor_pos]
    hero = $game_actors[@actors[0]]
    KRumors.hero_and_rumor(hero, rumor)
    rumor.read = true
    hero.rumor_total += 1
    @rumor_total += 1
    add_book_page(rumor.book, rumor.book_contents + [hero.id])
    KRumors.retrieve_spoils if find_spoils
    KRumors.clear_rumor_and_hero
  end
  alias :add_story :add_rumor

  def add_book_page(book, contents)
    return if book.values.empty?
    bid = book[:book]
    @books[bid] ||= KRumorBook.new(bid)
    page = KRumorPage.new(book[:page], contents)
    @books[bid].add_page(page)
    return true
  end

  def send_traveler(hero_id, locate_pos)
    hero = $game_actors[hero_id]
    hero.rumor_place_id = place_id = rumor_place(locate_pos)
    hero.timer = @rumor_places[place_id].time
    hero.hp -= hero.mhp * KRumors::HP_DMG_PERCENT / 100 if KRumors.hurt_heroes
    @destinations[hero_id] = @rumor_places[place_id].name
    @reserves.delete_if{|hid| hid == hero_id }
    @travelers << hero_id
    KRumors.heroes = @reserves
  end

  def interrupt_travel
    traveler = @travelers[KRumors.group_pos]
    @travelers.delete(traveler)
    @reserves << traveler
    KRumors.refresh = true
  end

  def skip_travel(actor_id)
    traveler = @travelers.delete(actor_id)
    return unless traveler
    @reserves << traveler
    true
  end

  def find_group(pos)
    KRumors.heroes = case pos
    when 0 then @reserves
    when 1 then @travelers
    when 2 then @returners
    end
  end

  def update_returners
    return if @travelers.empty?
    heroes = @travelers.select{|tid| $game_actors[tid].timer < 20 }
    return if heroes.empty?
    heroes.each {|h| hero_hears_rumors(h) }
    @travelers -= heroes
    @returners += heroes
    find_group(KRumors.index)
    KRumors.refresh = true
  end

  def returners_become_idle
    heroes = @returners.select{|rid| $game_actors[rid].no_new_rumors }
    return if heroes.empty?
    @returners -= heroes
    @reserves += heroes
    KRumors.refresh = true
  end

  def hero_hears_rumors(hero_id)
    hero = $game_actors[hero_id]
    hero.timer = KRumors.set_recovery_time if hero.hplow?
    rumors = @all_rumors[hero.rumor_place_id]
    return if rumors.empty?
    total = [rand(KRumorSetup::MAX_RUMORS_PER_ATTEMPT).round, 1].max
    if KRumors.repeatable
      total.times { hero.add_rumor(rumors[rand(rumors.size)]) }
    else
      total.times { hero.add_rumor(rumors.delete_at(rand(rumors.size))) }
    end
  end

  def add_actor(aid)
    if @actors.size < KRumors::PARTY_MAX and !@actors.include?(aid)
      @actors << aid
      $game_player.refresh
      return $game_map.need_refresh = true
    end
    return if groups.include?(aid) or @non_gossipers.include?(aid)
    @reserves << aid
  end

  def swap_actor_reserve(actor_id, reserve_id)
    return unless (apos = @actors.index(actor_id))
    return unless (rpos = @reserves.index(reserve_id))
    @actors[apos], @reserves[rpos] = @reserves[rpos], @actors[apos]
    return true
  end
  def swap_actors(m, n) @actors[m], @actors[n] = @actors[n], @actors[m] end
  def reserve?(actor_id) @reserves.include?(actor_id) end
  def traveler?(actor_id) @travelers.include?(actor_id) end
  def add_rumor_place(n) @rumor_places[n] = KRumors.all_locations[n].dup end
  def reputation() @actors.inject(:+){|a| a.reputation } end
  def gossip_haters(*ids) @non_gossipers = (@non_gossipers + ids).uniq end
  def remove_haters(*ids) @non_gossipers -= ids end
  def groups() @reserves + @travelers + @returners end
  def rumor_place(pos) @rumor_places.keys.sort[pos] end
  def no_more_rumors?(pos) @all_rumors[rumor_place(pos)].empty? end
  def rumor_location(locate_id) @rumors.add_place(locate_id) end
  def remove_reserve(actor_id) @reserves.delete(actor_id) end
  def rumor_places_names() @rumor_places.sort.map{|k, place| place.name } end
  def rumor_heroes() @reserves + @travelers end
end

class TitleSprite < Sprite
  def initialize(y, w, h)
    super(Viewport.new(0, y, w, h))
    self.bitmap = Bitmap.new(w, h)
  end

  def refresh(label)
    b = self.bitmap
    bitmap.clear
    bitmap.font.name = KRumorSetup::TITLE_FONT_NAME
    bitmap.font.size = KRumorSetup::TITLE_FONT_SIZE
    bitmap.draw_text(0, 0, bitmap.width, 38, label, 1)
  end
end

class RumorMenuBackdrop < Sprite
  def initialize(new_x, new_y, w, max)
    super(nil)
    self.x = new_x
    self.y = new_y
    h = (max + 1) * 24 + 20
    bit = Cache.picture(KRumorSetup::LIST_BACKDROP)
    self.bitmap = b = Bitmap.new(w, h)
    bitmap.blt(0, 0, bit, Rect.new(0, bit.height - 12, w, 12))
    bitmap.blt(0, 12, bit, Rect.new(0, bit.height - h + 14, w, h + 4))
    bit.dispose
  end
end

class RumorListTitle < Sprite
  def initialize(new_x, new_y, new_z, label)
    super(nil)
    self.x = new_x
    self.y = new_y
    self.z = new_z
    self.bitmap = b = Cache.picture(KRumorSetup::LIST_TITLE_ICON).dup
    bitmap.draw_text(0, 0, bitmap.width, 28, label, 1)
  end
end

class RumorListSprite < Sprite
  def initialize(new_width, view)
    super(view)
    self.x -= 4
    self.y = 12 if Graphics.width == 544
    self.z += 25
    @bit_width = new_width + 10
  end

  def refresh(total)
    bitmap.dispose if bitmap
    h = total * 24 + 16
    h_bottom = h - 12
    bit = Cache.picture(KRumorSetup::LIST_BACKDROP)
    self.bitmap = b = Bitmap.new(@bit_width, h)
    target_back_rect = Rect.new(0, 0, @bit_width, h - 4)
    target_base_rect = Rect.new(0, h_bottom, @bit_width, 12)
    back_rect = Rect.new(0, 0, bit.width, h_bottom)
    base_rect = Rect.new(0, bit.height - 12, bit.width, 12)
    bitmap.stretch_blt(target_back_rect, bit, back_rect, 255)
    bitmap.stretch_blt(target_base_rect, bit, base_rect, 255)
    bit.dispose
  end
end

class RumorItemList < Sprite
  def initialize(view)
    super(view)
    self.y = 12 if Graphics.width == 544
    self.z = 100
    @w = view.rect.width
  end

  def refresh(names)
    names = ['Nothing'] if names.empty?
    total = names.size
    list_w = @w - 14
    bitmap.dispose if bitmap
    self.bitmap = b = Bitmap.new(@w, total * 24)
    total.times {|n| bitmap.draw_text(12, n * 24, list_w, 24, names[n]) }
  end
  def list_y(new_y) self.y += new_y end
end

class RumorInfoSprite < Sprite
  include KRumorSetup
  def initialize(nx, px)
    super(nil)
    w = Graphics.width
    h = Graphics.height
    @bg_width = w - (w == 544 ? 48 : 80)
    @bg_x = nx
    @page_x = px
    self.x = (w - @bg_width) / 2
    self.y = 48
    self.z = 400
    self.bitmap = Bitmap.new(@bg_width, h - 48)
    @black = Color.new(0, 0, 0)
    @white = Color.new(255, 255, 255)
  end

  def refresh(rumor, page_id=nil)
    @rumor = rumor
    b = self.bitmap
    bitmap.clear
    f = bitmap.font
    f.size = 32
    f.bold = true
    f.name = RUMOR_INFO_FONT_NAME
    f.color = INFO_TITLE_FILL_COLOR
    f.out_color = INFO_TITLE_OUTLINE_COLOR
    bitmap.draw_text(0, 0, @bg_width, 32, rumor.title, 1)
    f.bold = Graphics.width > 640
    f.size = 26
    bitmap.draw_text(0, 36, @bg_width, 26, rumor.subtitle, 1)
    f.size = 24
    f.color = INFO_SPOILS_FILL_COLOR
    f.out_color = INFO_SPOILS_OUTLINE_COLOR
    bitmap.draw_text(@bg_x, 168, 128, 26, SOURCES)
    f.color = @white
    f.out_color = @black
    f.size = 22
    show_sources(rumor.sources)
    show_spoils(rumor.spoils_found) if page_id == nil
    show_story(rumor.story)
    bitmap.font.bold = true
    page_id ? show_page_opinions(page_id.to_s) : show_quests_found
  end

  def show_sources(s)
    s.each_with_index {|t,n| bitmap.draw_text(@bg_x, 194 + n * 24, 200, 24, t) }
  end

  def show_spoils(spoils)
    @sx = @bg_x + 204
    bitmap.font.bold = true
    bitmap.draw_text(@sx, 168, 128, 26, SPOILS_FOUND)
    if spoils.empty?
      bitmap.draw_text(@sx, 196, 220, 24, NO_SPOILS)
    else
      spoils.each_with_index do |item, n|
        text = get_item_name(item.kind, item.id) + ' x' + item.amount.to_s
        bitmap.draw_text(@sx, 196 + n * 24, 220, 24, text)
      end
    end
  end

  def show_story(s)
    f = bitmap.font
    f.bold = Graphics.width > 640
    f.size = 23
    w = @bg_width - 56
    s.each_with_index{|tx, n| bitmap.draw_text(@bg_x, 72 + n * 24, w, 24, tx) }
    f.bold = false
  end

  def show_page_opinions(page_id)
    bitmap.draw_text(@page_x, 4, 64, 24, PAGE_LABEL + ' ' + page_id)
    hid = @rumor.hero_id
    opinions = KRumors.rumor_opinions[@rumor.id]
    return bitmap.font.bold = false unless opinions[hid]
    name = sprintf(HERO_THOUGHTS, $game_actors[hid].name)
    bitmap.draw_text(@bg_x, 268, @bg_width, 24, name)
    bitmap.font.bold = Graphics.width > 640
    opinions[hid].each_with_index do |opinion, n|
      bitmap.draw_text(@bg_x, 298 + n * 24, @bg_width, 24, opinion)
    end
  end

  def show_quests_found
    f = bitmap.font
    f.color = INFO_SPOILS_FILL_COLOR
    f.out_color = INFO_SPOILS_OUTLINE_COLOR
    bitmap.draw_text(@bg_x, 268, 380, 24, PENDING_QUESTS)
    f.color = @white
    f.out_color = @black
    lx = @bg_x + 134
    ly = 0
    return unless KRumors::HAS_KUESTS
    @rumor.quest_ids.each do |qid|
      if Kuests[qid]
        bit = Cache.icon(STAR_ICONS[qid - 1])
        bitmap.blt(@bg_x, 300 + ly * 24, bit, bit.rect)
        bitmap.draw_text(lx, 298 + ly * 24, 360, 24, Kuests[qid].name)
        bit.dispose
      else
        bitmap.draw_text(lx, 298 + ly * 24, 360, 24, NO_QUEST_FOUND)
      end
      ly += 1
    end
  end

  def get_item_name(kind, item_id)
    case kind
    when :item then $data_items[item_id].name
    when :weapon then $data_weapons[item_id].name
    when :armor then $data_armors[item_id].name
    end
  end
end

class RumorGroupCursor < Sprite
  def initialize(new_x, height, mode, new_limit, view)
    super(view)
    if mode == :hero
      self.bitmap = Cache.picture(KRumorSetup::HERO_CURSOR)
      @base_y = height - bitmap.height
    else
      self.bitmap = Cache.icon(KRumorSetup::LOCATE_CURSOR)
      @base_y = Graphics.width == 544 ? 12 : 0
    end
    @limit = new_limit
    @index = 0
    @change_y = false
    self.x = new_x
    self.y = @base_y
    self.z += 200
  end

  def reset(new_max)
    @max = new_max
    @index = 0
    self.y = @base_y
    self.visible = true
  end

  def refresh
    if Input.trigger?(Input::UP)
      Sound.play_cursor
      reset_group_index(-1)
      list_go_up if @list and @index >= @max
      @handler.call if @handler and @index >= @limit
      return
    elsif Input.trigger?(Input::DOWN)
      Sound.play_cursor
      reset_group_index(1)
      list_go_down if @list and @limit < @max
      @handler.call if @handler and !@index.between?(1, @limit)
    end
  end

  def reset_group_index(value)
    @index = (@index + value) % @max
    cy = [@index, @limit].min
    self.y = @base_y + @y_offset * cy
    @index_handler.call(@index) rescue nil
  end

  def list_go_up() @list.list_y(24) end
  def list_go_down() @list.list_y(-24) unless @index.between?(1, @max) end

  def max=(new_max)
    @max = new_max
    reset_group_index(0)
  end

  def set(meth1, meth2)
    @handler = meth1
    @index_handler = meth2
  end
  def check_y_offset() @index > @limit ? @index - @limit : 0 end
  attr_writer :limit, :y_offset, :list, :index_handler
  attr_reader :index
end

class HorizonCursor < Sprite
  def initialize(new_x, new_y, max, offset, view)
    super(view)
    @offset_x = offset
    @base_x = new_x + offset
    self.x = @base_x
    self.y = new_y
    self.z = 350
    self.bitmap = Cache.icon(KRumorSetup::CANCEL_ICON)
    @max = max
    @index = 0
  end

  def update_position
    if Input.trigger?(Input::LEFT)
      Sound.play_cursor
      self.index = (@index - 1) % @max
      return
    elsif Input.trigger?(Input::RIGHT)
      Sound.play_cursor
      self.index = (@index + 1) % @max
    end
  end

  def index=(new_pos)
    @handler.call(new_pos)
    self.x = @base_x + new_pos * @offset_x
    @index = new_pos
  end
  attr_writer :handler
  attr_reader :index
end

class TimeDataSprite < Sprite
  include KRumorSetup
  def initialize(pos, travel, view)
    super(view)
    @index = pos
    @label = travel ? RETURN_ETA : RECOVERY_ETA
    self.x = 104
    reset_y
    self.bitmap = Bitmap.new(420, 25)
    f = bitmap.font
    f.size = 25
    f.name = GROUP_FONT_NAME
    @x_offset = bitmap.text_size(@label).width + 18
    @hero = $game_actors[KRumors.heroes[pos]]
    @timer = @hero.timer
    redraw if show_data
  end

  def refresh
    return unless show_data
    @timer = @hero.timer
    redraw if @timer > 19 and @timer % Graphics.frame_rate == 0
  end

  def redraw
    @timer /= 60
    bitmap.clear
    f = bitmap.font
    f.size = 25
    f.name = GROUP_FONT_NAME
    f.out_color = GROUP_FONT_OUTLINE_COLOR
    f.color = GROUP_FONT_FILL_COLOR
    bitmap.draw_text(0, 0, @x_offset, 25, @label)
    f.out_color = GROUP_DATA_FONT_OUTLINE_COLOR
    f.color = GROUP_DATA_FONT_FILL_COLOR
    time = sprintf("%02d:%02d", @timer / 60, @timer % 60)
    bitmap.draw_text(@x_offset, 0, 100, 25, time.to_s)
  end

  def show_data
    self.visible = (KRumors.index == 1 or (KRumors.index == 0 and @hero.hplow?))
  end
  def reset_y() self.y = 104 * (@index - KRumors.y_offset) + 75 end
end

class HeroDataSprite < Sprite
  include KRumorSetup
  FONT_SIZE = Graphics.width == 544 ? 24 : 25
  def initialize(pos, view)
    super(view)
    @index = pos
    self.x = 104
    reset_y
    self.z = 5
    self.bitmap = Bitmap.new(436, 100)
    @hero = $game_actors[KRumors.heroes[pos]]
    refresh
  end

  def set_group_font_colors
    bitmap.font.out_color = GROUP_FONT_OUTLINE_COLOR
    bitmap.font.color = GROUP_FONT_FILL_COLOR
  end

  def set_group_data_font_colors
    bitmap.font.out_color = GROUP_DATA_FONT_OUTLINE_COLOR
    bitmap.font.color = GROUP_DATA_FONT_FILL_COLOR
  end

  def draw_labels
    bitmap.draw_text(136, 0, 52, FONT_SIZE, HERO_LVL)
    bitmap.draw_text(240, 0, 128, FONT_SIZE, HERO_NEEDS)
    bitmap.draw_text(0, 25, 100, FONT_SIZE, STATUS)
    bitmap.draw_text(224, 25, 128, FONT_SIZE, RUMORS_TOTAL)
  end

  def draw_basic_data
    bitmap.draw_text(0, 0, 128, FONT_SIZE, @hero.name)
    bitmap.draw_text(172, 0, 60, FONT_SIZE, @hero.level.to_s, 2)
    bitmap.draw_text(328, 0, 100, FONT_SIZE, @hero.next_exp_lvl_str, 2)
    bitmap.draw_text(368, 25, 60, FONT_SIZE, @hero.rumor_total.to_s, 2)
  end

  def draw_status
    bitmap.draw_text(0, 25, 184, FONT_SIZE, STATUSES[!@hero.hplow?], 2)
  end
  def reset_y() self.y = 104 * (@index - KRumors.y_offset) end
end

class IdleDataSprite < HeroDataSprite
  def refresh
    bitmap.font.name = GROUP_FONT_NAME
    bitmap.font.size = FONT_SIZE
    set_group_font_colors
    draw_labels
    set_group_data_font_colors
    draw_basic_data
    draw_status
  end
end

class TravelDataSprite < HeroDataSprite
  def refresh
    location = $game_party.destinations[@hero.id] || UNKNOWN_DESTINATION
    b = self.bitmap
    bitmap.clear
    bitmap.font.size = FONT_SIZE
    bitmap.font.name = GROUP_FONT_NAME
    set_group_font_colors
    draw_labels
    bitmap.draw_text(0, 50, 128, FONT_SIZE, DESTINATION)
    set_group_data_font_colors
    draw_basic_data
    bitmap.draw_text(136, 50, 280, FONT_SIZE, location)
    draw_status
  end
end

class RumorDataSprite < HeroDataSprite
  def refresh
    bitmap.clear
    rumors = @hero.rumors
    old = rumors.select{|r| r.read }.size
    total = rumors.size - old
    bitmap.font.size = FONT_SIZE
    bitmap.font.name = GROUP_FONT_NAME
    set_group_font_colors
    draw_labels
    bitmap.draw_text(0, 50, 128, FONT_SIZE, HOT_RUMORS)
    bitmap.draw_text(200, 50, 128, FONT_SIZE, OLD_RUMORS)
    set_group_data_font_colors
    draw_basic_data
    bitmap.draw_text(128, 50, 60, FONT_SIZE, total.to_s, 2)
    bitmap.draw_text(328, 50, 60, FONT_SIZE, old.to_s, 2)
    draw_status
  end
end

class RumorsDataSprite < Sprite
  include KRumorSetup
  def initialize(results, view)
    super(view)
    self.x = 8
    self.y = 300
    self.z = 5
    self.bitmap = Bitmap.new(240, 96)
    refresh(results)
  end

  def refresh(results)
    bitmap.clear
    f = bitmap.font
    f.size = 24
    f.name = GROUP_FONT_NAME
    f.color = GROUP_DATA_FONT_FILL_COLOR
    f.out_color = GROUP_FONT_OUTLINE_COLOR
    bitmap.draw_text(0, 0, 240, 24, HEROES_TOTAL)
    bitmap.draw_text(0, 24, 240, 24, RUMORS_TOTAL)
    bitmap.draw_text(0, 48, 240, 24, RIGHT_GUESS)
    bitmap.draw_text(0, 72, 240, 24, FALSE_RUMORS)
    f.color = GROUP_FONT_OUTLINE_COLOR
    f.out_color = MAIN_OTHER_COLOR
    bitmap.draw_text(0, 0, 240, 24, $game_party.groups.size.to_s, 2)
    bitmap.draw_text(0, 24, 240, 24, $game_party.rumor_total.to_s, 2)
    bitmap.draw_text(0, 48, 240, 24, results[:right].to_s, 2)
    bitmap.draw_text(0, 72, 240, 24, results[:wrong].to_s, 2)
  end
end

class RumorSpriteset
  include KRumorSetup
  def initialize
    basic_setup
    make_backdrop_main_menu
    refresh_stage_options
    make_titles_lists
    make_cursors
    make_rumor_backdrops
    make_cancel_sprites
  end

  def basic_setup
    @places = $game_party.rumor_places
    @place_names = $game_party.rumor_places_names
    @places_max = @places.size
    KRumors.index = @index = 0
    @locate_timer = 0
    @faces = []
    @heroes = []
    @timers = []
    @rumor_lists = []
    @rumor_item_lists = []
    @rumor_backdrops = []
    @cancel_buttons = []
    @failures = []
    @sprites = []
    @viewports = []
    @show_story = false
    @width = Graphics.width
    @height = Graphics.height
    @heroes_max = (@height - 60) / 100 - 1
    @list_max = (@height - 66) / 24 - 1
    set_coordinates
    h = (@heroes_max + 1) * 104
    @viewports << @bd_vp = Viewport.new(0, 0, @width, @height)
    @bd_vp.z = 0
    @viewports << @viewport = Viewport.new(@vx, @vy, @width - @vx, h)
    @viewport.z = 10
    @viewports << @list_vp = Viewport.new(@vx + 178, @vy - 4, @width - @vx, h)
    @list_vp.z = 50
    @viewports << @cursor_vp = Viewport.new(@vx + 140, @vy - 4, @width - @vx, h)
    @cursor_vp.z = 100
    @viewports << @warning_vp = Viewport.new(0, 0, @width, @height)
    @warning_vp.z = 300
    half = @width / 2
    @viewports << @left_scroll_vp = Viewport.new(0, 0, half, @height)
    @viewports << @right_scroll_vp = Viewport.new(half, 0, half, @height)
    @left_scroll_vp.z = 350
    @right_scroll_vp.z = 350
    @sprites << @these_heroes = Sprite.new(@viewport)
    @these_heroes.y = @height - 28
    @these_heroes.visible = false
    @these_heroes.bitmap = Bitmap.new(160, 26)
  end

  def set_coordinates
    @bx = 28
    @px = 24
    @x_diff = 10
    if @width == 544
      @vx = 8
      @vy = 52
      @lx = 188
      @ly = 32
      @ch = 84
      @x_diff = 16
      @rumor_offset = 272
    elsif @width == 640
      @vx = 54
      @vy = 60
      @lx = 232
      @ly = 28
      @ch = 100
      @rumor_offset = 260
    else
      @vx = 108
      @vy = 72
      @lx = 288
      @ly = 36
      @ch = 180
      @bx = 44
      @px = 40
      @rumor_offset = 340
    end
  end

  def make_backdrop_main_menu
    @sprites << @backdrop = Sprite.new(@bd_vp)
    @backdrop.bitmap = Cache.title1(BACKDROP + @width.to_s)
    @sprites << @title = TitleSprite.new(4, @width, 40)
    @title.refresh(TITLE)
    label = WELCOME
    if $game_party.groups.empty?
      label = NO_GROUP
    elsif @places.empty?
      label = NO_DESTINATION
    end
    @sprites << @welcome_sprite = Sprite.new
    @welcome_sprite.y = @vy + 8
    @welcome_sprite.bitmap = b = Bitmap.new(@width, 30)
    b.font.name = GROUP_FONT_NAME
    b.font.size = 26
    b.draw_text(0, 0, @width, 28, label, 1)
    bx = (@width - 188) / 2
    @sprites << @menu_sprite = RumorMenuBackdrop.new(bx - 4, 144, 188, 4)
    @sprites << @options_sprite = Sprite.new
    @options_sprite.x = bx + 12
    @options_sprite.y = 156
    @options_sprite.z = 400
    @options_sprite.bitmap = Bitmap.new(160, 116)
    results = $game_party.rumor_results
    @sprites << @rumor_data = RumorsDataSprite.new(results, @bd_vp)
  end

  def refresh_stage_options
    b = @options_sprite.bitmap
    b.clear
    b.font.size = 25
    4.times do |n|
      b.font.out_color = @index == n ? MAIN_ACTIVE_COLOR : MAIN_OTHER_COLOR
      b.draw_text(0, n * 28, 160, 25, STAGES[n])
    end
  end

  def make_titles_lists
    @sprites << @locate_title = RumorListTitle.new(@lx, @ly, 150, DESTINATIONS)
    @locate_title.visible = false
    @sprites << @rumor_title = RumorListTitle.new(@lx, @ly, 150, RUMORS)
    @rumor_title.visible = false
    @sprites << @story_title = RumorListTitle.new(@lx, @ly, 150, BOOKS)
    @story_title.visible = false
    @list_width = @story_title.bitmap.width
    @sprites << @list_sprite = RumorListSprite.new(@list_width, @list_vp)
    @list_sprite.visible = false
    @sprites << @story_list = RumorListSprite.new(@list_width, @list_vp)
    @story_list.visible = false
    @sprites << @item_list = RumorItemList.new(@list_vp)
    @item_list.z += 25
    @item_list.visible = false
    @sprites << @rumor_info = RumorInfoSprite.new(@bx, @px)
    @rumor_info.visible = false
  end

  def make_cursors
    @sprites << @cursor = Sprite.new
    @cursor.x = @options_sprite.x - 28
    @cursor.y = 158
    @cursor.bitmap = Cache.icon(STAGE_CURSOR)
    @group_cursor = RumorGroupCursor.new(@vx, @vy+100, :hero, @heroes_max, nil)
    @group_cursor.y_offset = 104
    @group_cursor.visible = false
    @group_cursor.set(method(:reset_face_data), KRumors.method(:group_pos=))
    @list_cursor = RumorGroupCursor.new(26, 0, nil, @list_max, @cursor_vp)
    @list_cursor.visible = false
    @list_cursor.y_offset = 24
    @list_cursor.list = @item_list
    @list_cursor.index_handler = KRumors.method(:locate_pos=)
    @story_cursor = RumorGroupCursor.new(26, 0, nil, @list_max, @cursor_vp)
    @story_cursor.visible = false
    @story_cursor.y_offset = 24
    @story_cursor.list = @story_list
    @sprites << @group_cursor << @list_cursor << @story_cursor
  end

  def make_rumor_backdrops
    drop = Cache.title1(RUMOR_BACKDROP + @width.to_s)
    half = @width / 2
    2.times do |n|
      view = n == 0 ? @left_scroll_vp : @right_scroll_vp
      @rumor_backdrops << sprite = Sprite.new(view)
      sprite.x = n == 0 ? @rumor_offset : -@rumor_offset
      sprite.z = 300
      sprite.visible = false
      sprite.bitmap = b = Bitmap.new(half, @height)
      b.blt(0, 0, drop, Rect.new(half * n, 0, half, @height))
    end
    drop.dispose
    @rumor_backdrops << sprite = Sprite.new(@warning_vp)
    sprite.visible = false
    sprite.bitmap = bit = Bitmap.new(@width, @height)
    bit.fill_rect(0, 0, @width, @height, Color.new(0, 0, 0, 160))
    @sprites += @rumor_backdrops
    @sprites << @warning_sprite = Sprite.new(@warning_vp)
    @warning_sprite.visible = false
    @warning_sprite.bitmap = b = Cache.picture(WARNING_BACKDROP)
    @warn_width = b.width
    @warning_sprite.x = wx = (@width - @warn_width) / 2
    @warning_sprite.z = 150
    @sprites << @warning_label = Sprite.new(@warning_vp)
    @warning_label.x = wx
    @warning_label.y = 14
    @warning_label.z = 200
    @warning_label.bitmap = Bitmap.new(@warn_width, 30)
  end

  def make_cancel_sprites
    @sprites << @cancel_sprite = Sprite.new(@warning_vp)
    @cancel_sprite.bitmap = bit = Cache.picture(CANCEL_BACKDROP)
    bw = bit.width
    @cancel_sprite.x = cw = (@width - bw) / 2
    @cancel_sprite.y = @ch
    @cancel_sprite.z = 300
    bit.font.size = 36
    bit.draw_text(0, 20, bw, 38, CANCEL_TEXTS[2], 1)
    bit.draw_text(0, 64, bw, 38, CANCEL_TEXTS[3], 1)
    cx = cw + (bw / 2) - 120
    cy = @ch + 136
    @cancel_cursor = HorizonCursor.new(cx - 40, cy - 8, 2, 116, @warning_vp)
    @sprites << KRumors.cancel_cursor = @cancel_cursor
    @cancel_cursor.handler = KRumors.method(:cancel_index=)
    2.times do |n|
      @cancel_buttons << sprite = Sprite.new(@warning_vp)
      sprite.x = cx + n * 120
      sprite.y = cy
      sprite.z = 350
      sprite.bitmap = b = Bitmap.new(120, 38)
      b.font.name = CANCEL_FONT_NAME
      b.font.color = CANCEL_FONT_COLOR
      b.font.size = 34
      b.draw_text(0, 0, 120, 34, CANCEL_TEXTS[n], 1)
    end
    @sprites += @cancel_buttons
    @show_cancel = true
    toggle_travel_cancel
  end

  def collect_heroes_data
    @actors = KRumors.heroes.map{|h| $game_actors[h] }
    @face_names = @actors.map{|a| a.character_name }
    @face_pos = @actors.map{|a| a.character_index }
    @face_max = @face_names.size
    @group_cursor.max = @face_max > 0 ? @face_max : 1
    KRumors.group_pos = @group_cursor.index
    KRumors.y_offset = @group_cursor.check_y_offset
  end

  def refresh_hero_data
    @face_max.times {|n| draw_face(n) }
    @index == 2 ? refresh_rumor_data : refresh_idle_travel_timer
  end

  def draw_face(pos)
    @faces << face = Sprite.new(@viewport)
    face.y = 104 * (pos - KRumors.y_offset)
    face.bitmap = Cache.face(@face_names[pos])
    face_index = @face_pos[pos]
    face.src_rect.set(face_index % 4 * 96, face_index / 4 * 96, 96, 96)
  end

  def refresh_rumor_data
    @all_rumors = @actors.map{|a| a.rumors }
    @face_max.times do |n|
      @heroes << RumorDataSprite.new(n, @viewport)
      unless @failures[n]
        @failures << sprite = Sprite.new(@viewport)
        sprite.x = 104
        sprite.y = 104 * (n - KRumors.y_offset)
        sprite.bitmap = Cache.picture(FAILED_PICTURE)
      end
      rumors = @all_rumors[n]
      void = rumors.empty?
      @failures[n].visible = void
      titles = rumors.map{|r| r.title }
      @rumor_lists << sprite = RumorListSprite.new(@list_width, @list_vp)
      sprite.refresh(titles.size)
      sprite.visible = false
      @rumor_item_lists << sprite = RumorItemList.new(@list_vp)
      sprite.refresh(titles)
      sprite.visible = false
    end
  end

  def refresh_idle_travel_timer
    return refresh_timers unless @heroes.empty?
    sprite_class = IdleDataSprite if @index == 0
    sprite_class = TravelDataSprite if @index == 1
    @face_max.times do |n|
      @heroes << sprite_class.new(n, @viewport)
      @timers << timer = TimeDataSprite.new(n, true, @viewport)
      timer.show_data
    end
  end

  def update_warning_timer
    return if @locate_timer == 0
    @locate_timer -= 1
    bool = @locate_timer > 0
    @warning_sprite.visible = bool
    @warning_label.visible = bool
  end

  def update_main_cursor
    @cursor.update
    if Input.trigger?(Input::UP)
      Sound.play_cursor
      KRumors.index = @index = (@index - 1) % 4
      @cursor.y = 158 + 28 * @index
      refresh_stage_options
      return
    elsif Input.trigger?(Input::DOWN)
      Sound.play_cursor
      KRumors.index = @index = (@index + 1) % 4
      @cursor.y = 158 + 28 * @index
      refresh_stage_options
    end
  end

  def start_group_stage
    toggle_main_menu
    @title.refresh(STAGES[@index])
    if @index < 3
      @group_cursor.reset(@face_max)
      collect_heroes_data
      refresh_hero_data
      @these_heroes.visible = true
      b = @these_heroes.bitmap
      b.clear
      b.draw_text(8, 0, 152, 24, HEROES_TOTAL)
      b.draw_text(8, 0, 152, 24, @face_max.to_s, 2)
      return
    end
    books = $game_party.books
    @ids = books.keys.compact.sort
    @story_max = @ids.size
    @story_cursor.reset(@story_max)
    @story_list.refresh(@story_max)
    book_names = @ids.map{|bid| KRumors.book_titles[bid] }
    @item_list.refresh(book_names)
    toggle_book_list
  end

  def refresh_timers() @face_max.times{|n| @timers[n].refresh } end

  def back_to_main_stage
    @title.refresh(TITLE)
    @rumor_data.refresh($game_party.rumor_results)
    @group_cursor.visible = false
    @these_heroes.visible = false
    dispose_old_hero_data
    toggle_main_menu
  end

  def update_group_cursor
    @group_cursor.update
    @group_cursor.refresh if @face_max > 1
    KRumors.group_pos = @group_cursor.index
    refresh_timers if @index < 2
    return KRumors.clear_refresh if KRumors.stop_refresh
    refresh_group_list if KRumors.refresh
  end

  def refresh_group_list
    KRumors.refresh = nil
    show_warning(:retrieve)
    @face_max = KRumors.heroes.size
    refresh_heroes_list
  end

  def reset_face_data
    y_offset = @group_cursor.check_y_offset
    travel = @index < 2
    @face_max.times do |n|
      @faces[n].y = fy = 104 * (n - y_offset)
      @heroes[n].y = fy
      if travel
        @timers[n].y = fy + 75
        @timers[n].refresh
      else
        @failures[n].y = fy
        @failures[n].visible = @all_rumors[n].size == 0
      end
    end
  end

  def start_location_stage
    KRumors.locate_pos = 0
    @list_sprite.refresh(@place_names.size)
    @item_list.refresh(@place_names)
    @list_cursor.reset(@places_max)
    toggle_location_sprites(true)
  end

  def toggle_location_sprites(boolean)
    @list_cursor.visible = boolean
    @locate_title.visible = boolean
    @list_sprite.visible = boolean
    @item_list.visible = boolean
  end

  def locate_to_group_stage
    toggle_location_sprites(false)
    @face_names.size == @face_max ? reset_face_data : refresh_heroes_list
  end

  def update_list_cursor
    @list_cursor.update
    @list_cursor.refresh if @places_max > 1
  end

  def toggle_travel_cancel
    @show_cancel = !@show_cancel
    @cancel_sprite.visible = @show_cancel
    @cancel_cursor.visible = @show_cancel
    @cancel_buttons.each {|b| b.visible = @show_cancel }
    @cancel_cursor.index = 1
  end

  def start_rumor_list_stage
    pos = @group_cursor.index
    @rumors = KRumors.rumors
    @rumor_max = @rumors.size
    @list_cursor.reset(@rumor_max)
    @rumor_title.visible = true
    @list_cursor.visible = true
    names = @rumors.map{|r| r.title }
    list = @rumor_item_lists[pos]
    list.refresh(names)
    @rumor_list = @rumor_lists[pos]
    @rumor_list.visible = true
    list.visible = true
  end

  def rumors_to_group_stage
    if @rumor_list
      @rumor_list.visible = false
      @rumor_item_lists[KRumors.group_pos].visible = false
    end
    @rumor_title.visible = false
    @list_cursor.visible = false
  end

  def update_rumor_cursor
    @list_cursor.update
    @list_cursor.refresh if @rumor_max > 1
  end

  def update_story_cursor
    @story_cursor.update
    @story_cursor.refresh if @story_max > 1
  end

  def toggle_book_list
    @show_story = !@show_story
    @story_cursor.visible = @show_story
    @story_title.visible = @show_story
    @story_list.visible = @show_story
    @item_list.visible = @show_story
  end

  def open_scroll
    @rumor_backdrops[0].x -= @x_diff
    @rumor_backdrops[1].x += @x_diff
    KRumors.scroll_open = @rumor_backdrops[1].x < 0
  end

  def close_scroll
    @rumor_backdrops[0].x += @x_diff
    @rumor_backdrops[1].x -= @x_diff
    KRumors.scroll_close = @rumor_backdrops[0].x < @rumor_offset
  end

  def show_scroll(bool) @rumor_backdrops.each {|s| s.visible = bool } end
  def toggle_rumor_info() @rumor_info.visible = !@rumor_info.visible end

  def choose_rumor
    KRumors.not_enough_pages = @rumor_max < 2
    @page_index = @list_cursor.index
    rumor_draw_page_hero
    toggle_rumor_info
  end

  def rumor_previous_page
    @page_index = (@page_index - 1) % @rumor_max
    rumor_draw_page_hero
  end

  def rumor_next_page
    @page_index = (@page_index + 1) % @rumor_max
    rumor_draw_page_hero
  end

  def rumor_draw_page_hero
    rumor = @rumors[@page_index]
    KRumors.grant_spoils(rumor)
    @rumor_info.refresh(rumor)
    @heroes[KRumors.group_pos].refresh
  end

  def choose_book
    pos = @story_cursor.index
    books = $game_party.books
    @ids = books.keys.compact.sort
    book_id = @ids[pos]
    @pages = books[book_id].pages
    @page_max = @pages.size
    @page_keys = @pages.keys.sort
    KRumors.not_enough_pages = @page_max < 2
    @page_index = 0
    show_scroll(true)
  end

  def story_previous_page
    @page_index = (@page_index - 1) % @page_max
    show_book_page
  end

  def story_next_page
    @page_index = (@page_index + 1) % @page_max
    show_book_page
  end

  def show_book_page
    page_id = @page_keys[@page_index]
    @rumor_info.refresh(@pages[page_id], page_id)
  end

  def story_to_group
    toggle_rumor_info
    @ids = nil
  end

  def toggle_main_menu
    bool = !@cursor.visible
    @welcome_sprite.visible = bool
    @cursor.visible = bool
    @options_sprite.visible = bool
    @menu_sprite.visible = bool
    @rumor_data.visible = bool
  end

  def clear_rumors_found
    return unless @index == 2
    @heroes.each {|s| s.dispose }
    @heroes.clear
  end

  def refresh_heroes_list
    dispose_old_hero_data
    collect_heroes_data
    refresh_hero_data
  end

  def show_warning(kind)
    label = kind == :locate ? NO_RUMORS_LEFT : UPDATE_WARNING
    b = @warning_label.bitmap
    b.clear
    b.font.color = WARNING_FILL_COLOR
    b.font.out_color = WARNING_OUTLINE_COLOR
    b.font.size = 28
    b.draw_text(0, 0, @warn_width, 28, label, 1)
    @warning_sprite.visible = true
    @warning_label.visible = true
    @locate_timer = Graphics.frame_rate * 15 / 100
  end

  def dispose_old_hero_data
    (@faces + @heroes + @timers + @failures + @rumor_lists).each{|s| s.dispose }
    @faces.clear
    @heroes.clear
    @timers.clear
    @failures.clear
    @rumor_lists.clear
  end

  def dispose
    (@sprites + @viewports).each {|s| s.dispose }
    @actors.clear
    @sprites.clear
    @viewports.clear
    @actors = @sprites = @faces = @cancel_index = nil
  end
end

class KRumorScene
  def main
    @stage = :main
    $game_party.find_group(0)
    @spriteset = RumorSpriteset.new
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      break if @exit
    end
    Graphics.freeze
    @spriteset.dispose
    KRumors.clear_all
  end

  def update
    $game_timer.update
    @spriteset.update_warning_timer
    case @stage
    when :main then update_main
    when :group then update_group
    when :travels then update_travels
    when :cancel_travel then update_travel_cancel
    when :locate then update_location
    when :rumors then update_rumor_list
    when :scroll then update_scroll
    when :review then update_read_rumor
    when :book_list then update_book_list
    when :story then update_story
    end
  end

  def update_main
    $game_party.update_returners
    @spriteset.update_main_cursor
    if Input.trigger?(Input::B)
      Sound.play_cancel
      SceneManager.return
      return @exit = true
    elsif Input.trigger?(Input::C)
      pos = KRumors.index
      if pos < 3
        $game_party.find_group(pos)
        return Sound.play_buzzer if KRumors.heroes.empty?
        Sound.play_ok
        @spriteset.start_group_stage
        @heroes_max = KRumors.heroes.size
        KRumors.stop_refresh = true
        return @stage = pos == 1 ? :travels : :group
      end
      return Sound.play_buzzer if $game_party.books.empty?
      Sound.play_ok
      @spriteset.start_group_stage
      @stage = :book_list
    end
  end

  def to_main_stage
    Sound.play_cancel
    @spriteset.back_to_main_stage
    @stage = :main
  end

  def update_group
    $game_party.update_returners if KRumors.index.between?(1, 2)
    @spriteset.update_group_cursor
    if Input.trigger?(Input::B)
      @spriteset.clear_rumors_found
      $game_party.returners_become_idle if KRumors.index == 2
      return to_main_stage
    elsif Input.trigger?(Input::C)
      return Sound.play_buzzer if KRumors.cannot_send?
      Sound.play_ok
      if KRumors.index == 0
        @spriteset.start_location_stage
        return @stage = :locate
      end
      $game_party.find_group(2)
      @spriteset.start_rumor_list_stage
      @stage = :rumors
    end
  end

  def update_travels
    $game_party.update_returners
    @spriteset.refresh_heroes_list if KRumors.refresh
    @spriteset.update_group_cursor
    return to_main_stage if KRumors.heroes.empty? or Input.trigger?(Input::B)
    return unless Input.trigger?(Input::C)
    @spriteset.toggle_travel_cancel
    @stage = :cancel_travel
  end

  def update_travel_cancel
    $game_party.update_returners
    KRumors.cancel_cursor.update_position
    @spriteset.refresh_timers
    if KRumors.refresh
      KRumors.refresh = nil
      @spriteset.refresh_heroes_list
      return exit_travel_cancel(true)
    elsif Input.trigger?(Input::B)
      return exit_travel_cancel(true)
    elsif Input.trigger?(Input::C)
      Sound.play_cancel
      $game_party.interrupt_travel if KRumors.cancel_index == 0
      exit_travel_cancel(nil)
    end
  end

  def exit_travel_cancel(exit_now)
    exit_now ? Sound.play_cancel : Sound.play_ok
    @spriteset.toggle_travel_cancel
    @stage = :travels
  end

  def update_location
    @spriteset.update_list_cursor
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @spriteset.locate_to_group_stage
      return @stage = :group
    elsif Input.trigger?(Input::C)
      pos = KRumors.locate_pos
      if $game_party.no_more_rumors?(pos)
        Sound.play_buzzer
        return @spriteset.show_warning(:locate)
      end
      Sound.play_ok
      $game_party.send_traveler(KRumors.hero_id, pos)
      if KRumors.heroes.empty?
        @spriteset.toggle_location_sprites(false)
        @spriteset.back_to_main_stage
        return @stage = :main
      end
      @spriteset.refresh_heroes_list
      @spriteset.locate_to_group_stage
      @stage = :group
    end
  end

  def update_rumor_list
    @spriteset.update_rumor_cursor
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @spriteset.rumors_to_group_stage
      return @stage = :group
    elsif Input.trigger?(Input::C)
      Sound.play_ok
      @spriteset.show_scroll(true)
      KRumors.scroll_open = true
      @stage = :scroll
    end
  end

  def update_scroll
    if KRumors.scroll_open
      @spriteset.open_scroll
      unless KRumors.scroll_open
        if KRumors.index == 2
          @spriteset.choose_rumor
          @stage = :review
        else
          @spriteset.toggle_rumor_info
          @spriteset.show_book_page
          @stage = :story
        end
      end
      return
    elsif KRumors.scroll_close
      @spriteset.close_scroll
      return if KRumors.scroll_close
      @spriteset.show_scroll(false)
      @stage = KRumors.index == 2 ? :rumors : :book_list
    end
  end

  def update_read_rumor
    $game_party.update_returners
    if Input.trigger?(Input::LEFT)
      return Sound.play_buzzer if KRumors.not_enough_pages
      Sound.play_cursor
      return @spriteset.rumor_previous_page
    elsif Input.trigger?(Input::RIGHT)
      return Sound.play_buzzer if KRumors.not_enough_pages
      Sound.play_cursor
      return @spriteset.rumor_next_page
    end
    return unless Input.trigger?(Input::B) or Input.trigger?(Input::C)
    Sound.play_cancel
    @spriteset.toggle_rumor_info
    KRumors.scroll_close = true
    @stage = :scroll
  end

  def update_book_list
    @spriteset.update_story_cursor
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @spriteset.toggle_book_list
      return to_main_stage
    elsif Input.trigger?(Input::C)
      Sound.play_ok
      @spriteset.choose_book
      KRumors.scroll_open = true
      @stage = :scroll
    end
  end

  def update_story
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @spriteset.story_to_group
      KRumors.scroll_close = true
      return @stage = :scroll
    elsif Input.trigger?(Input::LEFT)
      return Sound.play_buzzer if KRumors.not_enough_pages
      Sound.play_cursor
      @spriteset.story_previous_page
    elsif Input.trigger?(Input::RIGHT)
      return Sound.play_buzzer if KRumors.not_enough_pages
      Sound.play_cursor
      @spriteset.story_next_page
    end
  end
end

class Scene_Menu
  alias kyon_krumors_scn_menu_up update
  def update
    $game_timer.update
    super
  end
end

class Scene_Load
  alias kyon_krumors_scn_load_on_load on_load_success
  def on_load_success
    KRumors.locations = $game_party.rumor_places
    kyon_krumors_scn_load_on_load
  end
end