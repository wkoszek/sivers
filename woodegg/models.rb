require 'd50b/woodegg'
require 'yaml'

class NilClass
  def h ; '' ; end
  def to_html ; '' ; end
  def size ; 0 ; end
end

class String
  def h
    self.encode(self.encoding, :xml => :attr)[1...-1]
  end

  def nl2br
    self.gsub("\n", '<br/>')
  end

  def autolink
    self.gsub(/(http\S*)/, '<a href="\1">\1</a>')
  end

  def to_html
    self.h.autolink.nl2br
  end

  # for Markdown headers, turns '## this' into '### this'
  def demote_header
    self.split("\n").map {|x| (x[0] == '#') ? ('#' + x) : x}.join("\n")
  end

  # for Markdown headers, turns '## this' into '# this'
  def promote_header
    self.split("\n").map {|x| (x[0] == '#') ? x[1..-1] : x}.join("\n")
  end

  # instead of h4-deep header, change it to a bold print line
  def h4_to_bold
    self.split("\n").map {|x| (x[0,4] == '####') ? ('**%s**' % x.gsub('#', '').strip) : x}.join("\n")
  end
end

class Person

  class << self
    def country_val(country_code, statvalue)
      statkey = (country_code == 'ANY') ? 'woodegg' : "woodegg-#{country_code.downcase}"
      filter(id: Userstat.select(:person_id).filter(statkey: statkey, statvalue: statvalue)).all
    end

    # for people that are not yet researchers, writers, editors
    # adds [:book_country] property to each person in array
    # gets it from this tag in userstats, statkey: woodegg-CC
    def add_book_country(array_of_people, statvalue='14w')
      sql = "SELECT person_id, statkey FROM userstats" +
	" WHERE statvalue='%s' AND person_id IN (%s)" %
	[statvalue, array_of_people.map(&:id).join(',')]
      Peeps::DB[sql].all.each do |rc|
	p = array_of_people.find {|x| x.id == rc[:person_id]}
	/woodegg-([a-z]{2})/.match rc[:statkey]
	p.values[:book_country] = $1.upcase
      end
      array_of_people
    end

    # hash {countrycode => [array, of, people]}
    def interviewees
      statkeys = Countries.hsh.keys.map {|cc| "woodegg-#{cc.downcase}"}
      stats = Userstat.select(:person_id, :statkey).filter(statkey: statkeys, statvalue: 'interview').map(&:values)
      res = {}
      # hash of bios, to add as attribute to each person, below
      bios = {}
      Userstat.select(:person_id, :statvalue).filter(statkey: 'woodegg-bio').each {|u| bios[u[:person_id]] = u[:statvalue]}
      Countries.hsh.keys.each do |cc|
	person_ids = stats.find_all {|x| x[:statkey] == "woodegg-#{cc.downcase}"}.map {|y| y[:person_id]}
	pp = Person.filter(id: person_ids).all
	# add attribute of [:interviewee_bio], if there is one (nil if not)
	pp.each do |p|
	  p.values[:interviewee_bio] = bios[p.id]
	end
	res[cc] = pp
      end
      res
    end
  end

  # hardcoded to just me, Karol,and MR for now.
  def admin?
    [1, 10471, 59196].include?(id)
  end

  def interviewee_bio
    u = userstats_dataset.filter(statkey: 'woodegg-bio').first
    u.nil? ? nil : u.statvalue
  end

  def set_interviewee_bio(content)
    u = userstats_dataset.filter(statkey: 'woodegg-bio').first
    if u
      u.update(statvalue: content)
    else
      Userstat.create(person_id: id, statkey: 'woodegg-bio', statvalue: content)
    end
  end

  # first get values like 'woodegg-vn', 'woodegg', 'woodegg-cn'
  # then just get the 'vn' part, and compact it to remove the nil matches
  # then upper-case it, and return array of unique values like ['VN', 'CN']
  def countries_with_statvalue(v)
    Userstat.select(:statkey).filter(person_id: id, statvalue: v).map do |u|
      /woodegg-([a-z]{2})/.match u.statkey
      $1
    end.compact.map do |k|
      k.upcase
    end.uniq
  end

  # some .edu addresses are pre-paid for all books
  def prepaid?
    WoodEgg::config['email_suffix'].any? { |sufx| email.end_with? sufx }
  end
end

