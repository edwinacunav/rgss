# * KItemRefill XP
#   Scripter : Kyonides-Arkanthes
#   v 1.1.2 - 2019-01-21

# * Script Calls *
#      KItemRefill.refill(ID)
#   Just refill the flask with whatever you want to.
#      KItemRefill.improve(ID)
#   Increase the number of sips. Hiccup! XD
#      KItemRefill.break(ID)
#   Break the darn flask because you are evil!
#      KItemRefill.broken?(ID)
#   Is the flask broken?
#      KItemRefill.replace(ID)
#   Fix the broken flask.
#      KItemRefill.new_mode(ID, MODO)
#   Heal depending on its mode: nil : Database setup, :hp & :mp are self evident
#   Many calls are optional, you are not forced to improve it or change its mode
#   so use your preferred calls instead.

#   Object Description :   Uses Left:\u
#   The label should appear on the opposite side of the hero selection window.

#   SETTINGS

#   Pick one or more Non Consumable items, add them to the IDS array.
#   ITEM_KIND defines how the item will be used (1 out of 3 options)
#   Without ID nor any value or ID => nil : Based on Database settings
#   :hp => HP, :sp => SP or MP
#   USAGE_LIMITS: set ID => Maximum Number of Uses for each ID.
#   USAGE_INCREASE: set ID => Increase Uses for each ID.
#   MAX_LEVEL: set ID => Maximum Level (0 or higher) for each ID.
#   Don't forget to add as many commas as deemed necessary as a separator for
#   all key value pairs: 36 => 8, 37 => 5
#   REFILL_AFTER_IMPROVEMENT: set if you want the flask to be refilled or not
#   whenever it gets improved.
#   FILL_EMPTY_ITEM: set if the item should be filled at the beginning.

module KItemRefill
  IDS = [33]
  # Kind of Usage : ID => Use (nil, :hp, :sp)
  ITEM_KIND = { 33 => :hp }
  # Initial Maximum Level : ID => Level
  USAGE_LIMITS = { 33 => 8 }
  # Maximum Number of Improvements : ID => Maximum Number of Improvements
  USAGE_INCREASE = { 33 => 3 }
  # Maximum Level (0 or higher) : ID => Maximum Level
  MAX_LEVEL = { 33 => 4 }
  # Refill item after improving it? Yeah : true, No : false
  REFILL_AFTER_IMPROVEMENT = true
  # Refill item after getting it from some NPC? Yeah : true, No : false
  FILL_EMPTY_ITEM = true
  def self.refill(id) $game_system.refill_items[id].refill end
  def self.improve(id) $game_system.refill_items[id].improve end
  def self.break(id) $game_system.refill_items[id].broken = true end
  def self.broken?(id) $game_system.refill_items[id].broken end
  def self.replace(id) $game_system.refill_items[id].broken = nil end
  def self.new_mode(id,mode) $game_system.refill_items[id].change_mode(mode) end
end

module ItemAddOns
  attr_accessor :sips, :broken
  attr_reader :sip_max, :level, :mode
  def level_max() KItemRefill::MAX_LEVEL[@id] end
  def change_mode(new_mode) @mode = new_mode end
  def fill
    @level = 0
    @mode = KItemRefill::ITEM_KIND[@id]
    refill_item
    @sips = KItemRefill::FILL_EMPTY_ITEM ? @sip_max : 0
  end

  def refill
    return @sips if @broken
    refill_item
    @sips = @sip_max
  end

  def improve
    return  @sips if @broken
    @level += 1 if @level < KItemRefill::MAX_LEVEL[@id]
    limit = KItemRefill::USAGE_LIMITS[@id]
    @sip_max = (limit + (@level * KItemRefill::USAGE_INCREASE[@id]))
    @sips = @sip_max if KItemRefill::REFILL_AFTER_IMPROVEMENT
  end
  private
  def refill_item
    limit = KItemRefill::USAGE_LIMITS[@id]
    @sip_max = (limit + (@level * KItemRefill::USAGE_INCREASE[@id]))
  end
end

