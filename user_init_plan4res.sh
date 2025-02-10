#!/bin/bash

# path of the file .bashrc
BASHRC_FILE="$HOME/.bashrc"
local_dir=$(pwd) 

test_option() {
	local code=$1
	local option=$2
	if [[ $option == --* ]] || [[ $option == -* ]] || [[ $option == "" ]]; then
		echo "Error: input not provided after $code" 
		exit 1 
	fi
}

usage() {
	echo "This script can be run after plan4res as been installed in <installdir> "
	echo "It will create the environment variables P4R_DIR and P4R_DIR_LOCAL"
	echo "	P4R_DIR is where plan4res is installed (there is a repo P4R_DIR/p4r-env"
	echo "	P4R_DIR_LOCAL is where your datasets and the results of plan4res will be"
	echo "It will also create the functions p4r and sp4r"
	echo "	p4r is used to run plan4res"
	echo "	sp4r is used to run on an HPC cluster with SLURM"
	echo "and an example of dataset and settings in data/toyDataset"
	echo ""
	echo "Usage: ./user_init_plan4res -D [ <installdir> ] -S [ <SOLVER> ]"
	echo "   -D [ <installdir> ] is optional, if it is not present it means that "
	echo "       p4r-env is installed in the location from which you are running this script "
	echo "       currently: $local_dir"
	echo "   -S [ <SOLVER> ] is optional, if not provided HiGHS will be used"
	echo "       this script will update the settings so that <SOLVER> is used"
	echo "       SOLVER can be CPLEX, GUROBI, SCIP, or HiGHS"
	echo "       The chosen solver must be installed with plan4res"
	echo "You need to have an internet access to run this script"
	echo "  If you are behind a proxy, check that it is open"
	exit 1
}

function update_solver {
    local file=$1
    local solver=$2
    local valid_solvers=("CPLEX" "SCIP" "GUROBI" "HiGHS")
    local valid_modules=("CPXMILPSolver" "SCIPMILPSolver" "GRBMILPSolver" "HiGHSMILPSolver")
	local regex=$(IFS=\|; echo "${valid_modules[*]}")
	
    # check if solver is valid
	MILPModule="HiGHSMILPSolver"
    if [[ ! " ${valid_solvers[@]} " =~ " ${solver} " ]]; then
        echo "non valid solver $solver. Valid solvers are : ${valid_solvers[*]}"
        usage
    else
		if [ "$solver" = "CPLEX" ]; then 
			MILPModule="CPXMILPSolver"
		elif [ "$solver" = "GUROBI" ]; then 
			MILPModule="GRBMILPSolver"
		elif [ "$solver" = "SCIP" ]; then 
			MILPModule="SCIPMILPSolver"
		fi
	fi

    # Read config file
    while IFS= read -r line; do
        # Remove # before name of module for solver
		cleaned_line="${line//\#/}"
		cleaned_line="${cleaned_line//\ /}"
		if [[ "$cleaned_line" =~ $regex ]]; then
			if [[ "$cleaned_line" == *$MILPModule* ]]; then
				echo "$cleaned_line"
			else
				echo "#$cleaned_line"
			fi
		else
			echo $line
		fi
	done < "$file" > temp_file 
	mv temp_file "$file"
}

SOLVER=""
# treat arguments
while [[ "$#" -gt 0 ]]; do
	case $1 in
		-H|--help) 
			usage
			;;
		-D|--dir) 
			INSTALL_DIR=$2 
			test_option $1 $2
			shift 2
			echo "setup $INSTALL_DIR" 
			;;
		-S|--solver) 
			SOLVER=$2 
			test_option $1 $2
			shift 2
			echo "initialise settings for $SOLVER" 
			;;
		*) 
			echo "unknown option $1" 
			usage 
			;;
	esac
done

if [ "$INSTALL_DIR" = "" ]; then
	if [ ! -d $local_dir/p4r-env ]; then
		echo "Error: p4r-env is not present in $local_dir"
		echo "Please provide location of plan4res"
		usage
	else
		echo "p4r-env is present in $local_dir, proceeding...."
		INSTALL_DIR=$local_dir
	fi
