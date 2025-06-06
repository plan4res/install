# installation scripts for plan4res

## plan4res_install.sh
This script is used to install the plan4res software 

Requirements:
  plan4res_install.sh must be located within the directory in which you want to install plan4res
  If you want to install plan4res with CPLEX or GUROBI you must also copy in this directory the CPLEX installer for LINUX  (cplexXXX.bin) or the GUROBI installer for LINUX (gurobiXXX.tar.gz) and your GUROBI licence (gurobi.lic)

### Linux
From your terminal, type

  ./plan4res_install.sh [-S \<SOLVER\>] [-I \<installer\>] [-L \<license\>] [-v \<version\>] [-M \<mpi\>] [-U \<software\>] [-C] [-H]

        -S/--solver is optional, if not provided, HiGHS is chosen
        
           SOLVER can be: CPLEX, GUROBI, SCIP or HiGHS  (if not provided, HiGHS is chosen)
        
        -I/--installer is mandatory for CPLEX and GUROBI
        
            - for CPLEX : -I cplexinstaller.bin 
            
            - for GUROBI: -I gurobi.lic
        
        -L/--license is mandatory for GUROBI
        
            -L gurobi.lic
        
        -v/--version is optionnal and allows to choose the version if using SCIP (9.2.0 used if not provided)
   
            -v 9.2.0

        -D/--solverdir is optionnal ; it can only be used together with option -X. It allows to specify the location where the solver is already installed

            -D /solverpath

        -M/--mpi is optional, it is used to change the mpi version (default: OpenMPI)"	
        
            mpi can be: OpenMPI or MPICH
        
        -U/--update is optional. It is used to force the update of one of the softwares; if this option is not used and these solvers
            are already installed, they will not be updated.
        
            software can be: coin, stopt, sms++
            
            This option can be included many times (eg -U stopt -U coin)
        
        -X/--withoutp4renv : proceed to install without the p4r-env environment. In that case, the required software necessary for sms++ will be installed
        
        -B/--keepbuild : do not delete the .build directory where source code is downloaded and compilation done
        
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

## user_init_plan4res.sh
This script is used when plan4res is installed in a repository and the user wants to use it from another repository
In particular it is usefull when working on a server where plan4res is installed eg in a /softwares/ dir 
Each user will not need to install plan4res in their local dirs. The user will only need to run the user_init_plan4res script

this script will:
- update the environment variables P4R_DIR and P4R_DIR_LOCAL:
  - P4R_DIR is the location where plan4res is installed (ie p4r-env is in P4R_DIR)
  - P4R_DIR_LOCAL is the location where plan4res will be ran, ie where a directory data/ will be created, for storing the different datasets
- create the commands p4r and sp4r
  - p4r is the command for running plan4res
  - sp4r is the same command but for running in parallel with Slurm
- create the data/ directory in P4R_DIR_LOCAL and create within data an example of dataset: toyDataset

Requirements:
  user_init_plan4res.sh must be located within the directory in which you want to store your datasets and run plan4res
  plan4res must be installed

### Linux
From your terminal, type

  ./user_init_plan4res.sh [-D <INSTALLDIR>] [-S <SOLVER>]

        -D/--dir is mandatory
        
           INSTALLDIR is the directory where plan4res is installed (ie where p4r-env is located)

        -S/--solver is optional, if not provided, HiGHS is chosen
        
           SOLVER can be: CPLEX, GUROBI, SCIP or HiGHS  (if not provided, HiGHS is chosen)
           This is used to update the configuration files in data/toyDataset for the required solver

### Windows with Vagrant
Requirements:  same as for plan4res_install.sh

- Run Git Bash

- In a Git Bash terminal, type:   ./user_init_plan4res.sh [-D <INSTALLDIR>] [-S <SOLVER>]
