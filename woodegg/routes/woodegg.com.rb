#encoding: utf-8
require 'kramdown'

class WoodEggDotCom < Sinatra::Base

  def pagetitle(title)
    @pagetitle = title
    @pagetitle += ' | Wood Egg' unless @pagetitle.include? 'Wood Egg'
  end

  configure do
    # set root one level up, since this routes file is inside subdirectory
    set :root, File.dirname(File.dirname(File.realpath(__FILE__)))
    set :views, Proc.new { File.join(root, 'views/woodegg.com') }
  end

  before do
    @countrylist = Countries.hsh.values.join(', ')
  end

  not_found do
    redirect '/', 301
  end

  get '/' do
    @bodyid = 'homepage'
    pagetitle 'Entrepreneur’s Guides to Asia'
    @countries = Countries.hsh
    @cc_title = {}
    Book.select(:country, :title).all.each {|b| @cc_title[b.country] = b.title}
    erb :home
  end

  get '/about' do
    @bodyid = 'aboutpage'
    pagetitle 'About'
    erb :about
  end

  get '/contact' do
    @bodyid = 'contactpage'
    pagetitle 'Contact'
    erb :contact
  end

  get Regexp.new(Countries.routemap) do |cc|
    @bodyid = 'bookpage'
    @country_code = cc
    @ccode = cc.upcase
    @cname = Countries.hsh[@ccode]
    @country_name = @cname.gsub(' ', '&nbsp;')
    @country_name = 'the&nbsp;Philippines' if @country_name == 'Philippines'
    @book = Book.filter(country: @ccode).order(:id).last
    @booktitle = @book.title
    @isbn = @book.isbn
    @writers = '<a href="%s">%s</a>' % [@book.writers[0].url, @book.writers[0].company]
    if @book.writers[1]
      @writers << ' &amp; <a href="%s">%s</a>' % [@book.writers[1].url, @book.writers[1].company]
    end
    pagetitle @booktitle
    @title, @subtitle = @booktitle.split(': ')
    @questions = File.open("./views/woodegg.com/q-#{cc}.html", 'r:utf-8').read
    @salescopy = Kramdown::Document.new(@book.salescopy).to_html
    erb :bookpage
  end
end
