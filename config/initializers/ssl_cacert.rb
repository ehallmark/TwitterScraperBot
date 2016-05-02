# Fixes SSL Connection Error in Windows execution of Ruby
# Based on fix described at: https://gist.github.com/fnichol/867550
#ENV['SSL_CERT_FILE'] = File.expand_path(File.dirname(__FILE__)) + "/cacert.pem"
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
