# * KMonsterPals ACE
#   Scripter : Kyonides Arkanthes
#   2019-10-29

# This scriptlet allows monsters to (over)react after their pal's defeat.
# It will allow them to use a hidden skill in an attempt to exact revenge on
# the hero that killed their friend! They will calm down if successful.
# Note: If the revengeful monster has little mana, the script will provide it
#       enough mana to let it use it at least once. (Thank their rage for it!)

module KMonster
  PALS = {} # Do Not Touch This!
  PALS.default = {} # Do Not Touch This!
  # [TroopID] = { MonsterIndex => [MonsterPalIndex, PalSkillID], etc. }
  # NOTE: PalSkillID could also be an Array of Skill IDs, e.g. [1,2,3]
  PALS[1] = { 0 => [1, 1], 1 => [0, 1] }
end

class Game_BattlerBase
  alias :kyon_monsterpals_gm_battlerbase_scm :skill_conditions_met?
  def skill_conditions_met?(skill)
    result = kyon_monsterpals_gm_battlerbase_scm(skill)
    return true if result and @revenge_skill == skill.id
    result
  end
end

class Game_Battler
  alias :kyon_monsterpals_gm_battler_ed :execute_damage
  def execute_damage(user)
    killed = @hp == 0
    kyon_monsterpals_gm_battler_ed(user)
    return if user.kind == :enemy or kind != :enemy or killed or @hp > 0
    ids = KMonster::PALS[$game_troop.troop_id][@index]
    return unless ids
    enemy = $game_troop.members[ids[0]]
    enemy.revenge_target = $game_party.index_id(user.id)
    sid = ids[1].is_a?(Array)? ids[rand(ids.size)] : ids[1]
    enemy.revenge_skill = sid
    cost = $data_skills[sid].mp_cost
    enemy.mp = cost if cost > enemy.mp
  end
end

class Game_Enemy
  attr_writer :revenge_target, :revenge_skill
  alias :kyon_monsterpals_gm_enemy_ma :make_actions
  def make_actions
    if @revenge_target and @revenge_skill
      @actions.clear
      if $game_party.members[@revenge_target].hp == 0 or
         $data_skills[@revenge_skill].sp_cost > @sp
        @revenge_target = @revenge_skill = nil
      else
        @actions << action = Game_Action.new(self)
        action.set_skill(@revenge_skill)
        action.target_index = @revenge_target
        return
      end
    end
    kyon_monsterpals_gm_enemy_ma
  end
  def kind() :enemy end
end

class Game_Actor
  def kind() :actor end
end

class Game_Party
  def index_id(aid) @actors.index(aid) end
end

class Game_Troop
  attr_reader :troop_id
end