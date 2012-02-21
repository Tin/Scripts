#!/usr/bin/env ruby
domain = ARGV[0]
if not domain
    throw "no domain specified"
end
template = """server {
            listen   80;
            server_name  #{domain};
            rewrite ^/(.*) http://www.#{domain}/$1 permanent;
}


server {

            listen   80;
            server_name www.#{domain};

            access_log /home/public_html/#{domain}/log/access.log;
            error_log /home/public_html/#{domain}/log/error.log;

            location ~* ^.+\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|doc|xls|exe|pdf|ppt|txt|tar|mid|midi|wav|bmp|rtf|js|mov) {
                access_log   off;
                expires      30d;
                root    /home/public_html/#{domain}/public/www;
            }

            location / {
                        root   /home/public_html/#{domain}/public/www;
                        index  index.php index.html;

                        # Basic version of Wordpress parameters, supporting nice permalinks.
                        # include /usr/local/nginx/conf/wordpress_params.regular;
                        # Advanced version of Wordpress parameters supporting nice permalinks and WP Super Cache plugin
                        include /usr/local/nginx/conf/wordpress_params.regular;
            }

            # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
            #
            location ~ \.php$ {
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_index index.php;
                include /etc/nginx/fastcgi_params;
                fastcgi_param SCRIPT_FILENAME /home/public_html/#{domain}/public/www/$fastcgi_script_name;
            }
}
"""
if File.exist? domain
  puts template
else
  File.open(domain, 'w') do |f|
    f.puts template
  end
end