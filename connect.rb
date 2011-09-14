require 'jruby'

require 'lib/arapi7604_build002.jar'
# ARS will not load without log4j required
require 'lib/log4j-1.2.16.jar'  

module Ars
  include_package 'com.bmc.arsys.api'
end

config = {
  :username => 'Sample',
  :password => 'Sample',
  :server => 'remedy',
  :locale => '',
  :port => 3000,
  :authentication => ''
}

# Initialize a connection
user = Ars::ARServerUser.new(
  config[:username],
  config[:password],
  config[:locale],
  config[:server],
  config[:port])
  
# requires Admin
begin 
  puts user.generateGUID
rescue
  puts "Had error"
end

# add .to_a -- to make a nice Ruby Array
puts user.getListForm.to_a

# Fetch all fields from User for 00001
puts user.getEntry("User","000000000000001",[])

# Fetch fields (1,2) from User for 00001
puts user.getEntry("User","000000000000001",[1,2])

# Build a server side qualification
qual = "'1' != $\NULL$"

# Make it "usable" by ARS API
# need to tell the parse what form and qual
q = user.parseQualification("User",qual)

#form,qual,start_number,max_records,sort_fields,entry_fields,useLocale,get_count
puts user.getListEntry("User",q,0,1000,[],[],true,nil).to_a

puts user.getListEntry("User",q,0,1000,[],[],true,nil)[0]
puts user.getListEntry("User",q,0,0,[],[],true,nil)[0].getEntryID


e = Ars::Entry.new()

e.put(java.lang.Integer.new(8),Ars::Value.new("jblow")) # full name
e.put(java.lang.Integer.new(101),Ars::Value.new("Joe Blow")) # login name
e.put(java.lang.Integer.new(109),Ars::Value.new("2")) # license Type (Selection Field - starts at 0)

# user.createEntry("User",e)


# user.exportDefToFile([Ars::StructItemInfo.new(Ars::StructItemInfo::SCHEMA,"User")],true,"test_out_file.arx",true)


# r = user.createEntry("User",e)




