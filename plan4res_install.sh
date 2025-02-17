#!/bin/bash

INSTALLDIR=$(pwd)
configfile="$INSTALLDIR/p4r-env/config/plan4res.conf"
datestart=$(date +"%Y-%m-%d-%H:%M")
log_file="$INSTALLDIR/plan4resInstall_$datestart.log"
echo "Installing plan4res on $INSTALLDIR" | tee -a  "$log_file"
echo "starting $(date +"%Y-%m-%d-%H:%M")" | tee -a  "$log_file"
touch $log_file

test_option() {
	local code=$1
	local option=$2
	if [[ $option == --* ]] || [[ $option == -* ]] || [[ $option == "" ]]; then
		echo "Error: input not provided after $code" | tee -a "$log_file"
		exit 1
	fi
}

p4r() {
	export SINGULARITY_BIND=$INSTALLDIR/p4r-env
	cd $INSTALLDIR/p4r-env	
	bin/p4r python scripts/test.py | tee -a $log_file
	cd $INSTALLDIR
	return 0
}

usage() {
	echo "Usage: $0 [-S <SOLVER>] [-I <installer>] [-L <license>] [-v <version>] "
	echo "          [-U <software>] [-M <mpi>] [-V <memory>] [-X] [-C] [-B] [-H]"
	echo "Option -S is mandatory, it is used to specify which solver will be installed and used in SMS++"
	echo "       SOLVER can be : CPLEX, GUROBI, SCIP, or HiGHS"
	echo "Option -D means that the required solver is already installed in SOLVER_DIR "
	echo "       only useable with option -X"	
	echo "Option -I is used only with CPLEX and GUROBI"	
	echo "       It is mandatory if CPLEX or GUROBI needs to be installed"	
	echo "       installer is the linux installer file (cplex_xxx.bin or gurobiXXX.tar.gz)"	
	echo "Option -L is used only with GUROBI"	
	echo "       It is mandatory if GUROBI needs to be installed"	
	echo "       license is the gurobi licence file: gurobi.lic"	
	echo "Option -v is used only with SCIP"	
	echo "       this is optionnal, if not provided, scip 9.2.0 will be installed"	
	echo "       version is the SCIP version "	
	echo "Option -U is used to force update of coin, stopt and sms++"	
	echo "       it can be included many times"
	echo "       software can be: coin, stopt or sms++"	
	echo "Option -M is used to change the mpi version (default: OpenMPI)"	
	echo "       mpi is the MPI version: MPICH or OpenMPI"
	echo "Option -V means that the install is done on Windows with Vagrant"
	echo "       memory is the memory to be used by Vagrant (eg. 8192), it must be a multiple of 1024 "
	echo "Option -C means that everything will be uninstalled"
	echo "Option -B means that the build directory, where the source code is downloaded"
	echo "       and the compilation done, is not deleted after install "
	echo "Option -X means that the install will be done without the p4r-env environment"
	echo "       it means that all dependencies must be installed first "
	echo "Option -H prints this help"
	exit 0
}

clean() {
	echo "removing $INSTALLDIR/p4r-env" | tee -a "$log_file"
	rm -rf $INSTALLDIR/p4r-env
	echo "$INSTALLDIR/p4r-env removed" | tee -a "$log_file"
	return 0
}

change_mpi() {
	local MPIVERSION=$1
	if [[ ! -f $configfile ]]; then
		echo "error: $configfile does not exist" | tee -a "$log_file"
		exit 1
	fi
	echo "updating MPI version in $configfile, changing to $MPIVERSION" | tee -a "$log_file"
	sed -i.bak -E "s|P4R_MPI_IMP=\${P4R_MPI_IMP:-\"[^\"]*\"}|P4R_MPI_IMP=\${P4R_MPI_IMP:-\"$MPIVERSION\"}|" "$configfile"  
	echo "MPI version updated in $configfile, changed to $MPIVERSION" | tee -a "$log_file"  
}

