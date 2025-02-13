# Real-Time Data Pipeline using Apache Kafka and AWS

[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com)
[![Kafka](https://img.shields.io/badge/Apache_Kafka-231F20?style=for-the-badge&logo=apache-kafka&logoColor=white)](https://kafka.apache.org/)

## Project Overview
This project demonstrates a robust, real‑time data pipeline that leverages multiple AWS services along with Apache Kafka. The pipeline captures change data from a SQL Server database using Change Data Capture (CDC), streams the data via an Amazon MSK (Managed Streaming for Apache Kafka) cluster, and finally sinks the data into an Amazon S3 bucket. An optional Amazon EC2 instance is provided to verify that data is published to Kafka.

This solution is well suited for applications that require real‑time data ingestion, transformation, and analytics in a secure, scalable, and fault‑tolerant environment.

**Key Features**:
- 🚀 Millisecond-latency event processing
- 🔒 IAM authentication & TLS encryption
- 📈 Horizontally scalable Kafka architecture
- 🔄 Automated CDC capture with Debezium

## Architecture
![System Architecture](https://github.com/Ashish1100/Real-Time-Data-Pipeline-using-Kafka-and-AWS/blob/8f9c784b505d51c21ecfe4f07dbb1cc559413318/Documents/Architecture.png)

**Data Flow**:
1. SQL Server CDC → 2. Debezium Source Connector → 3. Amazon MSK → 4. S3 Sink Connector → 5. Data Lake

**Core Components**:
- **RDS SQL Server**: CDC-enabled source database
- **Amazon MSK**: Managed Kafka cluster (3 brokers)
- **Debezium Connector**: Real-time change capture
- **S3 Connector**: Parquet writer with hourly partitioning
- **EC2**: Operational monitoring instance

## Prerequisites
- AWS Account with IAM permissions for:
  - RDS, MSK, S3, EC2, IAM
  - VPC/Networking configuration
- Local Environment:
  - AWS CLI v2+
  - SQL Server Management Studio
  - Java 11+
- Network:
  - VPC with private subnets
  - NAT Gateway
  - DNS resolution enabled
- Basic familiarity with SQL Server, Kafka, and AWS services.
- AWS CLI configured for your account.
- Access to Confluent Hub for obtaining connector plugins.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Steps to Setup & Deployment](#steps-to-setup--deployment)
  - [Step 1: Create RDS Database](#step-1-create-rds-database)
  - [Step 2: Create Database, Table, and Enable CDC](#step-2-create-database-table-and-enable-cdc)
  - [Step 3: Create S3 Bucket and Setup S3 VPC Endpoint](#step-3-create-s3-bucket-and-setup-s3-vpc-endpoint)
  - [Step 4: Create MSK Cluster](#step-4-create-msk-cluster)
  - [Step 5: Create IAM Role for MSK](#step-5-create-iam-role-for-msk)
  - [Step 6: Create Connector Plugins](#step-6-create-connector-plugins)
  - [Step 7: Create the Source Connector](#step-7-create-the-source-connector)
  - [Step 8: Create an EC2 Instance for Data Verification](#step-8-create-an-ec2-instance-for-data-verification-optional)
  - [Step 9: Verify Data in Kafka Topic](#step-9-verify-data-in-kafka-topic-optional)
  - [Step 10: Create S3 Sink Connector](#step-10-create-s3-sink-connector)
  - [Step 11: Verify Data in Target S3 Bucket](#step-11-verify-data-in-target-s3-bucket)
- [Troubleshooting](#troubleshooting)
- [Future Enhancements](#future-enhancements)
- [License](#license)

## Architecture
The overall solution involves the following components:
- **SQL Server RDS:** Acts as the primary data source where CDC is enabled to capture ongoing changes.
- **Amazon MSK Cluster:** Used to ingest the CDC events via Kafka. The cluster is provisioned with an IAM-based authentication model and appropriate security groups.
- **Connector Plugins:**
  - *Debezium Connector for SQL Server:* Captures CDC events from the RDS.
  - *Kafka‑S3‑Sink Connector:* Transmits data from the Kafka topic to the S3 bucket.
- **Amazon S3:** Serves as the destination storage for the processed data.
- **Amazon EC2 (Optional):** Deployed for verifying and viewing the data within the Kafka topic.

These components are integrated using secure network configurations, including VPC endpoints, security groups, and IAM roles, to ensure reliable and secure data movement through the pipeline.


## Steps to Setup & Deployment

### Step 1: Create RDS Database
- **Database Engine:** SQL Server Standard Edition.
- **Security Group:** Configure to allow TCP traffic on port 1433 from all sources (adjust for production environments).

### Step 2: Create Database, Table, and Enable CDC
Execute the provided `database/cdc_script.sql` which:
- Creates the required database and table.
- Enables CDC on the target table.
- Inserts initial data into the table.

### Step 3: Create S3 Bucket and Setup S3 VPC Endpoint
- **S3 Bucket:** Create a bucket to store the data.
- **VPC Endpoint:** Set up a VPC endpoint with type “Gateway” and service name `com.amazonaws.us-east-1.s3` (modify region if needed).

### Step 4: Create MSK Cluster
- **Cluster Type:** Provisioned.
- **Security Group:** Allow inbound/outbound traffic as needed (for simplicity, wide-open access is used, but consider restricting in production).
- **Authentication:** Use IAM for secure access.

### Step 5: Create IAM Role for MSK
Create an IAM role for MSK and attach the policy defined in `IAM/MSKConnectorRole.json` to grant the connector plugins permission to interact with S3 and other services.

### Step 6: Create Connector Plugins for SQL Server Source and S3 Sink
Download and configure:
1. **Debezium Connector for SQL Server** – Captures CDC events from SQL Server.
2. **Kafka‑S3‑Sink Connector** – Transfers data from Kafka topics into S3.

Refer to:
   - Debezium Connector for SQL Server: Available on Confluent Hub.
   - Kafka‑S3‑Sink Connector: Available on Confluent Hub.

### Step 7: Create the Source Connector
Follow step-by-step instructions provided in your repository or tutorial video to configure and launch this connector. It will pull CDC events from SQL Server RDS into a Kafka topic.

### Step 8: Create an EC2 Instance for Data Verification (Optional)
Launch an EC2 instance with an attached IAM role (`IAM/ecRole.json`) to install Kafka tools. This instance can be used to verify that data is being published correctly into Kafka topics.

### Step 9: Verify Data in Kafka Topic (Optional)
Install Kafka on your EC2 instance using instructions in `kafka/kafka_commands.txt`. Use console consumer commands to check messages in your Kafka topic.

### Step 10: Create S3 Sink Connector
Configure and deploy this connector as per instructions provided. It will pull data from Kafka topics into your designated S3 bucket.

### Step 11: Verify Data in Target S3 Bucket
Log into AWS S3 Console or use AWS CLI commands to confirm that files are being created in your bucket (`my-data-pipeline-bucket`) as expected.

## Troubleshooting
1. **RDS/SQL Server Issues:** Ensure correct security group rules (port `1433`) are applied. Verify that CDC scripts executed successfully.
2. **Connector Problems:** Check logs of source/sink connectors for errors. Ensure IAM permissions are configured correctly.
3. **MSK Cluster Issues:** Confirm proper VPC/subnet/security group configurations.
4. **Data Verification Failures:** Validate that EC2 has correct Kafka installations; recheck consumer commands.


## Contributing
1. Fork the repository
2. Create feature branch (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -am 'Add feature'`)
4. Push branch (`git push origin feature/improvement`)
5. Open Pull Request

## Future Enhancements
1. Add automated monitoring/alerting mechanisms like CloudWatch or Prometheus.
2. Introduce real-time transformations using tools like Kafka Streams or AWS Lambda.
3. Tighten security policies by restricting network access via security groups/IAM roles.
4. Implement dashboards for real-time analytics using tools like Grafana or Tableau.
