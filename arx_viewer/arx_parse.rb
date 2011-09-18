def remove_head_token(string)
  # we are in a string
  if(/^"/.match(string))  then
    tmp_array = string.split(/ /)
    token = Array.new
    tmp = String.new
    while true do
      tmp = tmp_array.shift
      token << tmp
      if (tmp[-1,1] == '"') then
        break
      end
    end

    token = token.join(" ") # 
    token.chop! # remove trailing #
    token.slice!(0) # remove leading #
    new_string = tmp_array.join(" ")

    return [token,new_string]
  end
  
  # not in a string
  tmp_array=string.split(/ /)
  token = tmp_array.shift
  new_string = tmp_array.join(" ")
  return [token,new_string]
end

def parse_arx_data(line)
  data = Array.new
  line.chomp!

  while true do 
    (token,line) = remove_head_token(line)
    data << token
    if (line.length == 0) then 
      break
    end
  end

  # remove DATA token 
  data.shift
  return data

end

def parse_arx_display(arx_file)
  return parse_arx(arx_file, false)
end

def parse_arx_meta(arx_file)
  return parse_arx(arx_file, true)
end

def parse_arx(arx_file,skip)
  meta = Hash.new
  meta["data"]=Array.new
  counter = 0
  status_history_index = nil
  begin
    file = File.new(arx_file,"r")
    while (line=file.gets)
      
      line.chomp!
      
      if (/^DATA /.match(line)) then
        counter = counter + 1
        if (skip==false) then 
          meta["data"] << parse_arx_data(line)
        end
      end

      if (/^SCHEMA "(.*)"/.match(line)) then
        meta['schema'] = $1
      end

      if (/^FIELDS "(.*)"/.match(line)) then
        fields = Array.new
        fields = $1.split(/" "/)
        meta['fields'] = fields
      end

      if (/^FLD-ID (.*)/.match(line)) then
        fieldid = Array.new
        fieldid = $1.split(/ /)
        meta['fieldid'] = fieldid
        status_history_index = meta['fieldid'].find_index("15")
      end

      if (/^DTYPES (.*)/.match(line)) then
        dtypes = Array.new
        dtypes = $1.split(/ /)
        meta['dtypes'] = dtypes
        if (status_history_index!=nil) then
          meta['dtypes'][status_history_index] = "STATUSHISTORY"
        end
      end
    end
    file.close
  rescue => err
    puts "Exception #{err}"
  end
  
  
  meta["data_count"] = counter

  return meta  
end


