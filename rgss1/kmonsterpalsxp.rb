# * KMonsterPals XP
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

class Game_Battler
  alias :kyon_monsterpals_gm_battler_scu :skill_can_use?
  alias :kyon_monsterpals_gm_battler_se :skill_effect
  def skill_can_use?(sid)
    result = kyon_monsterpals_gm_battler_scu(sid)
    return true if result and @revenge_skill == sid
    result
  end

  def skill_effect(user, skill)
    killed = @hp == 0
    result = kyon_monsterpals_gm_battler_se(user, skill)
    if result and self.kind == :enemy and !killed and @hp == 0
      if (ids = KMonster::PALS[@troop_id][@member_index])
        enemy = $game_troop.enemies[ids[0]]
        enemy.revenge_target = $game_party.actors.index(user)
        sid = ids[1].is_a?(Array)? ids[rand(ids.size)] : ids[1]
        enemy.revenge_skill = sid
        cost = $data_skills[sid].sp_cost
        enemy.sp = cost if cost > enemy.sp
      end
    end
    result
  end
end

class Game_Enemy
  attr_writer :revenge_target, :revenge_skill
  alias :kyon_monsterpals_gm_enemy_ma :make_action
  def make_action
    if @revenge_target and @revenge_skill
      if $game_party.actors[@revenge_target].hp == 0 or
         $data_skills[@revenge_skill].sp_cost > @sp
        @revenge_target = @revenge_skill = nil
      else
        a = self.current_action
        a.kind = 1
        a.basic = 0
        a.skill_id = @revenge_skill
        a.target_index = @revenge_target
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