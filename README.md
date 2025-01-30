# installation scripts for plan4res

## plan4res_install.sh
This script is used to install the plan4res software 

Requirements:
  plan4res_install.sh must be located within the directory in which you want to install plan4res
  If you want to install plan4res with CPLEX or GUROBI you must also copy in this directory the CPLEX installer for LINUX  (cplexXXX.bin) or the GUROBI installer for LINUX (gurobiXXX.tar.gz) and your GUROBI licence (gurobi.lic)

### Linux
From your terminal, type

  ./plan4res_install.sh [-S <SOLVER>] [-I <installer>] [-L <license>] [-v <version>] [-M <mpi>] [-U <software>] [-C] [-H]

        -S/--solver is optional, if not provided, HiGHS is chosen
        
           SOLVER can be: CPLEX, GUROBI, SCIP or HiGHS  (if not provided, HiGHS is chosen)
        
        -I/--installer is mandatory for CPLEX and GUROBI
        
            - for CPLEX : -I cplexinstaller.bin 
            
            - for GUROBI: -I gurobi.lic
        
        -L/--license is mandatory for GUROBI
        
            -L gurobi.lic
        
        -v/--version is optionnal and allows to choose the version if using SCIP (9.2.0 used if not provided)
   
            -v 9.2.0
        
        -M/--mpi is optional, it is used to change the mpi version (default: OpenMPI)"	
        
            mpi can be: OpenMPI or MPICH
        
        -U/--update is optional. It is used to force the update of one of the softwares
        
            software can be: coin, stopt, sms++
            
            This option can be included many times (eg -U stopt -U coin)
        
        -C/--clean is used to remove plan4res
        
        -H/--help provides help


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

      ./plan4res_install.sh [-S <SOLVER>] [-I <installer>] [-L <license>] [-v <version>] [-M <mpi>] [-U <software>] [-V <memory>] [-C] [-H]

     -V/--vagrant is mandatory to install on Vagrant

             memory is the amount of memory you wish to allocate to your virtual machine. It must be a multiple of 1024

          other options have the same behavior than in Linux