class Game_System
  attr_reader :refill_items
  alias kyon_item_refill_gm_sys_init initialize
  def initialize
    @refill_items = {}
    KItemRefill::IDS.each do |id|
      @refill_items[id] = $data_items[id].dup
      @refill_items[id].extend(ItemAddOns)
      @refill_items[id].fill
    end
    kyon_item_refill_gm_sys_init
  end
end

class Game_Actor
  alias kitemrefill_gm_actor_item_effect item_effect
  def item_effect(item)
    refill_item = $game_system.refill_items[item.id]
    return false if refill_item and refill_item.sips == 0
    if !refill_item or (refill_item and !refill_item.mode)
      effective = kitemrefill_gm_actor_item_effect(item)
    else
      effective = refill_item_effect(refill_item)
    end
    refill_item.sips -= 1 if effective and refill_item and refill_item.sips > 0
    effective
  end

  def refill_item_effect(item)
    self.critical = false
    if ((item.scope == 3 or item.scope == 4) and self.hp == 0) or
       ((item.scope == 5 or item.scope == 6) and self.hp >= 1)
      return false
    end
    effective = false
    # Set effective flag if common ID is effective
    effective |= item.common_event_id > 0
    hit_result = (rand(100) < item.hit)
    unless hit_result
      self.damage = $game_temp.in_battle ? "Miss" : nil
      return false
    end
    # Set effective flag is skill is uncertain
    effective |= item.hit < 100
    if item.mode == :hp
      return effective = refill_hp_effect(item, effective)
    elsif item.mode == :sp
      return effective = refill_sp_effect(item, effective)
    end
  end

  def refill_hp_effect(item, effective)
    # Calculate amount of recovery
    recover_hp = maxhp * item.recover_hp_rate / 100 + item.recover_hp
    if recover_hp < 0
      recover_hp += self.pdef * item.pdef_f / 20
      recover_hp += self.mdef * item.mdef_f / 20
      recover_hp = [recover_hp, 0].min
    end
    # Element correction
    recover_hp *= elements_correct(item.element_set)
    recover_hp /= 100
    # Dispersion
    if item.variance > 0 and recover_hp.abs > 0
      amp = [recover_hp.abs * item.variance / 100, 1].max
      recover_hp += rand(amp+1) + rand(amp+1) - amp
    end
    # If recovery code is negative, guard correction
    recover_hp /= 2 if recover_hp < 0 and self.guarding?
    # Set damage value and reverse HP recovery amount
    self.damage = -recover_hp
    # HP recovery
    last_hp = self.hp
    self.hp += recover_hp
    effective |= self.hp != last_hp
    # State change
    @state_changed = false
    effective |= states_plus(item.plus_state_set)
    effective |= states_minus(item.minus_state_set)
    # If parameter value increase is effective
    if item.parameter_type > 0 and item.parameter_points != 0
      case item.parameter_type
      when 1  # Max HP
        @maxhp_plus += item.parameter_points
      when 2  # Max SP
        @maxsp_plus += item.parameter_points
      when 3  # Strength
        @str_plus += item.parameter_points
      when 4  # Dexterity
        @dex_plus += item.parameter_points
      when 5  # Agility
        @agi_plus += item.parameter_points
      when 6  # Intelligence
        @int_plus += item.parameter_points
      end
      effective = true
    end
    if item.recover_hp_rate == 0 and item.recover_hp == 0
      # Set damage to empty string
      self.damage = ""
      # If recovery amount is 0, and parameter increase value is ineffective.
      if item.parameter_type == 0 or item.parameter_points == 0
        # If state is unchanged Set damage to "Miss"
        self.damage = "Miss" unless @state_changed
      end
    end
    return effective
  end

  def refill_sp_effect(item, effective)
    # Calculate amount of recovery
    recover_sp = maxsp * item.recover_sp_rate / 100 + item.recover_sp
    recover_sp *= elements_correct(item.element_set)
    recover_sp /= 100
    # Dispersion
    if item.variance > 0 and recover_sp.abs > 0
      amp = [recover_sp.abs * item.variance / 100, 1].max
      recover_sp += rand(amp+1) + rand(amp+1) - amp
    end
    # SP recovery
    last_sp = self.sp
    self.sp += recover_sp
    effective |= self.sp != last_sp
    # State change
    @state_changed = false
    effective |= states_plus(item.plus_state_set)
    effective |= states_minus(item.minus_state_set)
    # If parameter value increase is effective
    if item.parameter_type > 0 and item.parameter_points != 0
      case item.parameter_type
      when 1  # Max HP
        @maxhp_plus += item.parameter_points
      when 2  # Max SP
        @maxsp_plus += item.parameter_points
      when 3  # Strength
        @str_plus += item.parameter_points
      when 4  # Dexterity
        @dex_plus += item.parameter_points
      when 5  # Agility
        @agi_plus += item.parameter_points
      when 6  # Intelligence
        @int_plus += item.parameter_points
      end
      effective = true
    end
    if item.recover_sp_rate == 0 and item.recover_sp == 0
      # Set damage to empty string
      self.damage = ""
      # If SP recovery rate / recovery amount are 0, and parameter increase
      # value is ineffective.
      if item.parameter_type == 0 or item.parameter_points == 0
        # If state is unchanged # Set damage to "Miss"
        self.damage = "Miss" unless @state_changed
      end
    end
    return effective
  end