else
	if [ ! -d $INSTALL_DIR/p4r-env ]; then
		echo "Error: p4r-env is not present in $INSTALL_DIR"
		echo "Please provide location of plan4res"
		usage
	else
		echo "p4r-env is present in $INSTALL_DIR, proceeding...."
	fi
fi

update_env_var() {
    local var_name="$1"
    local new_value="$2"
    grep_result=$(grep "export ${var_name}=" "$BASHRC_FILE")
    if [[ -z "$grep_result" ]]; then
        echo "export $var_name=$new_value" >> "$BASHRC_FILE"
	echo "$var_name=$new_value added to .bashrc"
    else
	sed -i "s|export $var_name=.*|export $var_name=$new_value|" "$BASHRC_FILE"
    	echo " $var_name already defined, changing value to $new_value"
        
    fi
}


update_env_var "P4R_DIR_LOCAL" $local_dir
update_env_var "P4R_DIR" "$INSTALL_DIR/p4r-env"
update_env_var "SINGULARITY_BIND" "$INSTALL_DIR/p4r-env/"

#functions_to_add=$( cat << 'EOF'
functions_to_add=$(cat << 'EOF'
	
# function for launching plan4res
sp4r() {
	local new_nodes_value
	local args=("$@")
	local sbatch_args=()
	while [[ "$1" != "" ]]; do
		case $1 in
		    -n | --nodes ) shift
		                   new_nodes_value="$1"
		                   ;;
		    * )		   sbatch_args+=("$1")    
				   ;;
		esac
		shift
	done

	file="$(pwd)/this_sbatch_p4r.sh"	
	cp $P4R_DIR/scripts/include/sbatch_p4r.sh $file
	echo "changing requested number of nodes to: $new_nodes_value and running ${sbatch_args[*]} via sbatch file $file"
	
	sed -i "/^#SBATCH --nodes=/c #SBATCH --nodes=$new_nodes_value" "$file"
	export ARGS=("$@")
	sbatch "$file" "$P4R_DIR" "${sbatch_args[@]}"
}

p4r() {
	source $P4R_DIR/scripts/include/run_p4r.sh "$P4R_DIR" "$@"
}
# end function for launching plan4res

EOF
	)
		
#Add functions to .bashrc
if ! grep -q -e "sp4r()" -e "p4r()" "$BASHRC_FILE"; then
    echo "adding functions to .bashrc $BASHRC_FILE"
    echo "$functions_to_add" >> $BASHRC_FILE
    echo " functions p4r and sp4r added to bashrc"
else
    echo " functions p4r and sp4r already in bashrc, replacing them"
    sed -i '/# function for launching plan4res/,/# end function for launching plan4res/d' "$BASHRC_FILE"
    echo "$functions_to_add" >> $BASHRC_FILE
fi

echo "sourcing .bashrc $BASHRC_FILE"

#source $BASHRC_FILE
source ~/.bashrc

if [ -d $local_dir/documentation ]; then
	echo " Update documentation "
	cd $local_dir/documentation
 	git pull
	git clone https://github.com/plan4res/documentation
else
	echo " Get documentation "
	cd $local_dir
	git clone https://github.com/plan4res/documentation
fi

if [ -d "$local_dir/data" ]; then
	echo "Directory $local_dir/data already exists."
else
    mkdir "$local_dir/data"
    echo "Directory $local_dir/data created."
fi
echo " Create example dataset toyDataset "
cd $local_dir/data
git clone https://github.com/plan4res/toyDataset

# update settings to account for solver
if [ "$SOLVER" = "" ]; then
	echo "Solver not specified, settings files are created using default solver HiGHS"
	SOLVER="HiGHS"
fi
echo "updating settings file $local_dir/data/toyDataset/settings/uc_solverconfig.txt for solver $SOLVER"
update_solver "$local_dir/data/toyDataset/settings/uc_solverconfig.txt" "$SOLVER"
cd ../..
echo "Installation finalised"
echo "To run plan4res type: p4r [MODE] dataset [options]"
echo "To run plan4res on a cluster with SLURM, type: sp4r -n [NumberNodes] [MODE] dataset [options]"
echo "    MODE = CLEAN / CREATE / FORMAT / SSV / SIM / CEM / SSVandSIM / SSVandCEM / POSTTREAT "
echo "    dataset = name of dataset (e.g. mini)"
echo "    options: see from full help"
echo " get full help : p4r --help"

