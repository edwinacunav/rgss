# * KMonsterSacrifice VX
#   Scripter : Kyonides Arkanthes
#   2019-11-04

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
  ATK_SACRIFICE_ID = 7
  SPI_SACRIFICE_ID = 8
  # Should it get killed if it has no more mana?
  @mana_knockout = true # true OR false
  # Options: :max or :rest or a percent (1 ~ 99 only)
  LIFE_SACRIFICE = {
    1 => :rest, 2 => 10, 3 => :max
  }
  MANA_SACRIFICE = {
    1 => :rest, 2 => 7, 3 => :max
  }
  # For ATK and SPI :rest option is the same as :max
  ATK_SACRIFICE = {}
  SPI_SACRIFICE = {}
  def self.mana_knockout() @mana_knockout end
  def self.mana_knockout=(bool) @mana_knockout = bool end
end

class Game_Battler
  attr_writer :hp_damage, :mp_damage
  attr_accessor :atk_plus, :spi_plus
  alias :kyon_monster_sacrifice_gm_battler_se :skill_effect
  def skill_effect(user, skill)
    killed = @hp == 0
    result = kyon_monster_sacrifice_gm_battler_se(user, skill)
    if result
      if KMonster::LIFE_SACRIFICE_ID == skill.id
        return life_sacrifice_calculation
      elsif KMonster::MANA_SACRIFICE_ID == skill.id
        return mana_sacrifice_calculation
      elsif KMonster::ATK_SACRIFICE_ID == skill.id
        return atk_sacrifice_calculation
      elsif KMonster::SPI_SACRIFICE_ID == skill.id
        return spi_sacrifice_calculation
      end
    end
    result
  end

  def life_sacrifice_calculation
    mobs = $game_troop.members - [self]
    if mobs.size > 0
      mob = mobs[rand(mobs.size)]
      stype = KMonster::LIFE_SACRIFICE[mob.id]
      case stype
      when :max
        self.hp += total = mob.maxhp
        @hp_damage = -total
        mob.hp_damage = total
        mob.hp = 0
      when :rest
        self.hp += total = mob.hp
        @hp_damage = -total
        mob.hp_damage = total
        mob.hp = 0
      when 1..99
        self.hp += total = mob.maxhp * stype / 100
        @hp_damage = -total
        mob.hp -= total
      end
      return true if stype
    end
    @hp_damage = KMonster::SACRIFICE_FAILED
    false
  end

  def mana_sacrifice_calculation
    mobs = $game_troop.members - [self]
    if mobs.size > 0
      mob = mobs[rand(mobs.size)]
      stype = KMonster::MANA_SACRIFICE[mob.id]
      case stype
      when :max
        self.mp += total = mob.maxmp
        @mp_damage = -total
        mob.mp_damage = total
        mob.mp = 0
      when :rest
        self.mp += total = mob.mp
        @mp_damage = -total
        mob.mp_damage = total
        mob.mp = 0
      when 1..99
        self.mp += total = mob.maxmp * stype / 100
        @mp_damage = -total
        mob.damage = total
        mob.mp -= total
      end
      mob.hp = 0 if KMonster.mana_knockout and mob.mp == 0
      return true if stype
    end
    @mp_damage = KMonster::SACRIFICE_FAILED
    false
  end

  def atk_sacrifice_calculation
    mobs = $game_troop.members - [self]
    if mobs.size > 0
      mob = mobs[rand(mobs.size)]
      stype = KMonster::ATK_SACRIFICE[mob.id]
      case stype
      when :max. :rest
        @atk_plus += total = mob.base_atk
        @damage = -total
        mob.damage = total
        mob.atk_plus = -total
      when 1..99
        @atk_plus += total = (mob.base_atk - mob.atk_plus) * stype / 100
        @damage = -total
        mob.damage = total
        mob.atk_plus -= total
      end
      return true if stype
    end
    @hp_damage = KMonster::SACRIFICE_FAILED
    false
  end

  def spi_sacrifice_calculation
    mobs = $game_troop.members - [self]
    if mobs.size > 0
      mob = mobs[rand(mobs.size)]
      stype = KMonster::SPI_SACRIFICE[mob.id]
      case stype
      when :max. :rest
        @spi_plus += total = mob.base_spi
        @damage = -total
        mob.damage = total
        mob.spi_plus = -total
      when 1..99
        @spi_plus += total = (mob.base_spi - mob.spi_plus) * stype / 100
        @damage = -total
        mob.damage = total
        mob.spi_plus -= total
      end
      return true if stype
    end
    @mp_damage = KMonster::SACRIFICE_FAILED
    false
  end
end