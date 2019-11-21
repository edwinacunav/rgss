# * DeceptivelyFriendlyKO XP
#   Scripter : Kyonides-Arkanthes
#   2019-02-26

module KDecKout
  UNHARMED = 'Unharmed'
  KNOCKOUT = 'Knockout'
  # WeaponID => [EnemyID1, etc.]
  IGNORE_TARGET_WEAPONS = {}
  # WeaponID => [EnemyID1, etc.]
  INSTANT_KILL_WEAPONS  = {}
  # [ArmorID1, etc.] - Include Shields and Body Armors Only
  DISTRIBUTE_DMG_ARMORS = []
end

class Game_Actor
  def attack_effect(attacker)
    effective = super(attacker)
    armors = [@armor1_id, @armor3_id]
    if effective and (KDecKout::DISTRIBUTE_DMG_ARMORS & armors).empty?
      heroes = $game_party.actors
      partial = @damage / heroes.size
      heroes.each {|h| h.damage = partial }
    end
    return effective
  end
end

class Game_Enemy
  def attack_effect(attacker)
    wid = attacker.weapon_id
    if (this_weapon = KDecKout::IGNORE_TARGET_WEAPONS[wid])
      if this_weapon.include?(@enemy_id)
        @damage = KDecKout::UNHARMED
        return false
      end
    elsif (this_weapon = KDecKout::INSTANT_KILL_WEAPONS[wid])
      if this_weapon.include?(@enemy_id)
        @damage = KDecKout::KNOCKOUT
        @hp = 0
        return true
      end
    end
    return super(attacker)
  end
end