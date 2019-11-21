#!/usr/bin/env ruby
# * KRumors XP TXT File Parser
#   Scripter : Kyonides-Arkanthes
#   2019-02-23

module Graphics
  def self.frame_rate
    60
  end
end

class KRumorLocation
  attr_reader :id, :name, :map_id, :time
  attr_writer :ready
  def initialize(new_id, name, map_id, time)
    @id = new_id
    @name = name
    @map_id = map_id
    @time = (time * 60 * Graphics.frame_rate).to_i
  end

  def update
    return if @ready or @time == 0
    @time -= 1
    @ready = @time == 0
  end
  def ready?() @ready end
end

class KRumor
  def initialize(loc_id, sources, spoils, ids)
    @place_id = loc_id
    @injury_rate = 0
    @percent = 100
    @spoils_max = 1
    @sources = sources || []
    @spoils = spoils
    @spoils_found = []
    @quest_ids = ids || []
    @story = []
    @book = { :book => nil, :page => nil }
    @title = ''
    @subtitle = ''
    @description = ''
    @confirm = nil
    @read = false
  end
  def confirm!() @confirm = true end
  def book_contents() [@title, @subtitle, @story] end
  attr_reader :sources, :spoils, :spoils_found, :story, :confirm, :book
  attr_reader :quest_ids, :place_id
  attr_accessor :title, :subtitle, :description, :sources_total, :percent
  attr_accessor :spoils_max, :read, :injury_rate
end

class KFakeItem
  def initialize(kind, id, amount)
    @kind = kind
    @id = id
    @amount = amount
  end
  def ==(other) other.kind == @kind and other.id == @id end
  def amount=(new_amount) @amount = new_amount end
  attr_reader :kind, :id, :amount
end

