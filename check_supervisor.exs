old_pid = Process.whereis(EmergencySystem.Processes.StateServer)

IO.puts("PID anterior: #{inspect(old_pid)}")

Process.exit(old_pid, :kill)

Process.sleep(500)

new_pid = Process.whereis(EmergencySystem.Processes.StateServer)

IO.puts("PID nuevo: #{inspect(new_pid)}")

IO.puts("¿Se reinició el proceso? #{old_pid != new_pid}")
