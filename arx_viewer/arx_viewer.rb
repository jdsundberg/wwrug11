require 'rubygems'
require 'sinatra'
require 'haml'

require 'fileutils'
require 'uuidtools'
require 'Date'
require 'zip/zip'
require 'utils'

require 'arx_parse'

@@root_dir = "uploads"

get '/' do
  haml :index
end  

# Look into this 
# http://aquantum-demo.appspot.com/file-upload
# Handle POST-request (Receive and save the uploaded file)
post "/upload" do
  @orig_file_name = params['myfile'][:filename]

  # TODO - migrate to directories so I can hold flags 
  # and meta data in the directory with the data
  # sample meta data would be -- last selected fields
  # so - if they return later with a get/aaabbbbbbreference
  # I can show them what they last viewed
  new_filename = String.new
  parse_file = String.new
  if(/\.zip$/i.match(@orig_file_name)) then
    unique_name = "#{UUIDTools::UUID.random_create.to_s}"
    new_directory = "#{@@root_dir}/#{unique_name}"
    new_filename = "#{unique_name}.zip"

    Dir.mkdir(new_directory)
    write_file("#{new_directory}/#{new_filename}", params['myfile'][:tempfile])

    unzip("#{new_directory}/#{new_filename}", new_directory)
    validate_file(new_filename)
    parse_file = ""

  else
    # assuming - normal arx 
    unique_name = "#{UUIDTools::UUID.random_create.to_s}.arx"
    full_unique_name = "#{@@root_dir}/#{unique_name}"

    write_file(full_unique_name, params['myfile'][:tempfile])
  end

  @meta_info = parse_arx_meta(full_unique_name)
  @meta_info['new_filename'] = unique_name
  haml :upload
end


get "/display/:reference" do
  filename = params[:reference]

end

post "/display/:reference" do
  filename = params[:reference]
  
  
  @selected_fields= (params.keys - ["reference"])
  # Possibly change to "wb" -- look into what that means
  @file_contents = parse_arx_display("#{@@root_dir}/#{filename}")
  @fieldid = @file_contents["fieldid"]
  @fields = @file_contents["fields"]
  @data = @file_contents["data"]
  @dtypes = @file_contents["dtypes"]

  # Default that we do not have complex fields selected
  @has_complex_fields = false

  # build up list of index numbers for data array  
  @indexes=Array.new # what column numbers in the fields do I care about
  @selected_fields.each do |selected|
    @fieldid.each_with_index do |field,index|
      if(selected == field) then
        @indexes << index  
        # Check for COMPLEX data types
        if(@dtypes[index] == "STATUSHISTORY") then
          @has_complex_fields = true
        end
        if(@dtypes[index] == "DIARY") then
          @has_complex_fields = true
        end
        if(@dtypes[index] == "CURRENCY") then
          @has_complex_fields = true
        end
      end 
    end  

  end


  @selected_field_name = Array.new
  @indexes.each do |index|
    @selected_field_name << @fields[index]
  end
  

  
  @selected_field_data = Array.new 
  @data.each do |row|
    tmp = Array.new
    # Make values human readable
    @indexes.each do |index|
      val = row[index]
      if (@dtypes[index]=="STATUSHISTORY") then
        combined = Array.new
        re_rows = "\003"
        re_columns = "\004"

        statuses = Array.new
        statuses = val.split(re_rows)
        statuses.each do |stat|
          (time,who) = stat.split(re_columns)
          combined << [Time.at(time.to_i),who].join(re_columns)
        end
        val = combined.join(re_rows)
      end
      if (@dtypes[index]=="TIME") then
        val = Time.at(val.to_i)
      end
      if (@dtypes[index]=="DATE") then
        val = Date.jd_to_civil(val.to_i).join("-")
      end
      if (@dtypes[index]=="TIMEOFDAY") then
        val = val.to_i
        
        hr = val.div(3600)
        min = val.modulo(3600).div(60)
        if (min < 9) then 
          min = "0#{min}"
        end
        sec = val.modulo(60)
        if (sec < 9) then
          sec = "0#{sec}"
        end
        val = "#{hr}:#{min}:#{sec}"
        
      end        
        
      if (@dtypes[index]=="DIARY") then
        combined = Array.new
        re_rows = "\003" # rows
        re_columns = "\004" # columns

        diary_entries = Array.new
        diary_entries = val.split(re_rows)
        diary_entries.each do |de|
          (time,who,what) = de.split(re_columns)
          combined << [Time.at(time.to_i),who,what].join(re_columns)
        end        
        val = combined.join(re_rows)
      end
      
      
      # TODO - need better samples for CURRENCY
      if (@dtypes[index]=="CURRENCY") then
        re_columns = "\004" # columns
        columns = Array.new
        columns = val.split(re_columns)
        columns[2] = Time.at(columns[2].to_i)
        val = columns.join(re_columns)
      end
      
      
      # TODO - fix up attachments references
      if (@dtypes[index]=="ATTACH") then
        # val = val.inspect
        val = "attachment"
      end
      tmp << val
    end
    @selected_field_data  << tmp
  end
  haml :display
end




