#!/bin/bash

# path of the file .bashrc
BASHRC_FILE="$HOME/.bashrc"

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

local_dir=$(pwd)
update_env_var "P4R_DIR_LOCAL" $local_dir
update_env_var "P4R_DIR" "/efs/software/plan4res/P4REDF/p4r-env"
update_env_var "SINGULARITY_BIND" "/efs/software/plan4res/P4REDF/p4r-env/"

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

	file="$(pwd)/this_awsp4r.sh"	
	cp $P4R_DIR/scripts/include/awsp4r.sh $file
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



#grep_result=$(grep -e "P4R_DIR_LOCAL" "$BASHRC_FILE")
#if [[ -z "$grep_result" ]]; then
#    echo "export P4R_DIR_LOCAL=\"$local_dir\"" >> "$BASHRC_FILE"

echo "sourcing .bashrc"
source "$BASHRC_FILE"

directories=("data" "data/local")
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "Directory $dir already exists."
    else
        mkdir "$dir"
        echo "Directory $dir created."
    fi
done

echo " Create example dataset mini "
cp -r /efs/software/plan4res/P4REDF/p4r-env/data/local/mini data/local/
echo "Installation finalised"
echo "To run plan4res type: p4r [MODE] dataset [options]"
echo "    MODE = CLEAN / CREATE / FORMAT / SSV / SIM / CEM / SSVandSIM / SSVandCEM / POSTTREAT "
echo "    dataset = name of dataset (e.g. mini)"
echo "    options: see from full help"
echo " get full help : p4r --help"

