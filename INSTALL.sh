#!/bin/bash

# ------------------------------------------------------------------------------
# SYNOPSIS
#     This script installs SMS++ and all its dependencies on Unix-based systems.
#
# DESCRIPTION
#     This script performs the installation of SMS++ and all its dependencies
#     on Unix-based systems. If not already present, it clones the smspp-project
#     repositories, then builds and installs them.
#
#     You can use the `--install-root=<your-custom-path>` option to specify your custom installation root.
#     You can use the `--without-cplex` option to skip the installation of CPLEX.
#     You can use the `--without-gurobi` option to skip the installation of Gurobi.
#
# options:
# 			--install-root=<your-custom-path>  : option to specify your custom installation root
# 			--build-root=<your-custom-path>  : option to specify your custom download and build root
# 			--without-linux-update  # forbid update of linux packages 
#	     	--without-scip  # do not install SCIP
#	   		--without-highs # do not install HiGHS
#	   		--without-cplex # do not install CPLEX
#	   		--without-gurobi # do not install GUROBI
#			--without-smspp   # prevents install of complete smspp and chooses only modules for plan4res
#			--without-stopt-update   # do not update stopt if already installed
#			--without-coin-update   # do not update coin if already installed 
#			--without-smspp-update   # do not pull sms++ if already installed
#			--without-interact  # prevents use of xterm (interactive mode)
#			--cplex-installer=<your-cplex-installer>   # allows user to pass his own cplex installer and prevent download
#			--gurobi-installer=<your-gurobi-installer>  # allows user to pass his own gurobi installer and prevent download
#			--gurobi-license=<your-gurobi-installer> # allows user to pass his own gurobi licence with the installer
#			--scip-version=<scip-version> # allows user to choose the version of SCIP
#			--cplex-root=<your cplex install rool> # if cplex is already installed somewhere, you can specify it
#			--gurobi-root=<your gurobi install rool> # if gurobi is already installed somewhere, you can specify it
#			--scip-root=<your scip install rool> # if scip is already installed somewhere, you can specify it
#			--highs-root=<your highs install rool> # if highs is already installed somewhere, you can specify it
#			--coin-root=<your coin install rool> # if coin is already installed somewhere, you can specify it
#
# AUTHOR
#     Donato Meoli, Sandrine Charousset
#
# EXAMPLES
#     If you are inside the cloned repository:
#
#         sudo ./INSTALL.sh --install-root=<your-custom-path>
#
#     or:
#
#         sudo ./INSTALL.sh --install-root=<your-custom-path> --without-cplex --without-gurobi
#
#     if you do not have a CPLEX and/or Gurobi license, or if you just want to install SMS++ without them.
#
#     If you have not yet cloned the SMS++ repository, you can run the script directly:
#
#     Using `curl`:
#
#         If you want to install SMS++ with all dependencies:
#
#             curl -s https://gitlab.com/smspp/smspp-project/-/raw/develop/INSTALL.sh | sudo bash -s -- --install-root=<your-custom-path>
#
#         or:
#
#             curl -s https://gitlab.com/smspp/smspp-project/-/raw/develop/INSTALL.sh | sudo bash -s -- --install-root=<your-custom-path> --without-cplex --without-gurobi
#
#        if you do not have a CPLEX and/or Gurobi license, or if you just want to install SMS++ without them.
#
#     Using `wget`:
#
#         If you want to install SMS++ with all dependencies:
#
#             wget -qO- https://gitlab.com/smspp/smspp-project/-/raw/develop/INSTALL.sh | sudo bash -s -- --install-root=<your-custom-path>
#
#         or:
#
#             wget -qO- https://gitlab.com/smspp/smspp-project/-/raw/develop/INSTALL.sh | sudo bash -s -- --install-root=<your-custom-path> --without-cplex --without-gurobi
#
#         if you do not have a CPLEX and/or Gurobi license, or if you just want to install SMS++ without them.
# ------------------------------------------------------------------------------