p4r_env_installed() {
	if [[ (-d "$INSTALLDIR/p4r-env") && (-f "$INSTALLDIR/p4r-env/.cache_p4r/plan4res_$MPI.sif") && (-d "$INSTALLDIR/p4r-env/scripts") && (-f "$INSTALLDIR/p4r-env/scripts/test.py") ]]; then
		cd $INSTALLDIR/p4r-env
		pwd
		output=$(bin/p4r python scripts/test.py)
		if [ "$output"="OK" ]; then
			echo "p4r-env is installed in $INSTALLDIR" | tee -a "$log_file"
			return 0
		else
			echo "p4r-env is not installed in $INSTALLDIR" | tee -a "$log_file"
			return 1
		fi
	else
		echo "p4r-env is not installed in $INSTALLDIR" | tee -a "$log_file"
		return 1
	fi
}

stopt_installed() {
	if [[ -d "$INSTALLDIR/p4r-env/scripts/add-ons/install/stopt" ]]; then
		echo "stopt is installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 0
	else
		echo "stopt is NOT installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 1
	fi
}

sms_installed() {
	if [[ (-d "$INSTALLDIR/p4r-env/scripts/add-ons/install/sms++") && (-f "$INSTALLDIR/p4r-env/scripts/add-ons/install/sms++/bin/investment_solver") && (-f "$INSTALLDIR/p4r-env/scripts/add-ons/install/sms++/bin/sddp_solver") && (-f "$INSTALLDIR/p4r-env/scripts/add-ons/install/sms++/bin/ucblock_solver")]]; then
		echo "sms++ is installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 0
	else
		echo "sms++ is NOT installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 1
	fi
}

cplex_installed() {
	if [ -d "$INSTALLDIR/p4r-env/scripts/add-ons/install/cplex" ]; then
		echo "CPLEX is installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 0
	else
		echo "CPLEX is NOT installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 1
	fi
}

scip_installed() {
	if [ -d "$INSTALLDIR/p4r-env/scripts/add-ons/install/scip" ]; then
		echo "SCIP is installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 0
	else
		echo "SCIP is NOT installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 1
	fi
}

highs_installed() {
	if [ -d "$INSTALLDIR/p4r-env/scripts/add-ons/install/HiGHS" ]; then
		echo "HiGHS is installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 0
	else
		echo "HiGHS is NOT installed in $INSTALLDIR/p4r-env/scripts/add-ons/install/" | tee -a "$log_file"
		return 1
	fi
}

python_installed() {
	if [[ (-d "$INSTALLDIR/p4r-env/scripts/python/plan4res-scripts") &&  (-d "$INSTALLDIR/p4r-env/scripts/python/openentrance") ]]; then
		echo "python scripts are installed in $INSTALLDIR/p4r-env/scripts/python/" | tee -a "$log_file"
		return 0
	else
		echo "python scripts are NOT installed in $INSTALLDIR/p4r-env/scripts/python/" | tee -a "$log_file"
		return 1
	fi
}

include_installed() {
	if [ -d "$INSTALLDIR/p4r-env/scripts/include" ]; then
		echo "running scripts are installed in $INSTALLDIR/p4r-env/scripts/include/" | tee -a "$log_file"
		return 0
	else
		echo "running scripts are NOT installed in $INSTALLDIR/p4r-env/scripts/include" | tee -a "$log_file"
		return 1
	fi
}

SOLVER=""
INSTALLER=""
LICENSE=""
VAGRANT=""
MPI="OpenMPI"
STOPT_UPDATE=0
SMSPP_UPDATE=0
COIN_UPDATE=0
P4RENV_UPDATE=0
CPLEX_UPDATE=0
GUROBI_UPDATE=0
SCIP_UPDATE=0
HiGHS_UPDATE=0
version="9.2.0"
WITHOUT_P4R_ENV=0
KEEP_BUILD=0
SOLVER_DIR=""

