# * KSkillTypes XP Hit Version
#   Scripter : Kyonides Arkanthes
#   v1.0.2 - 2019-11-27

# This scriptlet allows the player to see the skill menu in a different way.
# He or she will retrieve the usual information AND watch a skill animation
# hitting a hero or monster after they have picked a category and chosen any
# skill available there.

# You are in need of creating extra elements in the System tab.

module KSkillTypes
  BACKDROP = 'magical place' # Placed in Graphics/Titles
  TITLE_STRIPE_BACKDROP = 'strip'
  TEST_BATTLER_ID = 1 # Enemy ID to use as the skill target
  TEST_BATTLER_Y = 216 # Y Coordinate of the Test Battler getting hit
  SKILL_MENU_INDEX = 1 # Position of option that opens Skill Menu minus 1
  FIRST_ID = 17 # First Element ID used as a category tag
  # Icon & Picture Filenames
  ICONS = ['gem citrinus', 'physical', 'gem pale', 'gem dark',
    'gem ruby', 'gem emerald']
  DESCRIPTIONS = [ # 1 for each extra Element
    'Select a category',
    'Strength is the way of the fighter!',
    'Because health does matter!',
    'Patience is just for fools!',
    'Blood is a valuable resouce!',
    'Nature is your friend!'
  ]
  SCOPES = [ # 1 for each Skill Scope
    'Nobody',
    'Single Enemy',
    'All Enemies',
    'One Ally',
    'All Allies',
    'Dead Ally',
    'Dead Allies',
    'User Only'
  ]
  ALLY_SCOPES = [3,4,5,6,7]
  NO_STATE = "Normal"
  LABELS = {} # Ignore this line!
  LABELS[:title] = 'Skill Data'
  LABELS[:no_skill] = 'No data was found!'
  LABELS[:cost] = 'Mana'
  LABELS[:power] = 'Power'
  LABELS[:scope] = 'Scope'
  # End of Configuration #
  class << self
    def label() @elements[@index] end
    def type_id() FIRST_ID + @index end
    def description() DESCRIPTIONS[@index] end
    def get_scope(skill_scope) SCOPES[skill_scope] end
    attr_accessor :index
  end
  @elements = load_data('Data/System.rxdata').elements[FIRST_ID..-1]
  @index = 0
end

unless $HIDDENCHEST

module Graphics
  def self.width() 640 end
  def self.height() 480 end
end

end

class Window_Help
  def initialize
    super(0, 0, Graphics.width, 64)
    self.contents = Bitmap.new(width - 32, height - 32)
  end
end

class Window_Skill
  def initialize(actor)
    if (in_battle = $game_temp.in_battle)
      ny = 64
      nh = 256
    else
      ny = 96
      nh = Graphics.height - ny
    end
    super(0, ny, 220, nh)
    @data = []
    @actor = actor
    skills = @actor.skills
    skills.each{|n| @data << $data_skills[n] }
    @general_data = @data.dup
    refresh
    self.index = 0
    self.back_opacity = in_battle ? 160 : 0
    self.opacity = 0 unless in_battle
  end

  def no_contents!
    return unless self.contents
    self.contents.dispose
    self.contents = nil
  end

  def refresh
    no_contents!
    @data = @general_data
    if KSkillTypes.index > 0
      tid = KSkillTypes.type_id
      @data = @data.select{|s| s.element_set.include?(tid) }
    end
    @item_max = @data.size
    return if @item_max == 0
    self.contents = Bitmap.new(width - 32, row_max * 32)
    @bitmap = self.contents
    @item_max.times{|i| draw_item(i) }
  end

  def draw_item(index)
    skill = @data[index]
    can_use =  @actor.skill_can_use?(skill.id)
    @bitmap.font.color = can_use ? normal_color : disabled_color
    by = index * 32
    rect = Rect.new(4, by, self.width / @column_max - 32, 32)
    @bitmap.fill_rect(rect, Color.new(0, 0, 0, 0))
    bitmap = RPG::Cache.icon(skill.icon_name)
    @bitmap.blt(4, by + 4, bitmap, Rect.new(0, 0, 24, 24), can_use ? 255 : 128)
    @bitmap.draw_text(32, by, 204, 32, skill.name, 0)
  end
  def item_id() @data[@index] ? @data[@index].id : nil end
end

class KSpriteset
  def basic_setup(nx, ny)
    @x = nx
    @y = ny
    @sprites = []
  end

  def dispose
    @sprites.each{|s| s.dispose }
    @sprites.clear
  end
  attr_reader :x, :y
end

