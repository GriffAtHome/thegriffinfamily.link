import json
import subprocess
import boto3
import os

def get_terraform_plan():
    infrastructure_dir = './infrastructure'
    
    # Generate terraform plan file
    try:
        # Create plan in infrastructure directory
        subprocess.run([
            'terraform', 'plan',
            '-var-file=env/dev.tfvars',
            '-out=tfplan'
        ], cwd=infrastructure_dir, check=True)
        
        # Convert plan to JSON in the same directory
        process = subprocess.run([
            'terraform', 'show',
            '-json',
            'tfplan'
        ], cwd=infrastructure_dir, capture_output=True, text=True, check=True)
        
        if process.stdout:
            return json.loads(process.stdout)
        else:
            print("No JSON output received from terraform show")
            return None
    except subprocess.CalledProcessError as e:
        print(f"Error running terraform commands: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")
        return None
    finally:
        # Clean up the plan file
        try:
            plan_path = os.path.join(infrastructure_dir, 'tfplan')
            if os.path.exists(plan_path):
                os.remove(plan_path)
        except OSError as e:
            print(f"Error cleaning up plan file: {e}")

def check_aws_resources():
    session = boto3.Session(region_name='us-east-1')
    resources = []

    # Check VPC and Network Resources
    ec2 = session.client('ec2')
    try:
        vpcs = ec2.describe_vpcs(Filters=[{'Name': 'tag:Name', 'Values': ['eks-vpc']}])['Vpcs']
        resources.append(f"VPCs found: {[vpc['VpcId'] for vpc in vpcs]}")
        
        if vpcs:
            vpc_id = vpcs[0]['VpcId']
            subnets = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])['Subnets']
            resources.append(f"Subnets found: {[subnet['SubnetId'] for subnet in subnets]}")
            
            nats = ec2.describe_nat_gateways(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])['NatGateways']
            resources.append(f"NAT Gateways found: {[nat['NatGatewayId'] for nat in nats]}")
    except Exception as e:
        resources.append(f"Error checking VPC resources: {str(e)}")

    # ... existing EKS and ALB checks ...

    # Check IAM Roles
    iam = session.client('iam')
    try:
        roles = iam.list_roles(PathPrefix='/')['Roles']
        eks_roles = [r['RoleName'] for r in roles if 'eks' in r['RoleName'].lower()]
        resources.append(f"EKS IAM Roles found: {eks_roles}")
    except Exception as e:
        resources.append(f"Error checking IAM roles: {str(e)}")

    return resources

def main():
    print("Analyzing Terraform plan vs AWS resources...")
    
    # Get Terraform plan
    plan = get_terraform_plan()
    if not plan:
        print("Failed to get Terraform plan")
        return

    # Check AWS resources
    print("\nChecking AWS resources...")
    aws_resources = check_aws_resources()
    
    # Output results
    print("\nAWS Resources Found:")
    for resource in aws_resources:
        print(f"- {resource}")

if __name__ == "__main__":
    main()