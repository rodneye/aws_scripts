#!/bin/bash
#created by that guy Rodney Ellis
cat << "EOF"
                    ##        .            
              ## ## ##       ==            
           ## ## ## ##      ===            
       /""""""""""""""""\___/ ===        
      {                      /  ===-  
       \______ o          __/            
         \    \        __/             
          \____\______/                    
EOF
#########################################################################
###!!!!!!!!!!!          Generate InventoryReport           !!!!!!!!!!!###
#########################################################################
#
#
echo "..........."
echo "..............."
echo "....................."
echo "Please confirm AWS config is enabled for the region and account"

# example use pass aws profile in variable
# Get list https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_Cassandra.html
# and here https://docs.aws.amazon.com/cli/latest/reference/configservice/list-discovered-resources.html
# sh get-resources.sh <AWS Region>

region1=$1
if [ -z "$region1" ]; then
    echo "How to run the Script for multi region: ./get-resorces.sh eu-west-1 af-south-1"
    exit 0
    else
    region1=$1
fi

region2=$2
if [ -z "$region2" ]; then
    echo "No second region set"
    else
    region2=$2
fi

echo "Please add the account name and hit enter:"
read ACC_NAME

if [ -z "$ACC_NAME" ]; then
    echo "No account name set using deafualt name"
    ACC_NAME="Account"
    else
    echo "Account name $ACC_NAME"
fi

#Get accountID
ACCOUNT=$(aws sts get-caller-identity --output text | awk {'print $1'})
FILE1="/tmp/inventory-$ACC_NAME-$ACCOUNT-$region1.csv"
FILE2="/tmp/inventory-$ACC_NAME-$ACCOUNT-$region2.csv"

if [ -z "$region2" ]; then
    echo "Creating csv $FILE1 "
    echo "Type,Service,TotalCount" >> $FILE1
    echo "Running inventory list for account $ACCOUNT this can take 5 Min "
    else
    echo "Creating csv $FILE1 "
    echo "Type,Service,TotalCount" >> $FILE1
    echo "Creating csv $FILE2 "
    echo "Type,Service,TotalCount" >> $FILE2
    echo "Running inventory list for account $ACCOUNT this can take 5 Min "
fi

#Prod
for element in AWS::EC2::CustomerGateway AWS::EC2::EIP AWS::EC2::Host AWS::EC2::Instance AWS::EC2::InternetGateway AWS::EC2::NetworkAcl AWS::EC2::NetworkInterface AWS::EC2::RouteTable AWS::EC2::SecurityGroup AWS::EC2::Subnet AWS::CloudTrail::Trail AWS::EC2::Volume AWS::EC2::VPC AWS::EC2::VPNConnection AWS::EC2::VPNGateway AWS::EC2::RegisteredHAInstance AWS::EC2::NatGateway AWS::EC2::EgressOnlyInternetGateway AWS::EC2::VPCEndpoint AWS::EC2::VPCEndpointService AWS::EC2::FlowLog AWS::EC2::VPCPeeringConnection AWS::Elasticsearch::Domain AWS::IAM::Group AWS::IAM::Policy AWS::IAM::Role AWS::IAM::User AWS::ElasticLoadBalancingV2::LoadBalancer AWS::ACM::Certificate AWS::RDS::DBInstance AWS::RDS::DBSubnetGroup AWS::RDS::DBSecurityGroup AWS::RDS::DBSnapshot AWS::RDS::DBCluster AWS::RDS::DBClusterSnapshot AWS::RDS::EventSubscription AWS::S3::Bucket AWS::S3::AccountPublicAccessBlock AWS::Redshift::Cluster AWS::Redshift::ClusterSnapshot AWS::Redshift::ClusterParameterGroup AWS::Redshift::ClusterSecurityGroup AWS::Redshift::ClusterSubnetGroup AWS::Redshift::EventSubscription AWS::SSM::ManagedInstanceInventory AWS::CloudWatch::Alarm AWS::CloudFormation::Stack AWS::ElasticLoadBalancing::LoadBalancer AWS::AutoScaling::AutoScalingGroup AWS::AutoScaling::LaunchConfiguration AWS::AutoScaling::ScalingPolicy AWS::AutoScaling::ScheduledAction AWS::DynamoDB::Table AWS::CodeBuild::Project AWS::WAF::RateBasedRule AWS::WAF::Rule AWS::WAF::RuleGroup AWS::WAF::WebACL AWS::WAFRegional::RateBasedRule AWS::WAFRegional::Rule AWS::WAFRegional::RuleGroup AWS::WAFRegional::WebACL AWS::CloudFront::Distribution AWS::CloudFront::StreamingDistribution AWS::Lambda::Function AWS::NetworkFirewall::Firewall AWS::NetworkFirewall::FirewallPolicy AWS::NetworkFirewall::RuleGroup AWS::ElasticBeanstalk::Application AWS::ElasticBeanstalk::ApplicationVersion AWS::ElasticBeanstalk::Environment AWS::WAFv2::WebACL AWS::WAFv2::RuleGroup AWS::WAFv2::IPSet AWS::WAFv2::RegexPatternSet AWS::WAFv2::ManagedRuleSet AWS::XRay::EncryptionConfig AWS::SSM::AssociationCompliance AWS::SSM::PatchCompliance AWS::Shield::Protection AWS::ShieldRegional::Protection AWS::Config::ConformancePackCompliance AWS::Config::ResourceCompliance AWS::ApiGateway::Stage AWS::ApiGateway::RestApi AWS::ApiGatewayV2::Stage AWS::ApiGatewayV2::Api AWS::CodePipeline::Pipeline AWS::ServiceCatalog::CloudFormationProvisionedProduct AWS::ServiceCatalog::CloudFormationProduct AWS::ServiceCatalog::Portfolio AWS::SQS::Queue AWS::KMS::Key AWS::QLDB::Ledger AWS::SecretsManager::Secret AWS::SNS::Topic AWS::SSM::FileData AWS::Backup::BackupPlan AWS::Backup::BackupSelection AWS::Backup::BackupVault AWS::Backup::RecoveryPoint AWS::ECR::Repository AWS::ECS::Cluster AWS::ECS::Service AWS::ECS::TaskDefinition AWS::EFS::AccessPoint AWS::EFS::FileSystem AWS::EKS::Cluster AWS::OpenSearch::Domain AWS::EC2::TransitGateway AWS::Kinesis::Stream AWS::Kinesis::StreamConsumer AWS::CodeDeploy::Application AWS::CodeDeploy::DeploymentConfig AWS::CodeDeploy::DeploymentGroup
do
  service=$(echo $element | cut -c6-30)
  format=$(echo "$service" | sed -r 's/[::]+/,/g')

  if [ -z "$region2" ]; then
    aws configservice list-discovered-resources --resource-type $element --region $region1 | grep '"resourceId"' | wc | awk '{ print "'$format'" "," $1 }' >> $FILE1
    else
    aws configservice list-discovered-resources --resource-type $element --region $region1 | grep '"resourceId"' | wc | awk '{ print "'$format'" "," $1 }' >> $FILE1
    aws configservice list-discovered-resources --resource-type $element --region $region2 | grep '"resourceId"' | wc | awk '{ print "'$format'" "," $1 }' >> $FILE2
  fi
done 

echo "Run Complete"