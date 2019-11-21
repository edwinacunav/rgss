# * KBrainWash XP
#   Scripter : Kyonides Arkanthes
#   v1.0.1 - 2019-11-17

# This scriptlet allows you to define spells that might take control of their
# caster's opponent. It also adds a new stat, namely will, to all battlers.

# It also features the will force that might help the target resist such an
# psychic attack.

# The spell will fail if the target's willpower is stronger than the caster's.

# NOTE : The player is still able to choose any battle action at will.

module KBrainWash
  FAIL_ANIME_ID = 1 # Animation for Brainwash failure
  SKILL_ID = 81
  STATE_ID = 17
  # Target's Section
  WILL_FORCE_STATE_ID = 18
  WILL_FORCE_POINTS_PERCENT = 20 # Percent of Extra Will Force Points
  WILL_POINTS_VARIANCE_PERCENT = 5
  TEMP_IGNORE_BW_PERCENT = 5
  # Initial Will Points
  START_WILL_POINTS = {} # Do Not Touch This!
  # ActorID or EnemyID => Will Power Points, etc.
  START_WILL_POINTS[:actor] = {}
  START_WILL_POINTS[:enemy] = {}
  START_WILL_POINTS[:actor].default = 0 # Excluded actors get none!
  START_WILL_POINTS[:enemy].default = 0 # Excluded enemies get none!
  def self.ignore?() rand(100) < TEMP_IGNORE_BW_PERCENT end
end

class Game_BattleAction
  alias :kyon_will_force_gm_battle_act_drtfa :decide_random_target_for_actor
  alias :kyon_will_force_gm_battle_act_drtfe :decide_random_target_for_enemy
  def decide_random_target_for_actor
    if @battler.brainwashed?
      target = $game_party.random_target_actor
      return clear unless target
      return @target_index = target.index
    end
    kyon_will_force_gm_battle_act_drtfa
  end

  def decide_random_target_for_enemy
    if @battler.brainwashed?
      target = $game_troop.random_target_enemy
      return clear unless target
      return @target_index = target.index
    end
    kyon_will_force_gm_battle_act_drtfe
  end
end

class Game_Battler
  attr_accessor :will
  alias :kyon_will_force_gm_battler_init :initialize
  alias :kyon_will_force_gm_battler_se :skill_effect
  def initialize
    kyon_will_force_gm_battler_init
    @will = KBrainWash::START_WILL_POINTS[self.kind]
  end

  def skill_effect(user, skill)
    if KBrainWash::SKILL_ID == skill.id
      power = @will
      if @states.include?(KBrainWash::WILL_FORCE_STATE_ID)
        power *= KBrainWash::WILL_FORCE_POINTS_PERCENT
      end
      percent = KBrainWash::WILL_POINTS_VARIANCE_PERCENT
      user_var = rand(user.will * percent / 100)
      self_var = rand(@will * percent / 100)
      user_var.send(:-@) if rand(4) % 2 == 0
      self_var.send(:-@) if rand(4) % 2 == 0
      total = user.will * user.int + user_var - power * @int - self_var
      effective = (total > 0 and user.class != self.class)
      if effective
        states_plus(skill.plus_state_set)
        state = $data_states[KBrainWash::STATE_ID]
        @animation_id = state.animation_id
      else
        @animation_id = KBrainWash::FAIL_ANIME_ID
      end
      return effective
    end
    kyon_will_force_gm_battler_se(user, skill)
  end
  def brainwashed?() @states.include?(KBrainWash::STATE_ID) end
end

class Game_Actor
  def kind() :actor end
end

class Game_Enemy
  def kind() :enemy end
end

class Scene_Battle
  alias :kyon_will_force_sbattle_stb :set_target_battlers
  def set_target_battlers(scope)
    if !@active_battler.brainwashed? or KBrainWash.ignore?
      return kyon_will_force_sbattle_stb(scope)
    end
    if @active_battler.is_a?(Game_Enemy)
      case scope
      when 1  # single enemy
        index = @active_battler.current_action.target_index
        @target_battlers << $game_troop.smooth_target_enemy(index)
      when 2  # all enemies
        for target in $game_troop.enemies
          next unless target.exist?
          @target_battlers << target
        end
      when 3  # single ally
        index = @active_battler.current_action.target_index
        @target_battlers << $game_party.smooth_target_actor(index)
      when 4  # all allies
        for target in $game_party.actors
          next unless target.exist?
          @target_battlers << target
        end
      end
    elsif @active_battler.is_a?(Game_Actor)
      case scope
      when 1  # single enemy
        index = @active_battler.current_action.target_index
        @target_battlers.push($game_party.smooth_target_actor(index))
      when 2  # all enemies
        for target in $game_party.actors
          next unless target.exist?
          @target_battlers << target
        end
      when 3  # single ally
        index = @active_battler.current_action.target_index
        @target_battlers.push($game_troop.smooth_target_enemy(index))
      when 4  # all allies
        for target in $game_troop.enemies
          next unless target.exist?
          @target_battlers << target
        end
      end
    end
  end
end