class KIconSpriteset < KSpriteset
  def initialize(nx, ny, pictures)
    basic_setup(nx, ny)
    @pictures = []
    @icons = []
    @index = 0
    @max = pictures.size
    @max.times do |n|
      bit = RPG::Cache.picture(pictures[n])
      @pictures << sprite = Sprite.new
      h = bit.height
      w1 = bit.width
      this_x = @x - n * 6 + n * w1
      sprite.visible = false
      sprite.x = this_x
      sprite.y = @y
      sprite.bitmap = bit
      @icons << sprite = Sprite.new
      sprite.x = this_x + w1 / 2 - 12
      sprite.y = @y + h / 2 - 12
      sprite.bitmap = RPG::Cache.icon(pictures[n])
    end
    pic = @pictures[-1]
    @margin_right = pic.x + pic.bitmap.width
    update_cursor
    @sprites = @pictures + @icons
  end

  def update
    if Input.trigger?(Input::LEFT)
      update_icon
      @index = (@index - 1) % @max
      update_cursor
    elsif Input.trigger?(Input::RIGHT)
      update_icon
      @index = (@index + 1) % @max
      update_cursor
    end
  end

  def update_icon
    @pictures[@index].visible = false
    @icons[@index].visible = true
  end

  def update_cursor
    @pictures[@index].visible = true
    @icons[@index].visible = false
  end

  def dispose
    super
    @pictures.clear
    @icons.clear
  end
  attr_reader :index, :margin_right
end

class KLabelSpriteset < KSpriteset
  def initialize(nx, ny, nh, picture=nil)
    basic_setup(nx, ny)
    @offset_x = 0
    @width = Graphics.width - nx
    @height = nh
    @sprites << @backdrop = Sprite.new
    @backdrop.x = nx
    @backdrop.y = ny
    picture = '' unless picture
    @backdrop.bitmap = RPG::Cache.picture(picture)
    @backdrop.src_rect.set(0, 0, @width, @height)
    @sprites << @title = Sprite.new
    @title.x = nx
    @title.y = ny
    @title.bitmap = Bitmap.new(@width, @height)
    @font_size = @height - 8
    @white = Color.new(255, 255, 255)
    @red = Color.new(255, 64, 0)
    @yellow = Color.new(255, 255, 64)
  end

  def character=(new_char)
    @character = new_char
    refresh
  end

  def refresh
    set_label(8, 2, @width / 4, @character.name)
    font = @title.bitmap.font
    @states = @character.states
    text = @states.empty? ? KSkillTypes::NO_STATE : retrieve_state_name
    font.color = @red if @dead
    set_label(120, 2, 120, text)
    font.color = @yellow if (fourth = @character.hp <= @character.maxhp / 4)
    font.color = @white unless @dead or fourth
    hpx = 132 + @title.bitmap.text_size(text).width
    terms = $data_system.words
    set_label(hpx, 2, 32, terms.hp, 2)
    hpx += 36
    set_label(hpx, 2, 64, @character.hp.to_s, 2)
    set_label(hpx + 64, 2, 64, '/' + @character.maxhp.to_s)
    font.color = @white
    set_label(hpx + 132, 2, 32, terms.sp, 2)
    hpx += 168
    set_label(hpx, 2, 64, @character.sp.to_s, 2)
    set_label(hpx + 64, 2, 64, '/' + @character.maxsp.to_s)
  end

  def retrieve_state_name
    return "Knockout" if (@dead = @character.hp == 0)
    ratings = @states.map{|n| $data_states[n].rating }
    pos = ratings.index(ratings.max)
    $data_states[@states[pos]].name
  end

  def set_label(x, y, w, label, align=0)
    @title.bitmap.draw_text(x, y, w, @font_size, label, align)
  end

  def set_title(title, align=1)
    by = @height / 2 - @font_size / 2
    b = @title.bitmap
    b.clear
    b.font.size = @font_size
    b.draw_text(@offset_x, by, @width - @offset_x, @font_size, title, align)
  end
  def clear_text() @title.bitmap.clear end
  alias :set_text :set_title
  attr_reader :width, :height
  attr_writer :skill_window, :font_size, :offset_x
end

class KSkillStats < Sprite
  def initialize(w, h, new_skill)
    @skill_id = new_skill
    super(nil)
    self.bitmap = Bitmap.new(w, h)
    @white = Color.new(255, 255, 255)
    @black = Color.new(0, 0, 0)
    @dy = 38
    refresh
  end

  def skill_id=(new_id)
    @skill_id = new_id
    refresh
  end

  def refresh
    labels = KSkillTypes::LABELS
    bit = self.bitmap
    bit.clear
    bit.font.size = 26
    bit.draw_text(0, 0, bit.width, 26, labels[:title], 1)
    rect = Rect.new(8, 30, bit.width - 16, 4)
    bit.fill_rect(rect, @black)
    rect = Rect.new(9, 31, bit.width - 16, 2)
    bit.fill_rect(rect, @white)
    bit.font.size = 22
    return clear_no_skill unless @skill_id
    skill = $data_skills[@skill_id]
    bit.draw_text(0, @dy, 100, 24, labels[:cost])
    bit.draw_text(100, @dy, 96, 24, skill.sp_cost.to_s, 2)
    bit.draw_text(208, @dy, 100, 24, labels[:power])
    bit.draw_text(308, @dy, 96, 24, skill.power.to_s, 2)
    bit.draw_text(0, @dy + 26, 80, 24, labels[:scope])
    bit.draw_text(84, @dy + 26, 112, 24, KSkillTypes.get_scope(skill.scope), 2)
  end

  def clear_no_skill
    text = KSkillTypes::LABELS[:no_skill]
    bitmap.draw_text(0, @dy, bitmap.width, 24, text, 1)
  end
