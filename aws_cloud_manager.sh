#!/bin/bash

check_num_of_args() {
	# Checking the number of arguments
	if [ "$#" -ne 0 ]; then
	    echo "Usage: $0 <environment>"
	    exit 1
	fi
}


# Accessing the first argument
ENVIRONMENT=$1

activate_infra_environment() {
	# Acting based on the argument value
	if [ "$ENVIRONMENT" == "local" ]; then
	  echo "Running script for Local Environment..."
	elif [ "$ENVIRONMENT" == "testing" ]; then
	  echo "Running script for Testing Environment..."
	elif [ "$ENVIRONMENT" == "production" ]; then
	  echo "Running script for Production Environment..."
	else
	  echo "Invalid environment specified. Please use 'local', 'testing', or 'production'."
	  exit 2
	fi
}

check_aws_cli() {
	if ! command -v aws $> /dev/null; then
		echo "AWS CLI is not installed. Please install it before proceeding."
		return 1
	fi
}

check_aws_profile() {
	if [ -z "$AWS_PROFILE" ]; then
		echo "AWS profile environment variable is not set"
		return 1
	fi
}

create_ec2_instance() {
	# specicify the parameters for the EC2 instances
	instance_type="t2.micro"
	ami_id="ami-0cd59ecaf368e5ccf"
	count=2 # Number of instances to create
	region="us-east-1" # Rgion to create cloud resources

	# Create the EC@ intances
	aws ec2 run-instances \
		--image-id "$ami_id" \
		--instance-type "$instance_type" \
		--count $count \
		--key-name my-key-pair

	# Check if the EC2 instances were created successfully
	if [[ $? -eq 0 ]]; then
		echo "EC2 instances created successfully."
	else
		echo "Failed to create EC2 instances."
	fi
}

# Function to create S3 buckets for different departments
create_s3_buckets() {
    company="datawise"
    departments=("marketing" "sales" "hr" "operations" "media")
    
    for department in "${departments[@]}"; do
        bucket_name="${company}-${department}-data-bucket"
        
        # Check if the bucket already exists
        if aws s3api head-bucket --bucket "$bucket_name" &>/dev/null; then
            echo "S3 bucket '$bucket_name' already exists."
        else
            # Create S3 bucket using AWS CLI
            aws s3api create-bucket --bucket "$bucket_name" --region "us-east-1"
            if [ $? -eq 0 ]; then
                echo "S3 bucket '$bucket_name' created successfully."
            else
                echo "Failed to create S3 bucket '$bucket_name'."
            fi
        fi
    done
}

iam_users=("John" "Tom" "Ezi" "Tim" "Sam")
group_name="admin"

# Function to create IAM Users
create_iam_users() {
	for user in "${iam_users[@]}"; do
		aws iam get-user --user-name $user &>/dev/null
		if [[ $? -eq 0 ]]; then
			echo "User already exists"
		else
			aws iam create-user \
				--user-name $user
			if [[ $? -eq 0 ]]; then
				echo "IAM User '$user' created successfully"
			else
				echo "Failed to create IAM User '$user'"
			fi
		fi
	done
}

# Function to create IAM Group
create_iam_group() {
	aws iam create-group \
		--group-name $group_name

	# Check if the group was created successfully
	if [[ $? -eq 0 ]]; then
		echo "Group $group_name created successfully."
	else
		echo "Failed to create $group_name group."
	fi
}

# Function to attach administrative policy to group
attach_policy_to_group() {
	policy="arn:aws:iam::aws:policy/AdministratorAccess"
	aws iam attach-group-policy \
		--group-name $group_name \
		--policy-arn $policy

	# Check if the group policy was attached successfully
	if [[ $? -eq 0 ]]; then
		echo "Group $policy attached successfully."
	else
		echo "Failed to attach $policy to $group_name group."
	fi
}

# Function to attach users to group
attach_users_to_group() {
	for user in "${iam_users[@]}"; do
		aws iam add-user-to-group \
			--group-name $group_name \
			--user-name $user

		# Check if user was attached to group successfully	
		if [[ $? -eq 0 ]]; then
			echo "IAM User '$user' attached to $group_name group successfully"
		else
			echo "Failed to attach IAM User '$user' to $group_name group"
		fi
	done
}

check_num_of_args
activate_infra_environment
check_aws_cli
check_aws_profile
create_ec2_instance
create_s3_buckets
create_iam_users
create_iam_group
attach_policy_to_group
attach_users_to_group