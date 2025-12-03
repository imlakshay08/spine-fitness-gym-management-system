<?php
echo phpinfo();
?>

server {
    listen 80;
    server_name 206.189.137.48;

    # Tell Nginx and Passenger where your app's 'public' directory is
    root /root/myinqpos;

    # Turn on Passenger
    passenger_enabled on;
    passenger_ruby /root/.rbenv/shims/ruby;
}

host -t A inqpos.com

server {
    server_name 206.189.137.48;
    listen 80;
    location / {
        proxy_pass http://206.189.137.48:12001;
    }
}