# for Rack::Auth::Basic to share info with Sinatra routes (instead of @@person)
class HTTPAuth
  @person = nil
  class << self
    attr_accessor :person
  end
end

class Userstat
  # array of hashes with symbol keys created_at, person_id, statkey, statvalue, name
  # TODO: probably a more elegant solution to this. put this + Countries.userstats* together?
  def self.newest_woodegg
    query = "SELECT peeps.userstats.created_at, person_id, statkey, statvalue, name" +
    " FROM peeps.userstats LEFT JOIN peeps.people ON peeps.userstats.person_id=peeps.people.id" +
    " WHERE statkey LIKE 'woodegg%' ORDER BY peeps.userstats.id DESC LIMIT 100"
    Sequel.postgres('d50b', user: 'd50b').fetch(query).all
  end
end

class Countries
  class << self
    def hsh
      {'KH' => 'Cambodia',
      'CN' => 'China',
      'HK' => 'Hong Kong',
      'IN' => 'India',
      'ID' => 'Indonesia',
      'JP' => 'Japan',
      'KR' => 'Korea',
      'MY' => 'Malaysia',
      'MN' => 'Mongolia',
      'MM' => 'Myanmar',
      'PH' => 'Philippines',
      'SG' => 'Singapore',
      'LK' => 'Sri Lanka',
      'TW' => 'Taiwan',
      'TH' => 'Thailand',
      'VN' => 'Vietnam'}
    end

    def codes
      hsh.keys
    end

    # helper for routes like /cn or /jp
    def routemap
      '/(' + codes.map(&:downcase).join('|') + ')$'
    end

    # helper for routes like /cn/123 or /tw/321
    def routemap2
      '/(' + codes.map(&:downcase).join('|') + ')/([0-9]+)$'
    end

    # all WoodEgg userstats, per country
    def userstats
      statkeys = "'woodegg','" + Countries.hsh.keys.map {|x| "woodegg-#{x.downcase}"}.join("','") + "'"
      query = "SELECT statkey, statvalue, COUNT(*) FROM peeps.userstats" +
	" WHERE statkey IN (#{statkeys})" +
        " AND statvalue NOT IN ('clicked')" +
        " AND LENGTH(statvalue) > 2 AND LENGTH(statvalue) < 50" +
	" GROUP BY statkey, statvalue ORDER BY statkey, statvalue"
      Sequel.postgres('d50b', user: 'd50b').fetch(query).all
    end

    # make a grid out of an array of {:statkey=>"x", :statvalue=>"y", :count=>9}
    def userstats_grid
      usrsts = self.userstats
      # get all unique keys and values
      require 'set'
      k = Set.new
      v = Set.new
      usrsts.each {|u| k << u[:statkey] ; v << u[:statvalue]}
      # init a nil-filled grid
      row = {}
      v.each {|x| row[x] = nil}
      grid = {}
      k.each {|x| grid[x] = row.dup}
      # replace nil with usrsts count
      usrsts.each do |u|
        grid[u[:statkey]][u[:statvalue]] = u[:count]
      end
      grid
    end

    # input 'woodegg' = output 'ANY'
    # input 'woodegg-lk' = output 'Sri Lanka'
    # input 'woodegg-qa' = output 'woodegg-qa'
    def from_userstat(statkey)
      return 'ANY' if statkey == 'woodegg'
      code = statkey.gsub('woodegg-', '').upcase
      return self.hsh[code] if self.hsh[code]
      statkey
    end

    # maybe a weird place to put this.  Format:
    # https://www.#{domain}/dp/#{asin}
    def amazon_domains
      {"amazon.com" => '$9.99',
       "amazon.ca" => '$9.99',
       "amazon.com.au" => '$9.99',
       "amazon.co.uk" => '₤5.99 +VAT',
       "amazon.de" => '€6.99 +VAT',
       "amazon.fr" => '€6.99 +VAT',
       "amazon.es" => '€6.99 +VAT',
       "amazon.it" => '€6.99 +VAT',
       "amazon.co.jp" => '¥1000',
       "amazon.in" => 'Rs 599',
       "amazon.com.br" => 'R$24.99',
       "amazon.com.mx" => '$99 MX'}
    end
  end
end

module Persony
  def email_formletter_subject_profile(formletter_id, subject, profile)
    f = Formletter[formletter_id]
    p = self.person
    h = {subject: subject, category: 'woodegg', profile: profile}
    f.send_to(p, h)
  end
end

