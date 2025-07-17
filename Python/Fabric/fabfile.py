from fabric import Connection
from fabric import task

# Configuration
HOST = "192.168.56.36"
USER = "vagrant"
KEY_FILENAME = "pyvms/.vagrant/machines/scriptbox/virtualbox/private_key"


@task
def run_script(c):
    c.run("echo Hello from the scriptbox!")
    c.run("uptime")

    print(f"Connecting to {USER}@{HOST} using key {KEY_FILENAME}")

    conn = Connection(
        host=HOST,
        user=USER,
        connect_kwargs={
            "key_filename": KEY_FILENAME,
        }
    )

    # Example commands
    conn.run("echo Hello from the scriptbox!")
    conn.run("uname -a")  # or your own script like ./install.sh