# treat arguments
while [[ "$#" -gt 0 ]]; do
	case $1 in
		-S|--solver) 
			SOLVER=$2
			test_option $1 $2
			shift 2
			echo "install with solver $SOLVER" | tee -a "$log_file"
			;;
		-I|--installer) 
			INSTALLER=$2 
			test_option $1 $2
			shift 2
			echo "use installer $INSTALLER" | tee -a "$log_file"
		;;
		-v|--version) 
			version=$2 
			test_option $1 $2
			shift 2
			echo "install version $version" | tee -a "$log_file"
		;;
		-L|--license) 
			LICENSE=$2 
			test_option $1 $2
			shift 2
			echo "use license $LICENSE" | tee -a "$log_file"
		;;
		-D|--solverdir) 
			SOLVER_DIR=$2 
			test_option $1 $2
			shift 2
			echo "use solver installed in $DIR" | tee -a "$log_file"
		;;
		-V|--vagrant) 
			VAGRANT="VAGRANT"
			MEMORY=$2 
			test_option $1 $2
			echo "install with Vagrant, memory: $MEMORY" | tee -a "$log_file"
			shift 2
			;;
		-C|--clean) 
			echo "Remove previous install" | tee -a "$log_file"
			clean 
			exit 0
			;;
		-H|--help) 
			usage 
			;;
		-P|--p4r) 
			p4r 
			exit 0 
			;;
		-M|--mpi) 
			MPI=$2 
			test_option $1 $2
			echo "Install with $MPI" | tee -a "$log_file"
			change_mpi "$MPI"
			shift 2 
			;;
		-U|--update)
			test_option $1 $2
			what=$2
			if [ "$what" = "stopt" ]; then STOPT_UPDATE=1 ; fi
			if [ "$what" = "sms++" ]; then SMSPP_UPDATE=1 ; fi
			if [ "$what" = "coin" ]; then COIN_UPDATE=1 ; fi
			if [ "$what" = "p4r-env" ]; then P4RENV_UPDATE=1 ; fi
			if [ "$what" = "CPLEX" ]; then CPLEX_UPDATE=1 ; fi
			if [ "$what" = "GUROBI" ]; then GUROBI_UPDATE=1 ; fi
			if [ "$what" = "SCIP" ]; then SCIP_UPDATE=1 ; fi
			if [ "$what" = "HiGHS" ]; then HiGHS_UPDATE=1 ; fi
			shift 2 
			;;
		-X|--withoutp4renv)
			WITHOUT_P4R_ENV=1
			shift
			;;
		-B|--keepbuild)
			KEEP_BUILD=1
			shift
			;;			
		*) 
			echo "unknown option $1" | tee -a "$log_file"
			usage 
			;;
	esac
done

