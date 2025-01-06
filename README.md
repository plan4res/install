# installation scripts for plan4res

## plan4res_install.sh
This script is used to install the plan4res software 

Requirements:
  plan4res_install.sh must be located within the directory in which you want to install plan4res
  If you want to install plan4res with CPLEX or GUROBI you must also copy in this directory the CPLEX installer for LINUX  (XXX.bin) or your GUROBI licence (XXX.lic)

### Linux
From your terminal, type:
  ./plan4res_install.sh -S <SOLVER> [-L <Installer or Licence>]
  SOLVER can be: CPLEX, GUROBI, SCIP or HiGHS
  -L is mandatory for CPLEX and GUROBI
    - for CPLEX : -L cplexinstaller.bin 
    - for GUROBI: -L gurobi.lic

For removing a previous install:
  ./plan4res_install.sh -C

For getting help:
  .§/plan4res_install.sh -H

### Windows with Vagrant
Requirements:
  Installation requires Windows 7 Pro 64bit SP1 or higher and PowerShell 3.0 or higher. Furthermore, the CPU must support hardware virtualization. On many systems, the hardware virtualization features first need to be enabled in the BIOS.

- Install Git for Windows (use default settings) https://git-for-windows.github.io/
- Install VirtualBox and Extension Pack https://www.virtualbox.org/wiki/Downloads
- Install Vagrant https://www.vagrantup.com/downloads.html
- Run Git Bash
- In a Git Bash terminal, type:
    ./plan4res_install.sh -S <SOLVER> [-L >Installer or Licence>] -V <memory>
      where memory is the amount of memory you wish to allocate to your virtual machine. It must be a multiple of 1024
