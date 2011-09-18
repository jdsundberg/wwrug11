

# define some haml helpers
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
end


def unzip(filename,target_directory)
  
  current_directory = Dir.pwd
  Dir.chdir(target_directory)
  puts "#{current_directory}/#{filename}"
  Zip::ZipInputStream::open("#{current_directory}/#{filename}") { |io|
    while (entry = io.get_next_entry)
      # puts "Contents of #{entry.name}: '#{io.read}'"
      puts entry.name
    end
  }
end

# TODO - Is this truly a stream?
def write_file(newfile, instream)
  File.open(newfile, "w") do |f|
    f.write(instream.read)
  end
end

# TODO
# check for single .arx
# what is it's name?
# check for singe directory from zip???
def validate_file(filename)
  return true
end