# install p4r-env
if [ "${WITHOUT_P4R_ENV}" = "0" ]; then
	export P4R_ENV=$INSTALLDIR/p4r-env/bin/p4r
	export SINGULARITY_BIND=$INSTALLDIR/p4r-env
	if p4r_env_installed; then
		echo "p4r-env already installed" | tee -a "$log_file"
		if [ "${P4RENV_UPDATE}" = "1" ]; then
			echo "updating p4r-env" | tee -a "$log_file"
			cd $INSTALLDIR/p4r-env
			git pull
			# edit config/plan4res.conf to allow download of sif image 
			echo "Updating $configfile to allow download of SIF image" >> "$log_file"
			sed -i '/P4R_SINGULARITY_IMAGE_PRESERVE=1/ s/^/#/' "$configfile"	
			sed -i '/P4R_SINGULARITY_IMAGE_PRESERVE=0/ s/^#//' "$configfile"  
			grep -qxF 'P4R_SINGULARITY_IMAGE_PRESERVE=0' "$configfile" || echo 'P4R_SINGULARITY_IMAGE_PRESERVE=1' >> "$configfile" 
			echo "$configfile updated" >> "$log_file"
			echo "updating p4r-env SIF image" | tee -a "$log_file"
			p4r
			echo "p4r-env SIF image updated" | tee -a "$log_file"
			# edit config/plan4res.conf to prevent download of sif image at each bin/p4r launch
			echo "Updating $configfile to prevent download of SIF image" >> "$log_file"
			sed -i '/P4R_SINGULARITY_IMAGE_PRESERVE=0/ s/^/#/' "$configfile"	
			sed -i '/P4R_SINGULARITY_IMAGE_PRESERVE=1/ s/^#//' "$configfile"  
			grep -qxF 'P4R_SINGULARITY_IMAGE_PRESERVE=1' "$configfile" || echo 'P4R_SINGULARITY_IMAGE_PRESERVE=1' >> "$configfile" 
			echo "$configfile updated" >> "$log_file"
		fi
	else
		echo "installing p4r-env" | tee -a "$log_file"
		if [[ -d $INSTALLDIR/p4r-env ]]; then 
			echo "p4r-env exists, removing...." >> "$log_file"
			rm -rf $INSTALLDIR/p4r-env 
			echo "p4r-env removed...." >> "$log_file"
		fi
		echo "cloning p4r-env...." >> "$log_file"
		git clone --recursive https://github.com/plan4res/p4r-env | tee -a $log_file
		wait
		echo "p4r-env cloned" >> "$log_file"
		export SINGULARITY_BIND=$INSTALLDIR/p4r-env
		cd $INSTALLDIR/p4r-env
		if [ "$VAGRANT" = "VAGRANT" ]; then
			echo "Install plan4res with VAGRANT, requested memory: $MEMORY" | tee -a "$log_file"
			if [[ -n $MEMORY ]]; then
				if ! [[ $MEMORY =~ ^[0-9]+$ ]]; then
					echo "Error : Option -V <memory> must be an integer, multiple of 1024." | tee -a "$log_file"
					exit 1
				fi
				if (( MEMORY % 1024 != 0 )); then
					echo "Error : Option -V <memory> must be a multiple of 1024." | tee -a "$log_file"
					exit 1
				fi
			fi
			echo "installing with Vagrant" | tee -a "$log_file"
			vagrantfile="$INSTALLDIR/p4r-env/Vagrantfile"
			sed -i 's/vb.memory = "[0-9]\+"/vb.memory = "'"$MEMORY"'"/' "$vagrantfile"
			echo "Vagrantfile updated, memory requested: $MEMORY" | tee -a "$log_file"
			echo "installing vagrant-proxyconf" | tee -a "$log_file"
			vagrant plugin install vagrant-proxyconf
			wait
			echo "vagrant-proxyconf installed, starting Vagrant Virtual Machine" | tee -a "$log_file"
			vagrant up 
			echo "VM started" | tee -a "$log_file"
		fi
		git config submodule.recurse true
		echo "downloading p4r-env SIF image" | tee -a "$log_file"
		p4r
		echo "p4r-env SIF image downloaded" | tee -a "$log_file"

		# edit config/plan4res.conf to prevent download of sif image at each bin/p4r launch
		# comment row P4R_SINGULARITY_IMAGE_PRESERVE=0
		# uncomment row P4R_SINGULARITY_IMAGE_PRESERVE=1
		# add row P4R_SINGULARITY_IMAGE_PRESERVE=1 if not present
		echo "Updating $configfile to prevent download of SIF image" >> "$log_file"
		sed -i '/P4R_SINGULARITY_IMAGE_PRESERVE=0/ s/^/#/' "$configfile"	
		sed -i '/P4R_SINGULARITY_IMAGE_PRESERVE=1/ s/^#//' "$configfile"  
		grep -qxF 'P4R_SINGULARITY_IMAGE_PRESERVE=1' "$configfile" || echo 'P4R_SINGULARITY_IMAGE_PRESERVE=1' >> "$configfile" 
		echo "$configfile updated" >> "$log_file"
		cd $INSTALLDIR
		echo "p4r-env successfully installed" | tee -a "$log_file"
	fi
