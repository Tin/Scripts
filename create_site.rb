#!/usr/bin/env ruby
site_name = "cindypan.com"
site_root = "/home/public_html"
root = File.join [site_root, site_name]
wordpress_ver = "3.3.1"

def newpass(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
end

require "mysql"
def init_mysql(site_name)
  [".com", ".net", ".org", ".cn", ".name"].each do |surfix|
    site_name = site_name.gsub(surfix, "")
  end
  site_name = site_name.gsub(".", "").gsub("-", "_")
  pass = newpass(10)
  puts "Initialize mysql for #{site_name}/#{pass}"
  
  begin
    db = Mysql.real_connect("localhost", "root", "", "")
    puts "Mysql version: #{db.get_server_info}"
    db.query("create database #{site_name}")
    puts "if it doens't work `grant all on #{site_name}.* to '#{site_name}'@'localhost' identified by '#{pass}`"
    db.query("grant all on #{site_name}.* to '#{site_name}'@'localhost' identified by '#{pass}'")
    db.query("flush privileges")
  rescue Mysql::Error => e
    puts "Error code: #{e.errno}"
    puts "Error message: #{e.error}"
    puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
  ensure
    db.close if db
  end
  return site_name, pass
end


if File.exist? root
  raise "folder #{root} exist!"
end

`mkdir #{root}`

['log', 'backup', 'private', 'public'].each do |sub|
  `mkdir #{File.join([root, sub])}`
end

Dir.chdir "#{File.join([root, 'public'])}"
puts `pwd`

`wget http://cn.wordpress.org/wordpress-#{wordpress_ver}-zh_CN.zip`
`mv wordpress-#{wordpress_ver}-zh_CN.zip wp.zip`
`unzip wp.zip`
`rm wp.zip`
`mv wordpress www`
Dir.chdir "#{File.join([root, 'public', 'www'])}"

db_username, db_password = init_mysql(site_name)
puts "db_username, db_password = #{db_username}, #{db_password}"

`wget https://api.wordpress.org/secret-key/1.1/salt/`

puts "Create wordpress config"
config = ""
File.open("wp-config-sample.php", "r") do |f|
  while (line = f.gets)
    if line.include? "database_name_here"
      config += "define('DB_NAME', '#{db_username}');\n"
    elsif line.include? "username_here"
      config += "define('DB_USER', '#{db_username}');\n"
    elsif line.include? "password_here"
      config += "define('DB_PASSWORD', '#{db_password}');\n"
    elsif line.include? "put your unique phrase here"
      if line.include? "NONCE_SALT"
        File.open("index.html", 'r') do |salt|
          while (l = salt.gets)
            config += "#{l}\n"
          end
        end
      end
    else
      config += line
    end
  end
end

File.open("wp-config.php", "w") do |f|
  f.puts config
end

`rm index.html`
`sudo chown www-data:www-data -R #{File.join([root, 'public'])}`
