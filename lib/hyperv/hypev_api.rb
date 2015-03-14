# Hyper-V API Library

class HyperV
  class Server
    def connect(url, username, password)
    end

    def valid_server?(url, server_id)

    end

    def create_server(hostname, host_os, host_user, host_password)
      # Hyper-V API should return the server-id immediately.
      # Server create process can be strated in the background.
    end

    def machine_status(server_id)

    end

    def power_on(server_id)

    end

    def get_hostname(server_id)

    end

    def get_transport_type(server_id)

    end

    def destroy_machine(server_id)

    end

    def power_off(server_id)

    end
  end
end