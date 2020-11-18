require 'sinatra/base'
require './models.rb'

OTH_MAP = '/a'
require 'oth'
require './routes/woodegg.com.rb'
require './routes/a.rb'

use Rack::MethodOverride

map(OTH_MAP) { run WoodEggA }
map('/') { run WoodEggDotCom }

#require './routes/qa.rb'
#map('/qa') { run WoodEggQA }

#require './routes/writer.rb'
#map('/write') { run WoodEggWriter }

#require './routes/edit.rb'
#map('/edit') { run WoodEggEdit }