module KRumors
  def self.parse_locations
    @locations = [KRumorLocation.new(0, '', 0, 0)]
    lines = File.readlines('Rumors/rumor locations.txt')
    loc_max = lines.size / 3
    loc_max.times do |n|
      name = lines.shift.gsub(/destination: /i, '').chop
      map_id = lines.shift.scan(/\d+/)[0].to_i
      time = lines.shift.scan(/\d+/)[0].to_i
      @locations << location = KRumorLocation.new(n + 1, name, map_id, time)
    end
    filename = 'Data/KRumorsLocations.rxdata'
    File.open(filename, 'wb'){|file| Marshal.dump(@locations, file) }
  end

  def self.parse_rumors
    @rumors = {}
    lines = File.readlines('Rumors/rumors.txt') + ['']
    line_max = lines.size / 15
    line_max.times { retrieve_rumors(lines) }
    File.open('Data/KRumors.rxdata','wb'){|file| Marshal.dump(@rumors, file) }
    @npc_rumors = {}
    lines = File.readlines('Rumors/npc rumors.txt') + ['']
    line_max = lines.size / 13
    line_max.times { retrieve_npc_rumors(lines) }
    File.open('Data/KRumorsNPC.rxdata','wb'){|file| Marshal.dump(@npc_rumors, file) }
  end

  def self.retrieve_rumors(lines)
    place_id = lines.shift.scan(/\d+/)[0].to_i
    @rumors[place_id] ||= []
    title = lines.shift.chomp.sub!(/title: /i, '')
    caption = lines.shift.chomp.sub!(/subtitle: /i, '')
    desc = lines.shift.chomp
    sources = lines.shift.chomp.sub(/sources: /i, '')
    sources = sources.split(', ')
    spoils = parse_spoils(lines.shift)
    percent, attempts = lines.shift.scan(/\d+/).map{|d| d.to_i }
    rate = lines.shift.scan(/\d+/)[0].to_i
    quest_ids = lines.shift.scan(/\d+/).map{|d| d.to_i }
    rumor = KRumor.new(place_id, sources, spoils, quest_ids)
    rumor.title = title
    rumor.subtitle = caption
    rumor.description = desc.sub!(/description: /i, '')
    rumor.percent = percent
    rumor.injury_rate = rate
    rumor.spoils_max = attempts
    book_ids = lines.shift.scan(/\d+/)
    unless book_ids.empty?
      book_id, page_id = book_ids.map{|d| d.to_i }
      rumor.book[:book] = book_id
      rumor.book[:page] = page_id
    end
    4.times { rumor.story << lines.shift.chomp }
    lines.shift
    @rumors[place_id] << rumor
  end

  def self.parse_spoils(line)
    line.sub!(/\w+: /i, '')
    spoils = []
    results = line.scan(/\w+ \d+ - \d+/i)
    results.each do |item|
      kind = item[/\w+/].downcase
      kind = kind[/experienc\w+/] ? :exp : kind[/money/] ? :gold : kind.to_sym
      item_id, amount = item.scan(/\d+/).map{|d| d.to_i }
      spoils << KFakeItem.new(kind, item_id, amount)
    end
    spoils
  end

  def self.retrieve_npc_rumors(lines)
    place_id = lines.shift.scan(/\d+/)[0].to_i
    @npc_rumors[place_id] ||= []
    title = lines.shift.chomp.sub!(/title: /i, '')
    caption = lines.shift.chomp.sub!(/subtitle: /i, '')
    sources = lines.shift.chomp.sub(/sources: /i, '')
    sources = sources.split(', ')
    spoils = parse_spoils(lines.shift)
    percent, attempts = lines.shift.scan(/\d+/).map{|d| d.to_i }
    quest_ids = lines.shift.scan(/\d+/).map{|d| d.to_i }
    rumor = KRumor.new(place_id, sources, spoils, quest_ids)
    book_ids = lines.shift.scan(/\d+/)
    unless book_ids.empty?
      book_id, page_id = book_ids.map{|d| d.to_i }
      rumor.book[:book] = book_id
      rumor.book[:page] = page_id
    end
    4.times { rumor.story << lines.shift.chomp }
    lines.shift
    rumor.title = title
    rumor.subtitle = caption
    rumor.percent = percent
    rumor.spoils_max = attempts
    puts rumor.sources
    @npc_rumors[place_id] << rumor
  end

  def self.parse_rumor_opinions
    filenames = Dir['Rumors/rumor opinions *.txt'].sort
    return if filenames.empty?
    opinions = {}
    filenames.each do |filename|
      oid = filename.scan(/\d+/)[0].to_i
      opinions.default = {}
      opinions[oid] = opinion = {}
      lines = File.readlines(filename) + ['']
      lines.shift
      generic = []
      4.times { generic << lines.shift.chomp }
      lines.shift
      opinion.default = generic
      (lines.size / 6).times do |n|
        hero_id = lines.shift.scan(/\d+/)[0].to_i
        opinion[hero_id] = []
        4.times { opinion[hero_id] << lines.shift.chomp }
        lines.shift
      end
    end
    name = 'Data/KRumorsOpinions.rxdata'
    File.open(name,'wb'){|file| Marshal.dump(opinions, file) }
  end

  def self.parse_book_titles
    titles = {}
    lines = File.readlines('Rumors/book titles.txt')
    lines.each do |line|
      book_id = line.scan(/\d+/)[0].to_i
      title = line.gsub(/\d+ - |\n/,'')
      titles[book_id] = title
    end
    name = 'Data/KRumorsBookTitles.rxdata'
    File.open(name,'wb'){|file| Marshal.dump(titles, file) }
  end
  parse_locations
  parse_rumors
  parse_rumor_opinions
  parse_book_titles
  print "Finished parsing the locations, rumors, opinions and books list!\n"
  #p "Total Locations: #{@locations.size}", "Total Rumors Groups: #{@rumors.size}"
  #@rumors.each {|id,rumors| p "Total Rumors: #{rumors.size}" }
end