end

class Window_Help
  def set_text(item_id, text=nil, align=0)
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
  def update_help
    a = @index % 2 == 0 ? 0 : 2
    obj = self.item
    id, desc = self.item ? [obj.id, obj.description] : ["", nil]
    @help_window.set_text(id, desc, a)
  end
end

class Scene_Item
  def update_item
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $scene = Scene_Menu.new(0)
      return
    elsif Input.trigger?(Input::C)
      @item = @item_window.item
      if !@item.is_a?(RPG::Item) or !$game_party.item_can_use?(@item.id)
        return $game_system.se_play($data_system.buzzer_se)
      end
      $game_system.se_play($data_system.decision_se)
      @infinite_potion = KItemRefill::IDS.include?(@item.id)
      if @item.scope >= 3 or @infinite_potion
        if @infinite_potion
          @item = $game_system.refill_items[@item.id]
          if @item.sips == 0
            $game_system.se_play($data_system.buzzer_se)
            @infinite_potion = nil
            return
          end
        end
        @item_window.active = false
        @target_window.x = (@item_window.index + 1) % 2 * 304
        @target_window.visible = true
        @target_window.active = true
        if @item.scope == 4 || @item.scope == 6
          @target_window.index = -1
        else
          @target_window.index = 0
        end
      else
        if @item.common_event_id > 0
          $game_temp.common_event_id = @item.common_event_id
          $game_system.se_play(@item.menu_se)
          if @item.consumable
            $game_party.lose_item(@item.id, 1)
            $game_system.map_interpreter.update
            @item_window.draw_item(@item_window.index)
          end
          $scene = Scene_Map.new
        end
      end
      return
    end
  end

  def update_target
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      @item_window.refresh unless $game_party.item_can_use?(@item.id)
      @infinite_potion = nil
      @item_window.active = true
      @target_window.visible = false
      @target_window.active = false
      return
    elsif Input.trigger?(Input::C)
      if $game_party.item_number(@item.id) == 0
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      if @target_window.index == -1
        used = false
        for i in $game_party.actors
          used |= i.item_effect(@item)
        end
      end
      if @target_window.index >= 0
        if @infinite_potion
          if @item.sips == 0
            $game_system.se_play($data_system.buzzer_se)
            return
          end
        end
        target = $game_party.actors[@target_window.index]
        used = target.item_effect(@item)
        @item_window.update_help if @infinite_potion and used
      end
      if used
        $game_system.se_play(@item.menu_se)
        if @item.consumable
          $game_party.lose_item(@item.id, 1)
          @item_window.draw_item(@item_window.index)
        end
        @target_window.refresh
        if $game_party.all_dead?
          $scene = Scene_Gameover.new
          return
        end
        if @item.common_event_id > 0
          $game_temp.common_event_id = @item.common_event_id
          $scene = Scene_Map.new
          return
        end
      end
      $game_system.se_play($data_system.buzzer_se) unless used
      return
    end
  end
end