#!/bin/bash

# Hadhir Driver Production Deployment Script
# This script helps deploy the application to AWS production environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="hadhir-driver"
AWS_REGION="us-east-1"
ENVIRONMENT="production"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to create S3 bucket for Terraform state
create_terraform_state_bucket() {
    print_status "Creating S3 bucket for Terraform state..."
    
    BUCKET_NAME="hadhir-driver-terraform-state"
    
    if aws s3 ls "s3://$BUCKET_NAME" 2>&1 > /dev/null; then
        print_warning "S3 bucket $BUCKET_NAME already exists."
    else
        aws s3 mb "s3://$BUCKET_NAME" --region $AWS_REGION
        aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
        aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
        print_success "S3 bucket $BUCKET_NAME created successfully!"
    fi
}

# Function to deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying AWS infrastructure with Terraform..."
    
    cd aws-infrastructure
    
    # Initialize Terraform
    terraform init
    
    # Plan the deployment
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Ask for confirmation
    read -p "Do you want to apply this Terraform plan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply tfplan
        print_success "Infrastructure deployed successfully!"
        
        # Save outputs to file
        terraform output -json > ../terraform-outputs.json
    else
        print_warning "Terraform deployment cancelled."
        exit 1
    fi
    
    cd ..
}

# Function to build and push Docker image
build_and_push_docker() {
    print_status "Building and pushing Docker image..."
    
    # Get ECR repository URL from Terraform outputs
    ECR_REPO=$(jq -r '.ecr_repository_url.value' terraform-outputs.json)
    
    if [ -z "$ECR_REPO" ] || [ "$ECR_REPO" = "null" ]; then
        print_error "Could not get ECR repository URL from Terraform outputs."
        exit 1
    fi
    
    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
    
    # Build Docker image
    cd backend
    docker build -f Dockerfile.production -t $ECR_REPO:latest .
    docker push $ECR_REPO:latest
    cd ..
    
    print_success "Docker image built and pushed successfully!"
}

# Function to create ECS service
create_ecs_service() {
    print_status "Creating ECS service..."
    
    # Get values from Terraform outputs
    CLUSTER_ARN=$(jq -r '.ecs_cluster_arn.value' terraform-outputs.json)
    TASK_DEF_ARN=$(jq -r '.ecs_task_definition_arn.value' terraform-outputs.json)
    TARGET_GROUP_ARN=$(jq -r '.alb_target_group_arn.value' terraform-outputs.json)
    
    if [ -z "$CLUSTER_ARN" ] || [ "$CLUSTER_ARN" = "null" ]; then
        print_error "Could not get ECS cluster ARN from Terraform outputs."
        exit 1
    fi
    
    # Create ECS service
    aws ecs create-service \
        --cluster $CLUSTER_ARN \
        --service-name hadhir-driver-api \
        --task-definition $TASK_DEF_ARN \
        --desired-count 2 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$(jq -r '.private_subnet_ids.value[]' terraform-outputs.json | tr '\n' ',' | sed 's/,$//')],securityGroups=[$(jq -r '.ecs_security_group_id.value' terraform-outputs.json)],assignPublicIp=ENABLED}" \
        --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=hadhir-driver-api,containerPort=8000" \
        --region $AWS_REGION
    
    print_success "ECS service created successfully!"
}

# Function to build Flutter app
build_flutter_app() {
    print_status "Building Flutter app..."
    
    # Get Flutter dependencies
    flutter pub get
    
    # Build for web
    flutter build web --release
    
    # Build for Android
    flutter build apk --release
    
    # Build for iOS (no codesign)
    flutter build ios --release --no-codesign
    
    print_success "Flutter app built successfully!"
}

# Function to deploy Flutter web to S3
deploy_flutter_web() {
    print_status "Deploying Flutter web to S3..."
    
    # Get S3 bucket name from Terraform outputs
    S3_BUCKET=$(jq -r '.s3_bucket_name.value' terraform-outputs.json)
    CLOUDFRONT_DISTRIBUTION_ID=$(jq -r '.cloudfront_distribution_id.value' terraform-outputs.json)
    
    if [ -z "$S3_BUCKET" ] || [ "$S3_BUCKET" = "null" ]; then
        print_error "Could not get S3 bucket name from Terraform outputs."
        exit 1
    fi
    
    # Sync web build to S3
    aws s3 sync build/web/ s3://$S3_BUCKET --delete
    
    # Invalidate CloudFront cache
    if [ "$CLOUDFRONT_DISTRIBUTION_ID" != "null" ]; then
        aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths "/*"
    fi
    
    print_success "Flutter web deployed to S3 successfully!"
}

# Function to setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring and alerting..."
    
    # Create CloudWatch dashboard
    aws cloudwatch put-dashboard \
        --dashboard-name "Hadhir-Driver-Production" \
        --dashboard-body file://aws-infrastructure/cloudwatch-dashboard.json \
        --region $AWS_REGION
    
    # Create SNS topic for alerts
    ALERT_TOPIC_ARN=$(aws sns create-topic --name "hadhir-driver-alerts" --region $AWS_REGION --query 'TopicArn' --output text)
    
    print_success "Monitoring setup completed!"
    print_status "Alert topic ARN: $ALERT_TOPIC_ARN"
}

# Function to run health checks
run_health_checks() {
    print_status "Running health checks..."
    
    # Get load balancer DNS from Terraform outputs
    ALB_DNS=$(jq -r '.load_balancer_dns.value' terraform-outputs.json)
    
    if [ -z "$ALB_DNS" ] || [ "$ALB_DNS" = "null" ]; then
        print_error "Could not get load balancer DNS from Terraform outputs."
        exit 1
    fi
    
    # Wait for service to be ready
    print_status "Waiting for service to be ready..."
    sleep 30
    
    # Test health endpoint
    if curl -f "http://$ALB_DNS/health" > /dev/null 2>&1; then
        print_success "Health check passed!"
    else
        print_error "Health check failed!"
        exit 1
    fi
}

# Function to display deployment information
display_deployment_info() {
    print_success "Deployment completed successfully!"
    echo
    echo "=== Deployment Information ==="
    echo "Load Balancer URL: http://$(jq -r '.load_balancer_dns.value' terraform-outputs.json)"
    echo "CloudFront URL: https://$(jq -r '.cloudfront_domain.value' terraform-outputs.json)"
    echo "Database Endpoint: $(jq -r '.database_endpoint.value' terraform-outputs.json)"
    echo "Redis Endpoint: $(jq -r '.redis_endpoint.value' terraform-outputs.json)"
    echo
    echo "=== Next Steps ==="
    echo "1. Configure your domain name to point to the CloudFront distribution"
    echo "2. Set up SSL certificates for HTTPS"
    echo "3. Configure monitoring alerts"
    echo "4. Test the application thoroughly"
    echo "5. Update your Flutter app configuration with production URLs"
}

# Main deployment function
main() {
    echo "=== Hadhir Driver Production Deployment ==="
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Create Terraform state bucket
    create_terraform_state_bucket
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Build and push Docker image
    build_and_push_docker
    
    # Create ECS service
    create_ecs_service
    
    # Build Flutter app
    build_flutter_app
    
    # Deploy Flutter web
    deploy_flutter_web
    
    # Setup monitoring
    setup_monitoring
    
    # Run health checks
    run_health_checks
    
    # Display deployment information
    display_deployment_info
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 