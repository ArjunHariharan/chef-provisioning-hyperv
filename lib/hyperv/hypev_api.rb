# Hyper-V API Library

module HyperV
  module Api
    def connect(url, username, password)
    end

    def valid_server?(url, server_id)

    end

    def create_server(hostname, host_os, host_user, host_password)
      # Hyper-V API should return the server-id immediately.
      # Server create process can be strated in the background.
    end
  end
end