# * KMonstersTerrain XP Mango Version
#   Scripter : Kyonides Arkanthes
#   v1.3.0 - 2019-09-29

#   Terrains may let your monsters get stats boosts or debuffs!
#   Since version 1.2.0 you can also swap monster's stats!
#   Since version 1.3.0 monsters might get custom boost and debuff levels by
#   setting their respective stats multiplier! Heroes might also notice that
#   some of their skills might get disabled from the very beginning (via the
#   global script call) or right after the monster used a skill to changed the
#   current terrain! (Disabled skills get cleared if a bad terrain is chosen or
#   the battle ends. A neutral terrain will not clear that list.)
#   You can also replace and return Heroes' skills!

# * Stats Swap Script Calls *

#   $game_troop.enemies[Index].hp_sp_swap = Boolean
# OR
#   KMonsTerrain.hp_sp_swap(Index, Boolean)

#   $game_troop.enemies[Index].str_int_swap = Boolean
# OR
#   KMonsTerrain.str_int_swap(Index, Boolean)

#   $game_troop.enemies[Index].agi_dex_swap = Boolean
# OR
#   KMonsTerrain.agi_dex_swap(Index, Boolean)

#   $game_troop.enemies[Index].pd_md_swap = Boolean
# OR
#   KMonsTerrain.pd_md_swap(Index, Boolean)

#   $game_troop.enemies[Index].swap_stats = Boolean
# OR
#   KMonsTerrain.swap_stats(Index, Boolean)

#   Index should be an Integer equal or greater than 0!
#   Boolean should be either true or false!
#   true - enables swap, false - disables it

# * Other Script Calls *

#   $game_troop.enemies[Index].boost_level = Integer
#   $game_troop.enemies[Index].debuff_level = Integer
#   Integer stands for any positive number greater than or equal to 1.

#   You can globally increase the Monster's Boost Stats and Gold Earned in
#   custom battles by calling:
#   KMonsTerrain.multiplier = 0 (or greater)

#   Explanation: Let's say the evil wizard cursed the land so every monster
#   gets a formidable increase in stats. 0 should be the new boost level after
#   the player has defeated him, meaning they managed to cleanse the land!

#   In custom battles you can setup a series of Skill IDs that will get
#   disabled or temporarily replaced right before those battle events start.
#   Minimum: 1 Skill ID

#   actor = $game_party.actors[Actor_Position] - Usually 0 through 3
#   actor.disable_skills(Skill_ID1, etc.)
#   actor.replace_skills(Skill_ID1, etc.)
#   actor.return_skills # Before battle ends only!
#   Replaced skills will be restored once the battle has ended!
#   You could also force the monsters use those skills during battle.

module KMonsTerrain
  TRANSFORM_SKILL_ID = 81 # Skill that will trigger the terrain transformation
  DISABLE_SKILL_ID = 82
  REPLACE_SKILL_ID = 83
  HPSP_STATS_MAX = 99999
  @multiplier = 0 # Any Integer greater than or equal to 0
  class Boost
    def initialize
      @hp = 0
      @sp = 0
      @str = 0
      @dex = 0
      @agi = 0
      @int = 0
      @atk = 0
      @pdef = 0
      @mdef = 0
      @eva = 0
      @gold = 0
      @actions = []
    end
    attr_accessor :hp, :sp, :str, :dex, :agi, :int, :atk, :pdef, :mdef, :eva
    attr_accessor :gold, :actions
  end
  # Do Not Edit The Following Array!
  SKILL_IDS = [TRANSFORM_SKILL_ID, DISABLE_SKILL_ID, REPLACE_SKILL_ID]
  class << self
    def change_terrain(enemy)
      @terrain = enemy.choose_terrain
      actors = $game_party.actors
      if enemy.good_terrain?
        actors.each{|a| a.disable_skills(@disable_skills[a.id][@terrain]) }
      elsif enemy.bad_terrain?
        actors.each{|a| a.clear_disable_skills }
      end
      backdrop = @terrains[@terrain][0]
      return if backdrop != ''
      $game_temp.battleback_name = backdrop
      return true
    end

    def load_data
      File.open('Data/KMonsTerrain.rxdata','rb') do |f|
        @terrains         = Marshal.load(f)
        @good_terrains    = Marshal.load(f)
        @bad_terrains     = Marshal.load(f)
        @boosts           = Marshal.load(f)
        @debuff           = Marshal.load(f)
        @multipliers      = Marshal.load(f)
        @disable_skills   = Marshal.load(f)
        @replace_skills   = Marshal.load(f)
      end
      @terrain = 0
      @terrains.default = ['']
      @good_terrains.default = []
      @bad_terrains.default = []
      @boosts.default = [0] * 10
      @debuff.default = [0] * 10
      @multipliers.default = 1
      @disable_skills.default = {}
      @good_terrains.each{|n| @disable_skills.default[n] = [] }
      @replace_skills.default = []
    end
    def hp_sp_swap(n, bool) $game_troop.enemies[n].hp_sp_swap = bool end
    def str_int_swap(n, bool) $game_troop.enemies[n].str_int_swap = bool end
    def agi_dex_swap(n, bool) $game_troop.enemies[n].agi_dex_swap = bool end
    def pd_md_swap(n, bool) $game_troop.enemies[n].pd_md_swap = bool end
    def swap_stats(n, bool) $game_troop.enemies[n].swap_stats = bool end
    def transform?(sid) sid == TRANSFORM_SKILL_ID end
    def disable_skills?(sid) sid == DISABLE_SKILL_ID end
    def replace_skills?(sid) sid == REPLACE_SKILL_ID end
    def include_skill?(sid) SKILL_IDS.include?(sid) end
    attr_accessor :terrain, :multiplier
    attr_reader :terrains, :good_terrains, :bad_terrains, :boosts, :debuff
    attr_reader :multipliers, :disable_skills, :replace_skills
  end
  load_data
