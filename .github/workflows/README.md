# Cloud Computing
Cloud computing is delivering computing services like servers, storage, databases, networking etc. Instead of owning and maintaining our own pyhsical computer hardware, we use these services from a cloud provider.

## Five Basic Consepts of Cloud Computing
1. On-Demand Self-Service: We can get computing resources whenevet we need them wiyhout needing to talk a person. We just use a web interface or an API. For example launcing ec2 on aws in minutes with a few clicks or using a tool like Terraform. We dont need to wait for an IT department.
2. Broad Network Access: Cloud services can be accessed from many diffirent devices over a network usually internet. For example accesing a file we stored on AWS S3 from anywhere in the world, as long as we have an internet connection an the right permissions.
3. Resource Pooling: The cloud provider gathers computing resources into a large pool. They share these resources among many customers. We usually dont know exactly where our resources are physically located.
4. Rapid elasticity: Cloud resources can be quick and automaticlly scaled up or down to meet changing demands. They can be increased or decreased very fast, sometimes even instantly. For the user, it feels like there are unlimited resources available. For example if our website suddenly gets a lot of visitors, AWS Auto Scaling can automatically start new EC2 instances to handle the traffic. When traffic goes down, it can automatically shut them off.
5. Measured Service: Cloud system automatically monitor and control resource usage. They track how much you use like storage, processing power, network data. This means we only pay for what we actually use.

# S3
AWS S3 is a object storage services designed to store any amount of date. We can use it for websites, mobile apps, backups projects. 
# Github Actions
Github Action is a CI/CD platform that allows you to automate tasks and workflows directly within our github repos.

# CI/CD
It is a methodology that automates and streamlines the software development process.
It enables software to be delivered to customers faster, more reliably and more frequently
CI is a practice where developers frequently merge their code changes into a central repository. After each merge, automated builds and tests are run.
Continuous delivery is an extension of Continuous Integration. It automates the process of building, testing and preparign software for release. Hovewer deployment to production is often manual step.
Continuous Deployment is a step beyond Continuous Delivery. Every code that passes all testes is automatically deployed to production without any human intervention.

## Workflow
An automated process that defines one or more jobs. It's defined in a YAML file inside the .github/workflows/ directory of our repo.
We specify the events that start a workflow.

## Job
A job is a set of stpes that run on the same runner(virtual machine or a container). Workflows can hav multiple jobs. They run in prallel.
Running envitonemnt (runs-on), We specify the operating system where the job will execute like ubuntu or windows
#### Usage
1. Ubuntu-latest
2. larger runners
3. self-hosted runners

## Steps
An indevidual task within a job. Steps run in the order they are defined.
We use run and uses. run executes command-line commands directly. uses executes a pre-defined "action" like a reusable code block

## Action
The smallest, reusable block in Github Actions. It performs a specific task. We can write our own actions or use actions from github community. For example actions/checkout@v4 cloes our repo code to the runner. actions/setup-node@v4 sets up node environment. docker/build-push-actions@v5 builds and pushes a Docker image.

## Usage
1. Ubuntu-latest
2. larger runners
3. self-hosted runners