# Function to install dependencies on Linux 
install_on_linux() {
	set -e  # Exit immediately if a command exits with a non-zero status
	echo "Starting the installation process on Linux..."
   
   # update linux packages only if user has sudo AND it is requested by user
	if [[ "$HAS_SUDO" = "1" && "$update_linux" = "1" ]]; then
		# Update packages and install basic requirements
		echo "Updating system and installing basic requirements..."
		apt-get update -q
		apt-get install -y -q build-essential clang cmake cmake-curses-gui git curl xterm

		# Install Boost libraries
		echo "Installing Boost libraries..."
		apt-get install -y -q libboost-dev libboost-system-dev libboost-timer-dev libboost-mpi-dev libboost-random-dev

		# Install OpenMP
		echo "Installing OpenMP..."
		apt-get install -y -q libomp-dev

		# Install Eigen
		echo "Installing Eigen..."
		apt-get install -y -q libeigen3-dev

		# Install NetCDF-C++
		echo "Installing NetCDF-C++..."
		apt-get install -y -q libnetcdf-c++4-dev
	fi
	
	# Install CPLEX
	#CPLEX_ROOT="${INSTALL_ROOT}/ibm/ILOG/CPLEX_Studio"
	if [ "${CPLEX_ROOT}"="" ]; then CPLEX_ROOT="${INSTALL_ROOT}/cplex"; fi
	# only install if requested and not yet installed
	if [ "$install_cplex" -eq 1 ] && [ ! -d $CPLEX_ROOT ]; then
		echo "Installing CPLEX..."
		
		cd "$INSTALL_ROOT"
		# if the user passes the installer then this one is used instead of the version here																					   
		if [ ! "$cplex_installer" = "" ]; then
			cplex_installer=$cplex_installer
		else
			cplex_installer="cplex_studio2211.linux_x86_64.bin"
		fi
		# the CPLEX_URL is always given by the same prefix, i.e.:
		# "https://drive.usercontent.google.com/download?id=" +
		# the id code suffix in the Drive sharing link, i.e.:
		# https://drive.google.com/file/d/ 12JpuzOAjnuQK6tq2LLolIgmlmKTmOP4x /view?usp=sharing
		if [ "$cplex_installer" = "" ]; then
			CPLEX_URL="https://drive.usercontent.google.com/download?id=12JpuzOAjnuQK6tq2LLolIgmlmKTmOP4x"
			uuid=$(curl -sL "$CPLEX_URL" | grep -oE 'name="uuid" value="[^"]+"' | cut -d '"' -f 4)
			if [ -n "$uuid" ]; then
				curl -o "$cplex_installer" "$CPLEX_URL&export=download&authuser=0&confirm=t&uuid=$uuid"
				chmod u+x "$cplex_installer"
				cat <<EOL > installer.properties
INSTALLER_UI=silent
LICENSE_ACCEPTED=TRUE
USER_INSTALL_DIR=$CPLEX_ROOT
EOL
				./"$cplex_installer" -f ./installer.properties &
				wait $! # wait for CPLEX installer to finish
				INSTALLER_EXIT_CODE=$?
				if [ $INSTALLER_EXIT_CODE -eq 0 ]; then
					rm "$cplex_installer" installer.properties
					#mv ./ibm/ILOG/CPLEX_Studio2211 "$CPLEX_ROOT"
					export CPLEX_HOME="${CPLEX_ROOT}/cplex"
					export PATH="${PATH}:${CPLEX_HOME}/bin/x86-64_linux"
					export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${CPLEX_HOME}/lib/x86-64_linux"
					if [[ "$HAS_SUDO" -eq 1 && "$update_linux" -eq 1 ]]; then
						sh -c "echo '${CPLEX_HOME}/lib/x86-64_linux' > /etc/ld.so.conf.d/cplex.conf"
						ldconfig
					else
						rm -R javasharedresources
					fi
				else
					echo "CPLEX installation failed with exit code $INSTALLER_EXIT_CODE."
					exit 1
				fi
			else
				echo "Error: unable to find the UUID value in the response. The CPLEX download link could not be constructed."
				exit 1
			fi
		else
		# install using the user's installer instead of downloading
			cat <<EOL > installer.properties
INSTALLER_UI=silent
LICENSE_ACCEPTED=TRUE
USER_INSTALL_DIR=$CPLEX_ROOT
CHECK_DISK_SPACE=OFF
EOL
			if [ -f "$cplex_installer" ]; then
				chmod +x $cplex_installer
				./"$cplex_installer" -f ./installer.properties &
				wait $! # wait for CPLEX installer to finish
				INSTALLER_EXIT_CODE=$?
				if [ $INSTALLER_EXIT_CODE -eq 0 ]; then
					rm installer.properties
					rm "$cplex_installer" 
					echo "CPLEX installation succeeded"
				else
					echo "CPLEX installation failed with exit code $INSTALLER_EXIT_CODE."
					exit 1
				fi
			else
				echo "Cplex installer does not exist"
				exit 1
			fi
		fi
	else
		echo "CPLEX already installed or not requested to be installed."
	fi

	# Install Gurobi
	# if the user passes his own installer then this version is used instead of 10.0
	if [ "${GUROBI_ROOT}"="" ]; then GUROBI_ROOT="${INSTALL_ROOT}/gurobi" ; fi
	if [ "$install_gurobi" -eq 1 ]; then							 
		if [ ! "$gurobi_installer" = "" ]; then
			GUROBI_INSTALLER=$gurobi_installer
			GRBDIR=$(tar tzf "$GUROBI_INSTALLER" | head -1 | cut -f1 -d"/")
		elif [ -d "$GUROBI_ROOT" ]; then
			for file in ${GUROBI_ROOT}/*/ ; do 
				if [[ -d "$file" && ! -L "$file" ]]; then
					grb="${file%/}" 
					grb="${grb##*/}"
				fi
			done
			echo "version $grb of gurobi found"
			GRBDIR=$grb
		else
			GUROBI_INSTALLER="gurobi10.0.3_linux64.tar.gz"
			GRBDIR=$(tar tzf "$GUROBI_INSTALLER" | head -1 | cut -f1 -d"/")
		fi
		GUROBI_HOME="${GUROBI_ROOT}/$GRBDIR/linux64"
	fi
	# install gurobi only if requested and not already installed
	if [ "$install_gurobi" -eq 1 ] && [ ! -d "$GUROBI_ROOT/$GRBDIR" ]; then
		echo "Installing Gurobi..."					 
        cd "$INSTALL_ROOT"
		if [ ! -d ${GUROBI_ROOT} ]; then mkdir ${IGUROBI_ROOT} ; fi
		if [ "$gurobi_installer" = "" ]; then
			curl -O "https://packages.gurobi.com/10.0/$GUROBI_INSTALLER"
			tar -xvf "$GUROBI_INSTALLER"
			rm "$GUROBI_INSTALLER"
			mv ./gurobi1003 "$GUROBI_ROOT"
			export GUROBI_HOME="${GUROBI_ROOT}/$GRBDIR/linux64"
			export PATH="${PATH}:${GUROBI_HOME}/bin"
			export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
			if [ "$HAS_SUDO" -eq 1 ]; then
				sh -c "echo '${GUROBI_HOME}/lib' > /etc/ld.so.conf.d/gurobi.conf"
				ldconfig
			fi
		else
			if [ -f "$GUROBI_INSTALLER" ] && [ -f "$gurobi_license" ] ; then
				cd $INSTALL_ROOT
				tar xvf $GUROBI_INSTALLER
				export GUROBI_HOME="${GUROBI_ROOT}/$GRBDIR/linux64"
				export PATH="${PATH}:${GUROBI_HOME}/bin"
				export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
				export GRB_LICENSE_FILE=${GUROBI_ROOT}/$GRBDIR/gurobi.lic
				mv ./$GRBDIR "$GUROBI_ROOT"
				mv $gurobi_license $GUROBI_ROOT/$GRBDIR
				
				rm -rf $INSTALL_ROOT/$GUROBI_INSTALLER
			else
				echo "Gurobi license or installer does not exist"
				exit 1
			fi
		fi
    else
		echo "Gurobi already installed or not requested to be installed."
    fi

	# Install SCIP
	echo "Installing SCIP...  "
	if  [ "${SCIP_ROOT}" = "" ]; then SCIP_ROOT="${INSTALL_ROOT}/scip" ; fi
	SCIP_BUILD_ROOT="${BUILD_ROOT}/scip"
	# install only if requested and not already installed
	if [ "$install_scip" -eq 1 ] &&  [ ! -d $SCIP_ROOT ]; then
		if [[ "$HAS_SUDO" -eq 1 && "$update_linux" -eq 1 ]]; then
		  apt-get install -y -q gfortran libtbb-dev
		fi
		cd "$BUILD_ROOT"
		# we could also add a --scip-version to allow the user chosing the scip version....
		SCIP_INSTALLER="scip-"+"$scip_version"
		curl -O "https://www.scipopt.org/download/release/$SCIP_INSTALLER.tgz"
		tar xvzf "$SCIP_INSTALLER.tgz"
		rm "$SCIP_INSTALLER.tgz"
		if [ -d $SCIP_BUILD_ROOT ]; then rm -rf $SCIP_BUILD_ROOT ; fi
		if [ ! -d $SCIP_ROOT ]; then mkdir $SCIP_ROOT ; fi
		mv ./"$SCIP_INSTALLER" "$SCIP_BUILD_ROOT"
		cd "$SCIP_BUILD_ROOT"
		cmake -S . -B build -DCMAKE_INSTALL_PREFIX="$SCIP_ROOT" -DAUTOBUILD=ON
		cmake --build build 
		cmake --install build --prefix "$SCIP_ROOT"
		# i do have sudo on the container but the ld_config does not work.....
		if [[ "$HAS_SUDO" -eq 1 && "$update_linux" -eq 1 ]]; then
		  sh -c "echo '${SCIP_ROOT}/lib' > /etc/ld.so.conf.d/scip.conf"
		  ldconfig
		fi
	else
		echo "SCIP already installed or not requested to be installed."
	fi

	# Install HiGHS
	# install only if requested and not already installed
	echo "Installing HiGHS......  "
	if  [ "${HiGHS_ROOT}" = "" ]; then HiGHS_ROOT="${INSTALL_ROOT}/HiGHS"; fi
	HiGHS_BUILD_ROOT="${BUILD_ROOT}/HiGHS"
	if [ "$install_highs" -eq 1 ] && [ ! -d $HiGHS_ROOT ]; then
		cd "$BUILD_ROOT"
		if [ ! -d ${BUILD_ROOT}/HiGHS ]; then
			git clone https://github.com/ERGO-Code/HiGHS.git
		else
			git pull
		fi
		cd HiGHS
		cmake -S . -B build -DFAST_BUILD=ON -DCMAKE_INSTALL_PREFIX="$HiGHS_ROOT"
		cmake --build build
		cmake --install build --prefix "$HiGHS_ROOT"
		if [[ "$HAS_SUDO" -eq 1 && "$update_linux" -eq 1 ]]; then
			sh -c "echo '${HiGHS_ROOT}/lib' > /etc/ld.so.conf.d/highs.conf"
			ldconfig
		fi	
	else
		echo "HiGHS already installed or not requested to be installed."
	fi
 
	# Install COIN-OR CoinUtils and Osi/Clp
	echo "Installing COIN-OR CoinUtils and Osi/Clp... sudo=$HAS_SUDO"
	if [[ "$HAS_SUDO" -eq 1 && "$update_linux" -eq 1 ]]; then
		apt-get install -y -q coinor-libcoinutils-dev libbz2-dev liblapack-dev libopenblas-dev
	fi
	if  [ "${CoinOr_ROOT}" = "" ]; then CoinOr_ROOT="${INSTALL_ROOT}/coin-or" ; fi
	CoinOr_BUILD_ROOT="${BUILD_ROOT}/coin-or"
	# install only if not already installed
	# to be added "update coin"
	if [ ! -d $CoinOr_ROOT ] || [ $update_coin -eq 1 ]; then
		cd "$BUILD_ROOT"
		curl -O https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew
		chmod u+x coinbrew 
		# Build CoinUtils in BUILD_ROOT, install in CoinOr_ROOT
		./coinbrew build CoinUtils --latest-release --skip-dependencies --prefix="$CoinOr_ROOT" --tests=none
		# Build Osi with or without CPLEX
		osi_build_flags=(
			"--latest-release"
			"--skip-dependencies"
			"--prefix=$CoinOr_ROOT"
			"--tests=none"
		)
		if [ "$install_cplex" -eq 0 ]; then
			osi_build_flags+=("--without-cplex")
		else
			osi_build_flags+=(
				"--with-cplex"
				"--with-cplex-lib=-L${CPLEX_ROOT}/cplex/lib/x86-64_linux/static_pic -lcplex -lpthread -lm -ldl"
				"--with-cplex-incdir=${CPLEX_ROOT}/cplex/include/ilcplex"
			)
		fi
		# Build Osi with or without Gurobi
		if [ "$install_gurobi" -eq 0 ]; then
			osi_build_flags+=("--without-gurobi")
		else
			gurobiflag=$(echo $gurobi_installer | sed -E 's/gurobi([0-9]+)\.([0-9]+)\..*/lgurobi\1\2/')
			osi_build_flags+=(
				"--with-gurobi"
				"--with-gurobi-lib=-L${GUROBI_HOME}/lib -${gurobiflag}"
				"--with-gurobi-incdir=${GUROBI_HOME}/include"
			)
			
		fi
		./coinbrew build Osi "${osi_build_flags[@]}"
		# Build Clp
		./coinbrew build Clp --latest-release --skip-dependencies --prefix="$CoinOr_ROOT" --tests=none
		rm -Rf coinbrew build CoinUtils Osi Clp
		export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${CoinOr_ROOT}/lib"
		if [[ "$HAS_SUDO" -eq 1 && "$update_linux" -eq 1 ]]; then
			sh -c "echo '${CoinOr_ROOT}/lib' > /etc/ld.so.conf.d/coin-or.conf"
			ldconfig
		fi
		rm -rf ${CoinOr_BUILD_ROOT}
	else
		echo "COIN-OR already installed."
	fi

	# Install StOpt
	echo "Installing StOpt..."
	StOpt_ROOT="${INSTALL_ROOT}/StOpt"
	if [[ "$HAS_SUDO" -eq 1 && "$update_linux" -eq 1 ]]; then
		apt-get install -y -q zlib1g-dev
	fi
	if [ ! -d $StOpt_ROOT ]; then
		if [ -d $BUILD_ROOT/StOpt ]; then rm -rf $BUILD_ROOT/StOpt ; fi
		cd $BUILD_ROOT
		git clone https://gitlab.com/stochastic-control/StOpt.git $BUILD_ROOT/StOpt
		cd $BUILD_ROOT/StOpt
		# with debian:bullseye the versions of boost and eigen are not good so we
		# must install with wget/make and thus pass additionnal flags to stopt																	  																	   
		cmake -S . -B build \
          -DBUILD_PYTHON=OFF \
          -DBUILD_TEST=OFF \
          -DCMAKE_INSTALL_PREFIX="$StOpt_ROOT" \
		  -DBOOST_ROOT=${BOOST_PATH} \
		  -DEIGEN3_INCLUDE_DIR=${EIGEN_PATH}/include/eigen3
		# build in BUILD_ROOT, install in INSTALL_ROOT					    
		cmake --build build
		cmake --install build --prefix "$StOpt_ROOT"
		cd "$INSTALL_ROOT"
	else
		echo "update_stopt=$update_stopt"
		if [ $update_stopt -eq 1 ]; then
			if [ ! -d $BUILD_ROOT/StOpt ]; then 
				cd $BUILD_ROOT
				git clone https://gitlab.com/stochastic-control/StOpt.git $BUILD_ROOT/StOpt
			fi
			cd $BUILD_ROOT/StOpt
			LOCAL=$(git rev-parse @)
			REMOTE=$(git rev-parse @{u})
			# if the repository is not up to date
			if [ "$LOCAL" != "$REMOTE" ]; then
				git pull
				# with debian:bullseye the versions of boost and eigen are not good so we
				# must install with wget/make and thus pass additionnal flags to stopt
				cmake -S . -B build \
				  -DBUILD_PYTHON=OFF \
				  -DBUILD_TEST=OFF \
				  -DCMAKE_INSTALL_PREFIX="$StOpt_ROOT" \
				  -DBOOST_ROOT=${BOOST_PATH} \
				  -DEIGEN3_INCLUDE_DIR=${EIGEN_PATH}/include/eigen3
				cmake --build build --prefix "$StOpt_ROOT"
				cmake --install build
			else
				echo "StOpt already up to date."
			fi
		else
			echo "StOpt update is not requested."
		fi
		cd "$INSTALL_ROOT"
    fi

	echo "Installation completed successfully."
}

