
export GOOGLE_CHROME_APP=google-chrome
export WWW_DIR=/var/www/concepts.com
export CONCEPTS_USER=concepts

cd /home/concepts
/usr/local/rvm/wrappers/ruby-2.5.3/ruby update_concepts.rb
sudo service nginx restart