end

class Scene_Skill
  alias :kyon_scn_skill_up_skill :update_skill
  def main
    KSkillTypes.index = 0
    backdrop = KSkillTypes::TITLE_STRIPE_BACKDROP
    @start = true
    @actors = $game_party.actors
    @actor = @actors[@actor_index]
    @backdrop = Sprite.new
    @backdrop.y = 96
    @backdrop.bitmap = RPG::Cache.title(KSkillTypes::BACKDROP)
    @backdrop.src_rect.set(0, 0, Graphics.width, Graphics.height - 96)
    @name_sprite = KLabelSpriteset.new(0, 0, 40, backdrop)
    @help_sprite = KLabelSpriteset.new(0, 40, 28, backdrop)
    @help_sprite.font_size = 24
    @help_sprite.set_title(KSkillTypes.description, 1)
    @status_window = KLabelSpriteset.new(0, 68, 28, backdrop)
    @status_window.font_size = 24
    @status_window.character = @actor
    @skill_window = Window_Skill.new(@actor)
    @skill_window.active = false
    @skill_window.help_window = @help_sprite
    @skill_window.index = -1
    @help_sprite.skill_window = @skill_window
    @target_window = Window_Target.new
    @target_window.visible = false
    @target_window.active = false
    @icon_menu = KIconSpriteset.new(8, 4, KSkillTypes::ICONS)
    if @icon_menu.margin_right > Graphics.width / 3
      @name_sprite.offset_x = @icon_menu.margin_right + 12
    end
    @name_sprite.set_title(KSkillTypes.label, 0)
    @data_sprite = KSkillStats.new(408, 100, @actor.skills[0])
    @data_sprite.x = 228
    @data_sprite.y = 100
    @target_sprite = RPG::Sprite.new
    @target_sprite.y = KSkillTypes::TEST_BATTLER_Y
    @test_battler = $data_enemies[KSkillTypes::TEST_BATTLER_ID]
    name = @test_battler.battler_name
    @enemy_bitmap = RPG::Cache.battler(name, @test_battler.battler_hue)
    @actor_bitmap = RPG::Cache.battler(@actor.battler_name, @actor.battler_hue)
    @target_sprite.x = 228
    @target_sprite.opacity = 255
    Graphics.transition
    until $scene != self
      Graphics.update
      Input.update
      update
    end
    Graphics.freeze
    @actor_bitmap.dispose
    @enemy_bitmap.dispose
    @target_sprite.dispose
    @data_sprite.dispose
    @icon_menu.dispose
    @name_sprite.dispose
    @help_sprite.dispose
    @status_window.dispose
    @skill_window.dispose
    @target_window.dispose
    @backdrop.dispose
  end

  def set_target(skill_id)
    @data_sprite.skill_id = skill_id
    return unless skill_id
    skill = $data_skills[skill_id]
    ally_scope = KSkillTypes::ALLY_SCOPES.include?(skill.scope)
    if @last_result != ally_scope
      bitmap = ally_scope ? @actor_bitmap : @enemy_bitmap
      @tsx = 228 + (Graphics.width - 228 - bitmap.width) / 2
      @target_sprite.x = @tsx
      @target_sprite.bitmap = bitmap
      @last_result = ally_scope
    end
    anime = $data_animations[skill.animation2_id]
    @target_sprite.animation(anime, true)
  end

  def update
    @skill_window.update
    @target_window.update
    if @start
      return update_section
    elsif @skill_window.active
      return update_skill
    elsif @target_window.active
      update_target
    end
  end

  def update_section
    @icon_menu.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      return $scene = Scene_Menu.new(KSkillTypes::SKILL_MENU_INDEX)
    elsif Input.trigger?(Input::C)
      $game_system.se_play($data_system.decision_se)
      @skill_window.index = 0
      @skill_window.active = true
      set_target(@skill_window.item_id)
      return @start = nil
    elsif Input.trigger?(Input::UP)
      refresh_data
      return
    elsif Input.trigger?(Input::DOWN)
      refresh_data
      return
    elsif Input.trigger?(Input::L)
      $game_system.se_play($data_system.cursor_se)
      pos = (@actor_index - 1) % @actors.size
      $scene = Scene_Skill.new(pos)
      return
    elsif Input.trigger?(Input::R)
      $game_system.se_play($data_system.cursor_se)
      pos = (@actor_index + 1) % @actors.size
      $scene = Scene_Skill.new(pos)
    end
  end

  def refresh_data
    $game_system.se_play($data_system.cursor_se)
    KSkillTypes.index = @icon_menu.index
    @name_sprite.set_title(KSkillTypes.label, 0)
    @help_sprite.set_title(KSkillTypes.description)
    @skill_window.refresh
  end

  def update_skill
    @target_sprite.update
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @skill_window.index = -1
      @skill_window.active = false
      @help_sprite.set_title(KSkillTypes.description)
      return @start = true
    elsif Input.dir4 > 0
      set_target(@skill_window.item_id)
    end
    kyon_scn_skill_up_skill
  end
end