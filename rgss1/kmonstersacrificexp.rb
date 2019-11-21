# * KMonsterSacrifice XP
#   Scripter : Kyonides Arkanthes
#   2019-11-08 (initial version 11-04)

# This scriptlet allows you to configure monsters that can sacrifice its fellow
# monsters' life or mana points if it casts a special skill. Additionally they
# can steal some of their fellows' strength or intelligence.

# KMonster.mana_knockout = true OR false
#  Magical Beings with no remaining SP will (not) fall in battle automatically
#  if another monster drains all of their remaining SP.

module KMonster
  SACRIFICE_FAILED = "FAILED"
  LIFE_SACRIFICE_ID = 5
  MANA_SACRIFICE_ID = 6
  STR_SACRIFICE_ID = 7
  INT_SACRIFICE_ID = 8
  # Should it get killed if it has no more mana?
  @mana_knockout = true # true OR false
  SACRIFICE = {} # Do Not Touch This!
  # Options: :max or :rest or a percent (1 ~ 99 only)
  SACRIFICE[:life] = {
    1 => :rest, 2 => 10, 3 => :max
  }
  SACRIFICE[:mana] = {
    1 => :rest, 2 => 7, 3 => :max
  }
  # For STR and INT :rest option is the same as :max
  SACRIFICE[:str] = {}
  SACRIFICE[:int] = {}
  def self.mana_knockout() @mana_knockout end
  def self.mana_knockout=(bool) @mana_knockout = bool end
end

class Game_Battler
  attr_writer :str_plus, :int_plus
  alias :kyon_monster_sacrifice_gm_battler_se :skill_effect
  def skill_effect(user, skill)
    result = kyon_monster_sacrifice_gm_battler_se(user, skill)
    if result and user == self and @troop_id and $game_troop.enemies.size == 1
      if KMonster::LIFE_SACRIFICE_ID == skill.id
        return life_sacrifice_calculation
      elsif KMonster::MANA_SACRIFICE_ID == skill.id
        return mana_sacrifice_calculation
      elsif KMonster::STR_SACRIFICE_ID == skill.id
        return str_sacrifice_calculation
      elsif KMonster::INT_SACRIFICE_ID == skill.id
        return int_sacrifice_calculation
      end
    end
    result
  end

  def find_sacrifice_target
    mobs = $game_troop.enemies - [self]
    mob = mobs[rand(mobs.size)]
  end

  def life_sacrifice_calculation
    mob = find_sacrifice_target
    case stype = KMonster::SACRIFICE[:life][mob.id]
    when :max
      self.hp += total = mob.maxhp
      @damage = -total
      mob.damage = total
      mob.hp = 0
    when :rest
      self.hp += total = mob.hp
      @damage = -total
      mob.damage = total
      mob.hp = 0
    when 1..99
      self.hp += total = mob.maxhp * stype / 100
      @damage = -total
      mob.damage = total
      mob.hp -= total
    else
      @damage = KMonster::SACRIFICE_FAILED
      return false
    end
    true
  end

  def mana_sacrifice_calculation
    mob = find_sacrifice_target
    case stype = KMonster::SACRIFICE[:mana][mob.id]
    when :max
      self.sp += total = mob.maxsp
      @damage = -total
      mob.damage = total
      mob.sp = 0
    when :rest
      self.sp += total = mob.sp
      @damage = -total
      mob.damage = total
      mob.sp = 0
    when 1..99
      self.sp += total = mob.maxsp * stype / 100
      @damage = -total
      mob.damage = total
      mob.sp -= total
    end
    mob.hp = 0 if KMonster.mana_knockout and mob.sp == 0
    return true if stype
    @damage = KMonster::SACRIFICE_FAILED
    false
  end

  def str_sacrifice_calculation
    mob = find_sacrifice_target
    case stype = KMonster::SACRIFICE[:str][mob.id]
    when :max. :rest
      @str_plus += total = mob.base_str
      @damage = -total
      mob.damage = total
      mob.str_plus = -total
    when 1..99
      @str_plus += total = (mob.base_str - mob.str_plus) * stype / 100
      @damage = -total
      mob.damage = total
      mob.str_plus -= total
    else
      @damage = KMonster::SACRIFICE_FAILED
      return false
    end
    true
  end

  def int_sacrifice_calculation
    mob = find_sacrifice_target
    case stype = KMonster::SACRIFICE[:int][mob.id]
    when :max. :rest
      @int_plus += total = mob.base_int
      @damage = -total
      mob.damage = total
      mob.int_plus = -total
    when 1..99
      @int_plus += total = (mob.base_int - mob.int_plus) * stype / 100
      @damage = -total
      mob.damage = total
      mob.int_plus -= total
    else
      @damage = KMonster::SACRIFICE_FAILED
      return false
    end
    true
  end
end