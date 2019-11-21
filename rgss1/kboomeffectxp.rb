# * KBoomEffect XP
#   Scripter : Kyonides Arkanthes
#   2019-11-08 - with actual explosions!

# This scriptlet lets you make your monster explode when they get hit by some
# physical or magical attack.

module KBoom
  FAILURE = "Unharmed"
  ANIME_ID = 99
  # MonsterID => [SuccessRate, AllHeroes?, Variance %], etc.
  PHYSICAL_ATK = { 1 => [99, true, 5] }
  # MonsterID => [SuccessRate, AllHeroes?, SkillID1, etc.], etc.
  MAGICAL_ATK = { 1 => [40, true, 60] }
end

class Game_Battler
  alias :kyon_boom_effect_gm_battler_ae :attack_effect
  alias :kyon_boom_effect_gm_battler_se :skill_effect
  def attack_effect(user)
    rate, all, variance = KBoom::PHYSICAL_ATK[self.id]
    return setup_ignition(user, rate, all, variance, nil) if @troop_id and rate
    kyon_boom_effect_gm_battler_ae(user)
  end

  def skill_effect(user, skill)
    rate, all, *skills = KBoom::MAGICAL_ATK[self.id]
    if @troop_id and rate and skills.include?(skill.id)
      return setup_ignition(user, rate, all, skill.variance, skill)
    end
    kyon_boom_effect_gm_battler_se(user, skill)
  end

  def setup_ignition(user, rate, multiple, variance, skill)
    @will_explode = rand(100) < rate
    if @will_explode
      power = skill ? skill.power : self.atk
      targets = multiple ? $game_party.survivors : [user]
      targets.each{|h| ignition_target(h, power, variance) }
    end
    @damage = @hp
    @hp = 0
    @will_explode
  end

  def ignition_target(user, power, variance)
    power = power * @hp / user.pdef
    return user.damage = KBoom::FAILURE if power < 1
    amp = [power.abs * variance / 100, 1].max
    power += rand(amp+1) + rand(amp+1) - amp
    user.damage = power
    user.hp -= power
    user.explosion_pop = true
  end
  def clear_explosion() @will_explode = @explode = nil end
  attr_accessor :will_explode, :explode, :explosion_pop
end

class Game_Party
  def survivors() @actors.select{|a| a.hp > 0 } end
end

class Sprite_Battler
  alias :kyon_boom_effect_sbt_up :update
  def update
    kyon_boom_effect_sbt_up
    return unless @battler and @battler.explode
    animation($data_animations[KBoom::ANIME_ID], true)
    @battler.clear_explosion
  end
end

class Scene_Battle
  alias :kyon_boom_effect_up_ph4_s4 :update_phase4_step4
  alias :kyon_boom_effect_up_ph4_s5 :update_phase4_step5
  def update_phase4_step4
    kyon_boom_effect_up_ph4_s4
    @target_battlers.each{|target| target.explode = target.will_explode }
  end

  def update_phase4_step5
    kyon_boom_effect_up_ph4_s5
    for target in $game_party.actors
      target.damage_pop = target.explosion_pop
      target.explosion_pop = nil
    end
  end
end