# Default values indicating if CPLEX and Gurobi should be installed
# it works even if you use `install_cplex=0` or `install_gurobi=0`
install_cplex=${install_cplex:-1}
install_gurobi=${install_gurobi:-1}
install_smspp=${install_smspp:-1}
update_linux=${update_linux:-1}
install_scip=${install_scip:-1}
install_highs=${install_highs:-1}
no_interact=${no_interact:-1}
update_stopt=${update_stopt:-1}
update_smspp=${update_smspp:-1}
update_coin=${update_coin:-1}
cplex_installer=""
gurobi_installer=""
gurobi_license=""
scip_version="9.2.0"

# Default value for installation and compilation root
# after install build_root can be deleted
install_root=""
build_root=""

# create log file
configfile="$INSTALLDIR/p4r-env/config/plan4res.conf"
datestart=$(date +"%Y-%m-%d-%H:%M")
sms_log_file="./smsppInstall_$datestart.log"
touch $log_file
echo "starting $(date +"%Y-%m-%d-%H:%M")" | tee -a  "$sms_log_file"
echo "Installing plan4res on $INSTALLDIR" | tee -a  "$sms_log_file"

# Parse command line 
echo "INSTALL.sh launched with arguments: $@" | tee -a  "$sms_log_file"
for arg in "$@"
do
	case $arg in
		--without-linux-update)  # prevents update of linux packages
			update_linux=0
			shift
			;;
		--without-stopt-update)  # prevents update of stopt
			update_stopt=0
			shift
			;;
		--without-coin-update)  # prevents update of stopt
			update_coin=0
			shift
			;;
		--without-smspp-update)  # prevents update of sms++
			update_smspp=0
			shift
			;;
		--without-cplex) # compile without cplex
			install_cplex=0
			shift
			;;	
		--without-scip) # compile without scip
			install_scip=0
			shift
			;;
		--without-highs) # compile without highs
			install_highs=0
			shift
			;;
		--without-gurobi) # compile without gurobi
			install_gurobi=0
			shift
			;;
		--without-smspp) # use only selected modules of sms++ for plan4res
			install_smspp=0
			shift
			;;
		--without-interact) # forbid interact mode in linux
			no_interact=0
			shift
			;;
		--install-root=*) # where to install the softwares
			install_root="${arg#*=}"
			shift
			;;
		--build-root=*) # where to build the softwares
			build_root="${arg#*=}"
			shift
			;;
		--cplex-installer=*)  # cplex installer file
			cplex_installer="${arg#*=}"
			shift
			;;
		--gurobi-installer=*) # gurobi installer file
			gurobi_installer="${arg#*=}"
			shift
			;;
		--gurobi-license=*) # gurobi license file
			gurobi_license="${arg#*=}"
			shift
			;;
		--scip-version=*) # scip version
			scip_version="${arg#*=}"
			shift 
			;;
		--cplex-root=*) # where cplex is already installed
			CPLEX_ROOT="${arg#*=}"
			shift
			;;
		--gurobi-root=*) # where cplex is already installed
			GUROBI_ROOT="${arg#*=}"
			shift
			;;
		--scip-root=*) # where cplex is already installed
			SCIP_ROOT="${arg#*=}"
			shift
			;;
		--highs-root=*) # where cplex is already installed
			HIGHS_ROOT="${arg#*=}"
			shift
			;;
		--coin-root=*) # where cplex is already installed
			COIN_ROOT="${arg#*=}"
			shift
			;;
		*)
			;;
	esac