else
	echo "Install without p4r-env" | tee -a "$log_file"
	if [ ! -d $INSTALLDIR/p4r-env ] ; then mkdir $INSTALLDIR/p4r-env ; fi
	if [ ! -d $INSTALLDIR/p4r-env/add-ons ] ; then mkdir $INSTALLDIR/p4r-env/add-ons ; fi
	if [ ! -d $INSTALLDIR/p4r-env/scripts ] ; then mkdir $INSTALLDIR/p4r-env/scripts ; fi
fi

# check SOLVER
if [[ "$SOLVER" != "" && "$SOLVER" != "CPLEX" && "$SOLVER" != "GUROBI" && "$SOLVER" != "SCIP" && "$SOLVER" != "HiGHS" ]]; then
	echo "Error : SOLVER must be among : CPLEX, GUROBI, SCIP, HiGHS." | tee -a "$log_file"
	usage
fi

SolverFlag=""
# Check solvers requirements
if [[ $SOLVER == "CPLEX" || $SOLVER == "GUROBI" ]]; then
	SolverFlag+="--without-scip --without-highs "
	if [ $SOLVER == "CPLEX" ]; then SolverFlag+="--without-gurobi "; else SolverFlag+="--without-cplex "; fi
	# is solver already installed?
	INSTALLED=0
	if [ "$WITHOUT_P4R_ENV" = "0" ]; then
		# cas in p4r-env
		if [ $SOLVER == "CPLEX" ]; then
			if cplex_installed; then INSTALLED=1 ; fi
		fi
		if [ $SOLVER == "GUROBI" ]; then
			if gurobi_installed; then INSTALLED=1 ; fi
		fi
	else
		if [ "$SOLVER_DIR" != "" ]; then 
			INSTALLED=1; 
			# in the case without p4r-env, pass solver path if already installed
			if [ "$SOLVER" = "CPLEX" ]; then SolverFlag+="--cplex-root=$SOLVER_DIR "; fi
			if [ "$SOLVER" = "GUROBI" ]; then SolverFlag+="--gurobi-root=$SOLVER_DIR "; fi
		fi	
	fi	
	if [ "$INSTALLED" = "0" ]; then 
		# solver is not installed, installer and license required
		if [[ -z $INSTALLER ]] ; then
			echo "Error : Option -L <INSTALLER> is mandatory for $SOLVER." | tee -a "$log_file"
			usage
		fi
		if [[ $SOLVER == "CPLEX" && $INSTALLER != *.bin ]]; then
			echo "Error : a .bin file is needed for CPLEX" | tee -a "$log_file"
			usage
		elif [[ $SOLVER == "GUROBI" && $INSTALLER != *.tar.gz ]]; then
			echo "Error : a .tar.gz file s needed for $SOLVER." | tee -a "$log_file"
			usage
		fi
		if [[ $SOLVER == "CPLEX" ]]; then
			if [ -f "$INSTALLDIR/$INSTALLER" ] ; then
				echo "CPLEX installer: $INSTALLER found, copying to p4r-env" | tee -a "$log_file"
				cp "$INSTALLDIR/$INSTALLER" $INSTALLDIR/p4r-env/
				SolverFlag+="--cplex-installer=$INSTALLER "
			else
				echo "Error: CPLEX installer $INSTALLDIR/$INSTALLER not found" | tee -a "$log_file"
				exit 1
			fi
		elif [[ $SOLVER == "GUROBI" ]]; then
			if [ -f "$INSTALLDIR/$INSTALLER" ] ; then
				echo "GUROBI installer $INSTALLDIR/$INSTALLER found, copying to p4r-env" | tee -a "$log_file"
				cp "$INSTALLDIR/$INSTALLER" $INSTALLDIR/p4r-env/
				if [ -f "$INSTALLDIR/$LICENSE" ] ; then
					echo "GUROBI license $INSTALLDIR/$LICENSE found, copying to p4r-env" | tee -a "$log_file"
					cp "$INSTALLDIR/$LICENSE" $INSTALLDIR/p4r-env/
					SolverFlag+="--gurobi-installer=$INSTALLER --gurobi-license=$LICENSE "
				else
					echo "Error: GUROBI license $INSTALLDIR/$LICENSE not found" | tee -a "$log_file"
					exit 1
				fi
			else
				echo "Error: GUROBI installer $INSTALLDIR/$INSTALLER not found" | tee -a "$log_file"
				exit 1
			fi
		fi
	fi
