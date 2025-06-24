# What is infrastructure as code
Infrastructure as code means managing and provising infrastructure like servers, databases, networks while using code instead of doing manually. 

## Why do we need this?
IaC is automated and consistent, used version control. Also it can recreate the same infra anywhere. Everyone shares and reviews the same code

## What is Terraform?
Terraform is a open-source Infrastructure as Code tool created by HashiCorp. it lets us define cloud sesources using a simole declaratibe language called HCL. We can describe what we want and Terraform figures out how to do it.

## What is the purpose of Terraform?
Terraform helps us to create manage and destroy cloud resources automatically. We can use tool for multiples cloud providers.

## What is the core concept in Terraform?
 #### Providers
Plugins to interact with cloud providers
#### Resources
Actual cloud components like EC2, S3, VPC etc
#### Variables
Input values to parameterize code
#### Outputs
Return values from the configuration
#### Modules
Reusable chunks of Terraform code
#### State
A file that keeps track of what Terraform has created

## How does Terraform work?
1. Write code - .tf files to define resources.
2. Initialize - terraform init to set up providers
3. Plan - terraform plan to see changes before applying
4. Apply - terraform apply to create/update infrastructure
5. Destroy - terraform destroy to all resources

## What are Terraform modules?
Modules are containers for multiple resources that are used together. We can think of it a function in programming. Instead of copying the same resource code everywhere, we can wrap it in a module and reuse it.

## What is state locking in Terraform?
State locking is used to prevent multiple users or systems from editing the state at the same time.
This is especially important in team environments. If two people run terraform apply at once, they might corrupt state file. Terraform uses state locking when using remote backends S3 with DynameDB.

# HOW I CAN CREATE A SOLUTION FOR A PROJECT USING TERRAFORM
### I have a Java project and to terraform all the resources and run my backend on a virtual computer. Also I need to create a backend S3 bucket to track Terraform state and make sure my infrastructure changes are stored and versioned properly.
### STEPS
1. I need to set up the provides for AWS
2. Ec2+user_data,Security groups, VPC , Subnet and Internet gateway route table and finally RDS

#### If needed
 I will create separate module folders for vpc, security group, rds, ec2 and create. Each folder will have variables.tf and output.tf to make clean and clear. After that in the root I will call all the modules on main.tf. Also to run my java application I will use user_data.

