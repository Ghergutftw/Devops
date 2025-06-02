# My Vagrant Project

This project sets up a Vagrant virtual machine using the "ubuntu/jammy64" box. It includes a provisioning script to install necessary packages and configure the environment.

## Project Structure

```
my-vagrant-project
├── Vagrantfile
├── provision.sh
└── README.md
```

## Getting Started

To set up the Vagrant environment, follow these steps:

1. **Install Vagrant**: Make sure you have Vagrant installed on your machine. You can download it from [Vagrant's official website](https://www.vagrantup.com/downloads).

2. **Clone the Repository**: Clone this repository to your local machine.

   ```bash
   git clone <repository-url>
   cd my-vagrant-project
   ```

3. **Start the Vagrant VM**: Run the following command to start the virtual machine.

   ```bash
   vagrant up
   ```

4. **Access the VM**: Once the VM is up and running, you can SSH into it using:

   ```bash
   vagrant ssh
   ```

## Provisioning

The provisioning script `provision.sh` will automatically run when you start the VM. It installs necessary packages and configures the environment as specified.

## Networking

- The VM is configured with a private network IP of `192.168.43.43`.
- It also has a public network configuration for external access.

## Stopping the VM

To stop the virtual machine, use the following command:

```bash
vagrant halt
```

## Destroying the VM

If you want to remove the VM completely, run:

```bash
vagrant destroy
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.