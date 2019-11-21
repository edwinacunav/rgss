# * KMonstersTerrain Parser Script for Mango Version 1.3.0
#   Scripter : Kyonides Arkanthes

module KMonsTerrain
  parse_file = true
  @terrains = {} # Do not edit this line!
  @good_terrains = {} # Do not edit this line!
  @bad_terrains = {} # Do not edit this line!
  @monster_boosts = {} # Do not edit this line!
  @monster_debuff = {} # Do not edit this line!
  @monster_skills = {} # Do not edit this line!
  @actor_disable_skills = {} # Do not edit this line!
  @monster_replace_skillset = {} # Do not edit this line!
  # [TerrainID] = Backdrop Name
  @terrains[1] = '043-Cave01'
  @terrains[2] = '011-PortTown01'
  # [MonsterID] = [All, Terrain, IDs]
  @good_terrains[1] = [1]
  # [MonsterID] = [All, Terrain, IDs]
  @bad_terrains[1] = [2]
  # [MonsterID] = [HP, SP, STR, DEX, AGI, INT, ATK, PD, MD, EVA, Gold]
  @monster_boosts[1] = [1, 50, 25, 15, 5, 5, 15, 15, 5, 5, 5, 20]
  # [MonsterID] = [[SkillID, Rating], etc.]
  @monster_skills[1] = [[11, 5]]
  # [MonsterID] = [HP, SP, STR, DEX, AGI, INT, ATK, PD, MD, EVA, Gold]
  @monster_debuff[1] = [50, 25, 15, 5, 5, 15, 15, 5, 5, 5, 4]
  # Monsters' Boost or Debuff Level Multiplier
  # { MonsterID => Initial Level, etc. }
  @monster_levels = { 1 => 2, 2 => 2 }
  # [Actor_ID] = { TerrainID => [Disabled_Skill_ID1, etc.], etc. }
  @actor_disable_skills[1] = { 1 => [2] }
  @actor_disable_skills[2] = { 1 => [1], 2 => [2] }
  # A Monster's Set of Useless Skills used to replace a Hero's Skillset
  # [MonsterID] = [Useless_Skill_ID1, etc.]
  @monster_replace_skillset[1] = [1, 2]
  @monster_replace_skillset[2] = [5, 6]
  class Boost# Do not alter this class!
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
  def self.make_file
    boosts = {}
    ids = @monster_boosts.keys.sort
    ids.each do |mid|
      mb = @monster_boosts[mid]
      boost = Boost.new
      boost.hp = mb.pop
      boost.sp = mb.pop
      boost.str = mb.pop
      boost.dex = mb.pop
      boost.agi = mb.pop
      boost.int = mb.pop
      boost.atk = mb.pop
      boost.pdef = mb.pop
      boost.mdef = mb.pop
      boost.eva = mb.pop
      boost.gold = mb.pop
      boosts[mid] = boost
    end
    skills = {}
    ids = @monster_skills.keys.sort
    ids.each do |sid|
      boosts[sid].actions = @monster_skills[sid].map do |s,r|
        gba = RPG::Enemy::Action.new
        gba.kind = 1
        gba.skill_id = s
        gba.rating = r
        gba
      end
    end
    debuffs = {}
    ids = @monster_debuff.keys.sort
    ids.each do |mid|
      mb = @monster_debuff[mid]
      debuff = Boost.new
      debuff.hp = -mb.pop
      debuff.sp = -mb.pop
      debuff.str = -mb.pop
      debuff.dex = -mb.pop
      debuff.agi = -mb.pop
      debuff.int = -mb.pop
      debuff.atk = -mb.pop
      debuff.pdef = -mb.pop
      debuff.mdef = -mb.pop
      debuff.eva = -mb.pop
      debuff.gold = -mb.pop
      debuffs[mid] = debuff
    end
    puts "Opening KMonsTerrain file...", boosts, debuffs
    File.open('Data/KMonsTerrain.rxdata','wb') do |f|
      Marshal.dump(@terrains, f)
      Marshal.dump(@good_terrains, f)
      Marshal.dump(@bad_terrains, f)
      Marshal.dump(boosts, f)
      Marshal.dump(debuffs, f)
      Marshal.dump(@monster_levels, f)
      Marshal.dump(@actor_disable_skills, f)
      Marshal.dump(@monster_replace_skillset, f)
    end
    puts :Finished
  end
  make_file if parse_file
end