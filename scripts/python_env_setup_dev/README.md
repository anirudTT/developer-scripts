# Python Environment Deployment Toolkit

This toolkit is designed to facilitate the deployment of Python environments and applications to remote hosts, perform installation of necessary packages, and run smoke tests to ensure system integrity and functionality.

## Files Description

- **README.md**
  - This file provides an overview and usage instructions for the toolkit.

- **hosts.config**
  - Configuration file containing the details of the remote hosts (like IP addresses and usernames) where the Python environment will be deployed.

- **scp_copy_and_install_python.sh**
  - Shell script responsible for securely copying the Python environment setup files and necessary Python wheel (.whl) files to remote hosts and installing them. It supports dynamic specification of the ZIP file and an option to remove existing directories.

- **run_smoke_tests.sh**
  - Shell script to execute Python smoke tests on remote hosts to verify the correct installation and operation of the Python environment and its dependencies.

- **smoke_test.py**
  - Python script that contains the smoke tests run by `run_smoke_tests.sh`. It checks the functionality of the Python environment and installed packages.

- **wrapper.sh**
  - Script that automates the execution of `scp_copy_and_install_python.sh` across multiple ZIP files located in a designated directory, optionally propagating the removal of existing directories, performing installations, and running smoke tests.

## Usage Instructions

1. **Configure Hosts:**
   - Edit `hosts.config` to include the IP addresses and usernames of the hosts where you wish to deploy the Python environment.
   - Example entry in `hosts.config`: `dummy@11.990.99.110`

2. **Prepare the ZIP Files:**
   - Ensure that ZIP files of the Python environments are placed within the `Releases` folder on your local system.

3. **Deploying the Python Environment:**
   - Run the `wrapper.sh` script with appropriate flags to control the deployment:
     - To deploy all ZIP files from the `Releases` folder and remove existing directories, execute: `./wrapper.sh -r`
     - To perform installations only without removing existing directories: `./wrapper.sh -i`
     - To combine installation with directory cleanup: `./wrapper.sh -ri`

4. **Running Smoke Tests:**
   - Optionally, after deployment, run `run_smoke_tests.sh` to execute the smoke tests defined in `smoke_test.py` on each remote host. This verifies the installation and basic functionality of the Python environment.
   - To execute smoke tests following deployment for each ZIP file, use: `./wrapper.sh -s`
   - Combine with installations and cleanup: `./wrapper.sh -ris`

## FAQs

- **Why does the script keep prompting for a password?**
  - If SSH key-based authentication is not set up between your local machine and the remote hosts, the script will repeatedly prompt for a password, which can become inconvenient, especially when deploying to multiple hosts. To streamline this process, set up SSH key-based authentication by generating an SSH key pair and copying the public key to the `~/.ssh/authorized_keys` file on each remote host. For more information, visit [SSH Key Setup Guide](https://www.ssh.com/academy/ssh/copy-id).

## Additional Notes

- Ensure you have appropriate SSH access and permissions on the remote hosts.
- Verify that all paths and dependencies in the scripts are correctly set up according to your system and network configurations.
- It is crucial that the ZIP file and its path are correctly set up as this script directly relies on it for deployment.