done

# Detect operating system and execute the appropriate installation function
OS="$(uname)"
case "$OS" in
	"Linux")
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			echo "distribution: $ID" | tee -a  "$sms_log_file"
			if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
			# Check if the user has sudo access
				if sudo -n true 2>/dev/null; then
					HAS_SUDO=1
					INSTALL_ROOT="${install_root:-/opt}"
					BUILD_ROOT="${build_root:-/opt}"
					SMSPP_ROOT="${INSTALL_ROOT}/smspp-project"
				else
					HAS_SUDO=0
					INSTALL_ROOT="${install_root:-${HOME}}"
					BUILD_ROOT="${build_root:-${HOME}}"
					SMSPP_ROOT="${HOME}/smspp-project"  # why not ${INSTALL_ROOT}/smspp-project?
				fi
		
				# create dirs if they do not exist
				if [ ! -d $INSTALL_ROOT ]; then mkdir $INSTALL_ROOT; fi
				if [ ! -d $BUILD_ROOT ]; then mkdir $BUILD_ROOT; fi
			
				# copy cplex and gurobi installers to the installation dir
				# they need to be located in the dir where the INSTALL is launched																	
				if [ ! "${cplex_installer}" = "" ]; then
					if [ -f ${cplex_installer} ]; then
						cp ${cplex_installer} $INSTALL_ROOT
					fi
				fi
				if [ ! "${gurobi_installer}" = "" ]; then
					if [ -f ${gurobi_installer} ]; then
						cp ${gurobi_installer} $INSTALL_ROOT
					fi
				fi
				if [ ! "${gurobi_license}" = "" ]; then
					if [ -f ${gurobi_license} ]; then
						cp ${gurobi_license} $INSTALL_ROOT
					fi
				fi 

				# I want to build and install in different dirs so I add these variables
				# which I use insteas of SMSPP_ROOT
				SMSPP_BUILD_ROOT="${BUILD_ROOT}/smspp-project"
				SMSPP_INSTALL_ROOT="${INSTALL_ROOT}/sms++"
				install_on_linux
			else
				echo "This script supports Ubuntu or Debian only." | tee -a  "$sms_log_file"
				exit 1
			fi
		else
			echo "This script supports Debian-based Linux distros only." | tee -a  "$sms_log_file"
			exit 1
		fi
		;;
	"Darwin")
		INSTALL_ROOT="${install_root:-/Library}"
		SMSPP_ROOT="${INSTALL_ROOT}/smspp-project"
		install_on_macos
		;;
	*)
		echo "This script does not support the detected operating system." | tee -a  "$sms_log_file"
		exit 1
		;;