elif [[ ($SOLVER == "SCIP") || ($SOLVER == "HiGHS") ]]; then
	SolverFlag+="--without-cplex --without-gurobi "
	if [ "$SOLVER" = "SCIP" ]; then
		SolverFlag+="--without-highs "
		SolverFlag+="--scip-version=$version "
		if [ "$WITHOUT_P4R_ENV" = "1" ] && [ "$SOLVER_DIR" != "" ]; then SolverFlag+="--scip-root=$SOLVER_DIR "; fi
	elif [ "$SOLVER" = "HiGHS" ]; then
		SolverFlag+="--without-scip "
		if [ "$WITHOUT_P4R_ENV" = "1" ] && [ "$SOLVER_DIR" != "" ]; then SolverFlag+="--highs-root=$SOLVER_DIR "; fi
	fi 

	# Ignore option -L for SCIP and HIGHS
	if [[ -n $INSTALLER ]]; then
		echo "Warning : option -I $INSTALLER is ignored for $SOLVER." | tee -a "$log_file"
	fi
fi
if [ "$WITHOUT_P4R_ENV" = "0"  ]; then SolverFlag+="--without-linux-update "; fi
SolverFlag+="--without-smspp --without-interact "
if [ "${STOPT_UPDATE}" = "0" ]; then SolverFlag+="--without-stopt-update " ; fi
if [ "${SMSPP_UPDATE}" = "0" ]; then SolverFlag+="--without-smspp-update " ; fi
if [ "${COIN_UPDATE}" = "0" ]; then SolverFlag+="--without-coin-update " ; fi
SolverFlag+="--build-root=$INSTALLDIR/p4r-env/scripts/add-ons/.build --install-root=$INSTALLDIR/p4r-env/scripts/add-ons/install"



# if cplex update requested, remove cplex install dir
if [ "${CPLEX_UPDATE}" = "1" ]; then
	if [ -d $INSTALLDIR/p4r-env/scripts/add-ons/install/cplex ]; then
		rm -rf $INSTALLDIR/p4r-env/scripts/add-ons/install/cplex
	fi
fi

# if gurobi update requested, remove gurobi install dir
if [ "${GUROBI_UPDATE}" = "1" ]; then
	if [ -d $INSTALLDIR/p4r-env/scripts/add-ons/install/gurobi ]; then
		rm -rf $INSTALLDIR/p4r-env/scripts/add-ons/install/gurobi
	fi
fi

# if cplex update requested, remove cplex install dir
if [ "${HiGHS_UPDATE}" = "1" ]; then
	if [ -d $INSTALLDIR/p4r-env/scripts/add-ons/install/HiGHS ]; then
		rm -rf $INSTALLDIR/p4r-env/scripts/add-ons/install/HiGHS
	fi
fi

# if cplex update requested, remove cplex install dir
if [ "${SCIP_UPDATE}" = "1" ]; then
	if [ -d $INSTALLDIR/p4r-env/scripts/add-ons/install/scip ]; then
		rm -rf $INSTALLDIR/p4r-env/scripts/add-ons/install/scip
	fi
fi

if ! sms_installed; then
	cd $INSTALLDIR/p4r-env
	if [ -d $INSTALLDIR/p4r-env/scripts/add-ons/install/sms++ ]; then
		echo "sms++ is present in $INSTALLDIR but not correctly installed" | tee -a "$log_file"
		echo "removing sms++" | tee -a "$log_file"
		rm -rf $INSTALLDIR/p4r-env/scripts/add-ons/install/sms++ | tee -a "$log_file"
		if [ -d $INSTALLDIR/p4r-env/scripts/add-ons/.build/smspp-project ]; then
			rm -rf $INSTALLDIR/p4r-env/scripts/add-ons/.build/smspp-project | tee -a "$log_file"
		fi
		wait
		echo "sms++ successfully uninstalled" | tee -a "$log_file"
	fi
