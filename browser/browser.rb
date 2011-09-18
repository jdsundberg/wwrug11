require "rubygems"

require 'sinatra'
require 'haml'
require File.join(File.dirname(__FILE__),"..","klink-ruby-api/lib/klink-ruby-api")
require 'pp'

use Rack::Session::Pool

def get_form_structure(form)
  
  if session["form_cache"].key?(form) then
    return session["form_cache"][form] 
  end

  
  session["form_cache"][form] = session["klink_handle"].structure(form)
  
  return session["form_cache"][form]
  
end

def get_record_number(rec_no)
  # Cases:
  # 0000000444400002
  # XYZ0000044441112
  return rec_no.split(/\D/)[-1].to_i
end

def get_record_number_next(rec_no)
  # Cases:
  # 0000000444400002
  # XYZ0000044441112
  orig_size = rec_no.length
  precede = rec_no.split(/\d/).to_s
  precede_size = precede.length
  
  num = get_record_number(rec_no)
  next_num = (num + 1).to_s.rjust(orig_size-precede_size,"0")
  
  next_val = "#{precede}#{next_num}"
  
  return next_val
end

def get_record_number_previous(rec_no)
  # Cases:
  # 0000000444400002
  # XYZ0000044441112
  orig_size = rec_no.length
  precede = rec_no.split(/\d/).to_s
  precede_size = precede.length
  
  num = get_record_number(rec_no)
  next_num = (num - 1).to_s.rjust(orig_size-precede_size,"0")
  
  next_val = "#{precede}#{next_num}"
  
  return next_val
end

# Temporary - learning about sessions
get '/session_info' do
  session.to_yaml
end

helpers do
  def link_to(url,name)
    return %!<a href="#{url}">#{name}</a>!
  end
  
  # Takes time in seconds and returns in days,hours,minutes,seconds
  # Ex: 3 Days 4 Hours 5 Minutes 6 Seconds
  def seconds_to_human(seconds)
    ret_val = ""
    ret_val = ret_val + (seconds/86400).to_i.to_s + " Days "
    ret_val = ret_val + ((seconds % 86400)/3600).to_i.to_s + " Hours "
    ret_val = ret_val + (((seconds % 86400) % 3600)/60).to_i.to_s + " Minutes "
    ret_val = ret_val + (((seconds % 86400) % 3600) % 60).to_i.to_s + " Seconds"
    return ret_val
  end
  
  def authenticated?
    if (session["auth"].nil?) then
      redirect "/login"
    end
    return true
  end
  
  def valid_user?(user,pass)
    
    forms = session["klink_handle"].structures.length
  
    if forms > 0 then 
      return true
    else 
      return false
    end
    
  end

  def invalidate_user!
    session["klink_handle"] = nil
    
  end


end

before do
  unless request.path_info == '/login' ||  request.path_info == '/'
    authenticated?
    unless request.path_info == '/recent_searches' 
      session["recent"]  << request.fullpath
    end
  end
end

get '/about' do
  redirect "http://www.kineticdata.com"
end

get '/' do
  haml :index, :layout => :layout_not_connected
end

get '/home' do
  @statistics = session["klink_handle"].statistics
  @configs = session["klink_handle"].configurations
  haml :home
end

get '/login' do
  session.keys.each do |k|
    session[k] = nil
  end
  haml :login, :layout => :layout_not_connected
end

post '/login' do

    session["user_id"] = params[:user_id]
    session["password"] = params[:password]
    
    session["form_cache"] = Hash.new

    handle = Kinetic::MultiLink.new
    handle.set_connection_klink("sample:8081","127.0.0.1")
    handle.set_connection_user(session["user_id"],session["password"])

    session["klink_handle"] = handle

    session["recent"] = Array.new

  if(valid_user?(params[:user_id],params[:password])) then
    session["auth"] = "true"
    redirect "/home"
  else
    redirect "/login"
  end
  
end  

get '/logout' do

  invalidate_user!

  # blow away the session
  session.keys.each do |k|
    session[k] = nil
  end
  redirect "/home"
end

get '/recent_searches' do
  haml :recent_searches
end

get '/service_stats' do
  @statistics = Kinetic::Link.statistics
  haml :service_stats
end

get '/configuration' do
  @config = session["klink_handle"].configurations
  haml :configuration
end

get '/statistics' do
  @statistics = session["klink_handle"].statistics
  haml :statistics
end

get '/form/:name/:id' do
  @form = params[:name]
  @record = params[:id]
  @form_details = get_form_structure(@form)
  @entry = session["klink_handle"].entry(@form,@record)
  haml :form_name_id
end

get '/form/:name/:id/next' do
  @form = params[:name]
  @record = params[:id]
  
  @entry = Hash.new

# Change this to query for next -- somehow
# something like query > current -- max 1 -- sort request_id???
# Right now -- this will end up looping too much and "forever" when at the max request_id
  while (@entry.empty?) do
    @record = get_record_number_next(@record)
    @entry = session["klink_handle"].entry(@form,@record)
  end

  @form_details = get_form_structure(@form)
  haml :form_name_id


  
end

get '/form/:name/:id/previous' do
  @form = params[:name]
  @record = params[:id]
  
  @entry = Hash.new

# Change this to query for next -- somehow
# something like query > current -- max 1 -- sort request_id???
# Right now -- this will end up looping too much and "forever" when at the max request_id
  while (@entry.empty?) do
    @record = get_record_number_previous(@record)
    @entry = session["klink_handle"].entry(@form,@record)
  end

  @form_details = get_form_structure(@form)
  haml :form_name_id


  
end

get '/form/:name' do
  @form = params[:name]
  @form_details = get_form_structure(@form)
  @entries = session["klink_handle"].entries_with_fields(@form, :fields=>["all"])
  haml :form
end

get '/forms' do
  @forms = session["klink_handle"].structures
  haml :forms
end