end

class Game_Battler
  alias :kyon_kmt_gbse :skill_effect
  def skill_effect(user, skill)
    return kyon_kmt_gbse(user, skill) if !KMonsTerrain.include_skill?(skill.id)
    hit = skill.hit
    hit = hit * skill.atk_f / 100 + hit * user.int / 100
    return unless rand(100) < hit
    if KMonsTerrain.transform?(skill.id) and user.is_a?(Game_Enemy)
      return KMonsTerrain.change_terrain(user)
    end
    return if self.is_a?(Game_Enemy)
    if KMonsTerrain.disable_skills?(skill.id)
      disable_skills(KMonsTerrain.disable_skills[@actor_id])
    elsif KMonsTerrain.replace_skills?(skill.id)
      replace_skills(KMonsTerrain.replace_skills[@enemy_id])
    end
    return
  end
end

class Game_Enemy
  alias :kyon_kmt_init :initialize
  alias :kyon_kmt_hp :maxhp
  alias :kyon_kmt_sp :maxsp
  alias :kyon_kmt_str :str
  alias :kyon_kmt_dex :dex
  alias :kyon_kmt_agi :agi
  alias :kyon_kmt_int :int
  alias :kyon_kmt_atk :atk
  alias :kyon_kmt_pdef :pdef
  alias :kyon_kmt_mdef :mdef
  alias :kyon_kmt_eva :eva
  attr_accessor :hp_sp_swap, :str_int_swap, :pd_md_swap
  attr_accessor :boost_level, :debuff_level
  def initialize(troop_id, member_index)
    eid = $data_troops[troop_id].members[member_index].enemy_id
    @boost = KMonsTerrain.boosts[eid]
    @debuff = KMonsTerrain.debuff[eid]
    @terrains = KMonsTerrain.good_terrains[eid]
    @bad_terrains = KMonsTerrain.bad_terrains[eid]
    @boost_level = KMonsTerrain.multipliers[eid]
    @debuff_level = KMonsTerrain.multipliers[eid]
    kyon_kmt_init(troop_id, member_index)
  end

  def swap_stats=(bool)
    @hp_sp_swap = bool
    @str_int_swap = bool
    @agi_dex_swap = bool
    @pd_md_swap = bool
  end

  def mhp
    base = good_terrain? ? @boost.hp * @boost_level : 0
    base += @debuff.hp * @debuff_level if bad_terrain?
    base += @boost.hp * KMonsTerrain.multiplier
    base += kyon_kmt_hp
  end

  def msp
    base = good_terrain? ? @boost.sp * @boost_level : 0
    base += @debuff.sp * @debuff_level if bad_terrain?
    base += @boost.sp * KMonsTerrain.multiplier
    base += kyon_kmt_sp
  end

  def estr
    base = good_terrain? ? @boost.str * @boost_level : 0
    base += @debuff.str * @debuff_level if bad_terrain?
    base += @boost.str * KMonsTerrain.multiplier
    base += kyon_kmt_str
  end

  def eint
    base = good_terrain? ? @boost.int * @boost_level : 0
    base += @debuff.int * @debuff_level if bad_terrain?
    base += @boost.int * KMonsTerrain.multiplier
    base += kyon_kmt_int
  end

  def pd
    base = good_terrain? ? @boost.pdef * @boost_level : 0
    base += @debuff.pdef * @debuff_level if bad_terrain?
    base += @boost.pdef * KMonsTerrain.multiplier
    base += kyon_kmt_pdef
  end

  def md
    base = good_terrain? ? @boost.mdef * @boost_level : 0
    base += @debuff.mdef * @debuff_level if bad_terrain?
    base += @boost.mdef * KMonsTerrain.multiplier
    base += kyon_kmt_mdef
  end

  def dx
    base = good_terrain? ? @boost.dex * @boost_level : 0
    base += @debuff.dex * @debuff_level if bad_terrain?
    base += @boost.dex * KMonsTerrain.multiplier
    base += kyon_kmt_dex
  end

  def ag
    base = good_terrain? ? @boost.agi * @boost_level : 0
    base += @debuff.agi * @debuff_level if bad_terrain?
    base += @boost.agi * KMonsTerrain.multiplier
    base += kyon_kmt_agi
  end

  def mhp=(new_hp)
    hsp = KMonsTerrain::HPSP_STATS_MAX
    @maxhp_plus += new_hp - self.maxhp
    @maxhp_plus = [[@maxhp_plus, -hsp].max, hsp].min
    @hp = [@hp, self.maxhp].min
  end

  def msp=(new_sp)
    hsp = KMonsTerrain::HPSP_STATS_MAX
    @maxsp_plus += new_sp - self.maxsp
    @maxsp_plus = [[@maxsp_plus, -hsp].max, hsp].min
    @sp = [@sp, self.maxsp].min
  end
  def maxhp() @hp_sp_swap ? msp : mhp end
  def maxsp() @hp_sp_swap ? mhp : msp end
  def str() @str_int_swap ? eint : estr end
  def int() @str_int_swap ? estr : eint end
  def agi() @agi_dex_swap ? dx : ag end
  def dex() @agi_dex_swap ? ag : dx end
  def pdef() @pd_md_swap ? md : pd end
  def mdef() @pd_md_swap ? pd : md end
  def maxhp=(hpm) @hp_sp_swap ? msp = spm : mhp = spm end
  def maxsp=(spm) @hp_sp_swap ? mhp = hpm : msp = hpm end

  def atk
    base = good_terrain? ? @boost.atk * @boost_level : 0
    base += @debuff.atk * @debuff_level if bad_terrain?
    base += @boost.atk * KMonsTerrain.multiplier
    base += kyon_kmt_atk
  end

  def eva
    base = good_terrain? ? @boost.eva * @boost_level : 0
    base += @debuff.eva * @debuff_level if bad_terrain?
    base += @boost.eva * KMonsTerrain.multiplier
    base += kyon_kmt_eva
  end

  def actions
    ba = good_terrain? ? @boost.actions : []
    $data_enemies[@enemy_id].actions + ba
  end

  def gold
    money = $data_enemies[@enemy_id].gold
    money += @boost.gold * @boost_level if good_terrain?
    money += @debuff.gold * @debuff_level if bad_terrain?
    money += @boost.gold * KMonsTerrain.multiplier
    money = 0 if money < 0
    money
  end

  def choose_terrain
    lands = @terrains + @bad_terrains
    lands[rand(lands.size)]
  end
  def good_terrain?() @terrains.include?(KMonsTerrain.terrain) end
  def bad_terrain?() @bad_terrains.include?(KMonsTerrain.terrain) end
end

class Game_Actor
  alias kyon_kmt_gm_actor_setup setup
  alias kyon_kmt_gm_actor_scu skill_can_use?
  def setup(actor_id)
    kyon_kmt_gm_actor_setup(actor_id)
    @disable_skills = []
    @replaced_skills = []
  end

  def replace_skills(*sids)
    @replaced_skills = @skills.dup
    @skills = sids.flatten
  end

  def return_skills
    @skills = @replaced_skills.dup
    @replaced_skills.clear
    return true
  end

  def skill_can_use?(skill_id)
    return false if @disable_skills.include?(skill_id)
    return kyon_kmt_gm_actor_scu
  end

  def disable_skills(*ids)
    ids.flatten.each{|sid| @disable_skills << sid }
    @disable_skills = @disable_skills.uniq
  end
  def clear_disable_skills() @disable_skills.clear end
end

class Scene_Battle
  alias :kyon_kmt_scn_battle_battle_end :battle_end
  def battle_end(result)
    KMonsTerrain.terrain = 0
    $game_party.actors.each do |a|
      a.clear_disable_skills
      a.return_skills
    end
    kyon_kmt_scn_battle_battle_end(result)
  end
end