esac

# Skip compilation if running in a GitLab CI/CD Docker container
if ! { [ -f /.dockerenv ] && [ "$CI" = "true" ]; }; then
	# Install SMSpp
	echo "Compiling SMS++..." | tee -a  "$sms_log_file"
	SMSPP_URL=https://gitlab.com/smspp/smspp-project.git
	smsbranch="develop"
  
	cd $BUILD_ROOT
	# Check if the SMSpp repository already exists
	if [ -d "$SMSPP_BUILD_ROOT" ]; then
		cd $SMSPP_BUILD_ROOT
		echo "SMS++ already installed. " | tee -a  "$sms_log_file"
		if [ $update_smspp -eq 1 ] ; then 
			echo "Pulling latest changes..." | tee -a  "$sms_log_file"
			git pull origin $smsbranch
			git submodule foreach --recursive "if git show-ref --verify --quiet refs/remotes/origin/$smsbranch ; then git pull origin $smsbranch ; else git pull origin master; fi"
		fi
	else
		echo "Repository not found locally. Cloning SMS++..." | tee -a  "$sms_log_file"
		if [ -z "$DISPLAY" ] || [ ! -t 1 ] || [ "$no_interact" -eq 1 ] ; then 
			# clone in the BUILD_ROOT	
			echo "clone sms++ modules for plan4res" | tee -a  "$sms_log_file"
			git clone --branch $smsbranch --recurse-submodules $SMSPP_URL "$SMSPP_BUILD_ROOT"
			cd $SMSPP_BUILD_ROOT
			# force submodules to checkout in the requested branch
			git submodule foreach --recursive "if git show-ref --verify --quiet refs/remotes/origin/$smsbranch ; then git checkout $smsbranch ; else git checkout master; fi"
		else
			echo "clone full sms++" | tee -a  "$sms_log_file"
			git clone --branch $smsbranch $SMSPP_URL "$SMSPP_BUILD_ROOT"
		fi
	fi
	cd $SMSPP_BUILD_ROOT

	# If the installation root is not the default one, update the makefile-paths
	echo "build in $SMSPP_BUILD_ROOT and install in $SMSPP_INSTALL_ROOT" | tee -a  "$sms_log_file"
	# GUROBI_ROOT has changed and it can be found out of GUROBI_HOME which is an env var even if Gurobi was not installed just now
	if [ ! -z $GUROBI_HOME ]; then GUROBI_ROOT=$(echo $GUROBI_HOME | sed 's/\/linux64$//') ; fi
	if [[ ("$OS" == "Linux" && "$INSTALL_ROOT" != "/opt") ||
        ("$OS" == "Darwin" && "$INSTALL_ROOT" != "/Library") ]]; then
		umbrella_extlib_file="$SMSPP_BUILD_ROOT/extlib/makefile-paths"
		# Create the file with the new paths of the resources for the umbrella
		{
			echo "CPLEX_ROOT = ${CPLEX_ROOT}"
			echo "SCIP_ROOT = ${SCIP_ROOT}"
			echo "GUROBI_ROOT = ${GUROBI_ROOT}"
			echo "HiGHS_ROOT = ${HiGHS_ROOT}"
			echo "StOpt_ROOT = ${StOpt_ROOT}"
			echo "CoinUtils_ROOT = ${CoinOr_ROOT}"
			echo "Osi_ROOT = ${CoinOr_ROOT}"
			echo "Clp_ROOT = ${CoinOr_ROOT}"
		} > "$umbrella_extlib_file"
		echo "Created $umbrella_extlib_file file."

		# If the submodule BundleSolver is initialized, i.e., the folder is not empty
		if [ -d "$SMSPP_BUILD_ROOT/BundleSolver" ] && [ -n "$(ls -A "$SMSPP_BUILD_ROOT/BundleSolver")" ]; then
			ndofi_extlib_file="$SMSPP_BUILD_ROOT/BundleSolver/NdoFiOracle/extlib/makefile-paths"
			# Create the file with the new paths of the resources for BundleSolver/NdoFiOracle
			{
				echo "CPLEX_ROOT = ${CPLEX_ROOT}"
				echo "GUROBI_ROOT = ${GUROBI_ROOT}"
				echo "CoinUtils_ROOT = ${CoinOr_ROOT}"
				echo "Osi_ROOT = ${CoinOr_ROOT}"
				echo "Clp_ROOT = ${CoinOr_ROOT}"
			} > "$ndofi_extlib_file"
			echo "Created $ndofi_extlib_file file."
		fi

		# If the submodule MCFBlock is initialized, i.e., the folder is not empty
		if [ -d "$SMSPP_BUILD_ROOT/MCFBlock" ] && [ -n "$(ls -A "$SMSPP_BUILD_ROOT/MCFBlock")" ]; then
			mcf_extlib_file="$SMSPP_BUILD_ROOT/MCFBlock/MCFClass/extlib/makefile-paths"
			# Create the file with the new paths of the resources for the MCFBlock/MCFClass
			{
				echo "CPLEX_ROOT = ${CPLEX_ROOT}"
			} > "$mcf_extlib_file"
			echo "Created $mcf_extlib_file file."
		fi
	fi

	# Build SMSpp
	cd $SMSPP_BUILD_ROOT
	if [ -z "$DISPLAY" ] || [ ! -t 1 ] || [ "$no_interact" -eq 0 ]; then
		# need to add flags for eigen and boost as I cannot install them with apt-get																				
		CMAKEFLAGS="-DCMAKE_INSTALL_PREFIX=${SMSPP_INSTALL_ROOT} 
			-Wno-dev \
			-DBOOST_ROOT=${BOOST_PATH} \
			-DEigen3_ROOT=${EIGEN_PATH}/share/eigen3/cmake \
			-DStOpt_ROOT=${StOpt_ROOT} \
			-DCMAKE_BUILD_TYPE=Release \
			-DBUILD_InvestmentBlock=ON \
			-DBUILD_tools=ON \
			-DBUILD_LagrangianDualSolver=ON \
			-DBUILD_BundleSolver=ON \
			-DBUILD_MILPSolver=ON "
	
		# choose OSi_QP version depending on solvers installed
		if [ -d "$CPLEX_ROOT" ]; then
			echo "repo $CPLEX_ROOT exists, building with CPLEX" | tee -a  "$sms_log_file"
			# if cplex is installed, choose Cplex
			CMAKEFLAGS+="-DWHICH_OSI_QP=1"
		elif [ ! -z $GUROBI_HOME ] && [ -d "$GUROBI_ROOT/$GRBDIR" ]; then
			echo "repo $GUROBI_ROOT/$GRBDIR exists, building with GUROBI" | tee -a  "$sms_log_file"
			# if cplex not there but gurobi installed, choose gurobi
			CMAKEFLAGS+="-DWHICH_OSI_QP=2"
		else
			# if none of cplex or gurobi is there use Clp
			CMAKEFLAGS+="-DWHICH_OSI_QP=0 -DWHICH_OSI_MP=0"
		fi
		cmake -S . -B build $CMAKEFLAGS
		cmake --build build
		# compile in BUILD_ROOT, install in INSTALL_ROOT
		cmake --install build --prefix ${SMSPP_INSTALL_ROOT}
	else
		# run ccmake in a xterm subshell to allow interaction
		xterm -e ccmake build & # select submodules, then Configure and Generate the build files
		wait $! # wait for ccmake to finish
		CCMAKE_EXIT_CODE=$?
		if [ $CCMAKE_EXIT_CODE -eq 0 ]; then
			cmake --build build
			cmake --install build
		else
			echo "ccmake fails with exit code $CCMAKE_EXIT_CODE." | tee -a  "$sms_log_file"
			exit 1
		fi
	fi
fi