fi

echo "installing/updating sms++ "
cd $INSTALLDIR/p4r-env
cp $INSTALLDIR/INSTALL.sh $INSTALLDIR/p4r-env/
chmod a+x $INSTALLDIR/p4r-env/INSTALL.sh
if [ "${WITHOUT_P4R_ENV}" = "0" ]; then
	${P4R_ENV} ./INSTALL.sh $SolverFlag
	wait
else
	./INSTALL.sh $SolverFlag
	wait
fi
cd $INSTALLDIR
if sms_installed; then
	echo "sms++ successfully installed with $SOLVER" | tee -a "$log_file"
	if [ "$KEEP_BUILD" = "0" ]; then 
		rm -rf $INSTALLDIR/p4r-env/scripts/add-ons/.build
	fi
else
	echo "Error: sms++ install failed" | tee -a "$log_file"
fi

# install python scripts
if python_installed; then
	echo "python scripts already installed"
	cd $INSTALLDIR/p4r-env/scripts/python/plan4res-scripts
	git pull | tee -a "$log_file"
	wait
	cd $INSTALLDIR/p4r-env/scripts/python/openentrance
	git pull | tee -a "$log_file"
	wait
	cd $INSTALLDIR
else
	echo "installing python scripts" | tee -a "$log_file"
	cd $INSTALLDIR/p4r-env/scripts
	if [[ ! -d "$INSTALLDIR/p4r-env/scripts/python" ]]; then mkdir python; fi
	cd python
	if [ -d "$INSTALLDIR/p4r-env/scripts/python/plan4res-scripts" ]; then
		cd plan4res-scripts
		git pull | tee -a "$log_file"
	else
		git clone https://github.com/plan4res/plan4res-scripts | tee -a "$log_file"
	fi
	wait
	if [ -d "$INSTALLDIR/p4r-env/scripts/python/openentrance" ]; then
		cd openentrance
		git pull | tee -a "$log_file"
	else
		git clone https://github.com/openENTRANCE/openentrance | tee -a "$log_file"
	fi
	wait
	cd $INSTALLDIR
fi
echo "python scripts successfully installed" | tee -a "$log_file"

# install scripts for running plan4res
if include_installed; then
	echo "running scripts already installed, updating...." | tee -a "$log_file"
	cd $INSTALLDIR/p4r-env/scripts/include
	git pull | tee -a "$log_file"
	wait
	cd $INSTALLDIR 
else
	echo "installing running scripts" | tee -a "$log_file"
	cd $INSTALLDIR/p4r-env/scripts
	git clone https://github.com/plan4res/include | tee -a "$log_file"
	wait
	cd $INSTALLDIR
fi
cd $INSTALLDIR/p4r-env/scripts/include
chmod a+x *.sh
cd $INSTALLDIR

if [ ! -d $INSTALLDIR/p4r-env/data/toyDataset ]; then
	echo " Create example dataset toyDataset "
	cd $INSTALLDIR/p4r-env/data/data
	git clone https://github.com/plan4res/toyDataset
fi	

if [ -d $INSTALLDIR/documentation ]; then
	echo " Update documentation "
	cd $INSTALLDIR/documentation
	git pull	
else									
	echo " Get documentation "
	cd $INSTALLDIR
	git clone https://github.com/plan4res/documentation
fi											  

echo "update environment variables and create plan4res commands"
cd $INSTALLDIR
if [ -f user_init_plan4res.sh ]; then
	chmod a+x user_init_plan4res.sh
	./user_init_plan4res.sh "$INSTALLDIR"
else
	echo "the script user_init_plan4res.sh is not present in $INSTALLDIR"
	echo "You need to move to the location where you want to store your data"
	echo "and run ./user_init_plan4res.sh <INSTALLDIR>"
	echo "<INSTALLDIR> is the location where you ran plan4res_install.sh"
fi

echo "plan4res install completed" | tee -a "$log_file"
