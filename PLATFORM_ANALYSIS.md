# Platform Execution Analysis: AWS Batch

**Pipeline:** RNA-seq Differential Expression Analysis  
**Platform:** Amazon Web Services (AWS) Batch   
**Date:** February 2026

---

## Executive Summary

This document analyzes AWS Batch as the cloud execution platform for deploying the RNA-seq analysis pipeline developed for GeneXOmics. AWS Batch was selected for its native integration with Nextflow, cost-effectiveness through spot instances, automatic scaling capabilities, and widespread adoption in the genomics industry. The analysis covers setup requirements, execution strategies, platform advantages and limitations, and performance considerations specific to RNA-seq workloads.

---

## Table of Contents

1. [Platform Overview](#platform-overview)
2. [Setup Requirements](#setup-requirements)
3. [Execution Approach](#execution-approach)
4. [Advantages for GeneXOmics](#advantages-for-genexomics)
5. [Limitations and Challenges](#limitations-and-challenges)
6. [Performance Considerations](#performance-considerations)

---

## Platform Overview

### What is AWS Batch?

AWS Batch is a fully managed batch computing service that dynamically provisions optimal compute resources (EC2 and Spot instances) based on volume and resource requirements. For bioinformatics workloads, AWS Batch provides:

- **Dynamic resource allocation:** Automatically scales from 0 to thousands of vCPUs
- **Job scheduling:** Queues and executes jobs based on dependencies and priorities
- **Cost optimization:** Supports Spot instances (up to 90% cost savings)
- **Container support:** Native Docker integration for reproducible environments
- **Integration with AWS ecosystem:** S3 for storage, CloudWatch for monitoring, IAM for security

### Why AWS Batch for Genomics?

AWS Batch is particularly well-suited for genomics pipelines because:

1. **Variable workloads:** RNA-seq projects vary from pilot studies (4-6 samples) to large cohorts (100+ samples)
2. **Parallel processing:** Samples can be processed independently, enabling massive parallelization
3. **Resource heterogeneity:** Different pipeline stages require different resources (alignment vs. quantification)
4. **Spot instance compatibility:** Batch jobs are fault-tolerant and can leverage cheaper spot instances
5. **Nextflow native support:** Nextflow has built-in AWS Batch executor with optimized job submission

---

## Setup Requirements

### 1. AWS Account and IAM Configuration

**Required AWS Services:**
- AWS Batch (compute orchestration)
- Amazon EC2 (compute instances)
- Amazon S3 (data storage)
- Amazon ECR (container registry, optional)
- AWS CloudWatch (logging and monitoring)
- AWS IAM (access management)

**IAM Roles Required:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "batch:SubmitJob",
        "batch:DescribeJobs",
        "batch:TerminateJob",
        "batch:ListJobs",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
```

**Key Permissions:**
- **Batch permissions:** Submit and monitor jobs
- **S3 permissions:** Read input data, write results
- **ECR permissions:** Pull Docker containers
- **CloudWatch permissions:** Write execution logs

### 2. AWS Batch Environment Setup

**Compute Environment Configuration:**

```bash
# Create compute environment
aws batch create-compute-environment \
    --compute-environment-name genexomics-rnaseq-env \
    --type MANAGED \
    --state ENABLED \
    --compute-resources \
        type=SPOT,\
        minvCpus=0,\
        maxvCpus=256,\
        desiredvCpus=0,\
        instanceTypes=optimal,\
        subnets=subnet-xxxxx,\
        securityGroupIds=sg-xxxxx,\
        instanceRole=ecsInstanceRole,\
        bidPercentage=100,\
        spotIamFleetRole=arn:aws:iam::account:role/aws-ec2-spot-fleet-role
```

**Key Configuration Decisions:**

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Type | SPOT | Significant cost savings for fault-tolerant workloads |
| minvCpus | 0 | No idle compute costs when no jobs running |
| maxvCpus | 256 | Supports up to ~32 parallel samples (8 vCPUs each) |
| instanceTypes | optimal | AWS selects best instance type for job requirements |
| bidPercentage | 100 | Accept spot instances at on-demand price maximum |

**Job Queue Setup:**

```bash
# Create job queue with priority
aws batch create-job-queue \
    --job-queue-name genexomics-rnaseq-queue \
    --state ENABLED \
    --priority 100 \
    --compute-environment-order order=1,computeEnvironment=genexomics-rnaseq-env
```

### 3. S3 Bucket Configuration

**Storage Structure:**

```
s3://genexomics-rnaseq/
├── work/                    # Nextflow work directory (temporary)
├── data/
│   ├── fastq/              # Input FASTQ files
│   ├── reference/          # Reference genome/transcriptome
│   └── metadata/           # Sample metadata files
├── results/                # Pipeline outputs
│   ├── qc/
│   ├── counts/
│   └── differential_expression/
└── logs/                   # Execution logs
```

**S3 Lifecycle Policies:**

```json
{
  "Rules": [
    {
      "Id": "DeleteWorkDir",
      "Status": "Enabled",
      "Prefix": "work/",
      "Expiration": {
        "Days": 30
      },
      "Comment": "Delete temporary work files after 30 days"
    },
    {
      "Id": "TransitionResults",
      "Status": "Enabled",
      "Prefix": "results/",
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "Comment": "Archive old results to Glacier after 90 days"
    }
  ]
}
```

### 4. Nextflow Configuration for AWS Batch

**Updated `nextflow.config`:**

```groovy
profiles {
    awsbatch {
        process {
            executor = 'awsbatch'
            queue = 'genexomics-rnaseq-queue'
            
            // Process-specific resource allocation
            withName: 'FASTQC_.*' {
                cpus = 2
                memory = '4 GB'
                container = 'community.wave.seqera.io/library/fastqc:0.12.1--af7a5314d5015c29'
            }
            
            withName: 'TRIM_FASTP' {
                cpus = 4
                memory = '8 GB'
                container = 'community.wave.seqera.io/library/fastp:1.1.0--08aa7c5662a30d57'
            }
            
            withName: 'SALMON_INDEX' {
                cpus = 8
                memory = '32 GB'
                time = '4h'
                container = 'community.wave.seqera.io/library/salmon:1.10.3--fcd0755dd8abb423'
            }
            
            withName: 'SALMON_QUANT' {
                cpus = 8
                memory = '16 GB'
                time = '2h'
                container = 'community.wave.seqera.io/library/salmon:1.10.3--fcd0755dd8abb423'
            }
            
            withName: 'DESEQ2_ANALYSIS' {
                cpus = 4
                memory = '16 GB'
                container = 'bioconductor/bioconductor_docker:RELEASE_3_18'
            }
        }
        
        // AWS-specific settings
        workDir = 's3://genexomics-rnaseq/work'
        aws {
            region = 'us-east-1'
            batch {
                cliPath = '/home/ec2-user/miniconda/bin/aws'
                maxTransferAttempts = 3
                delayBetweenAttempts = '30 sec'
            }
        }
        
        // Enable CloudWatch logging
        trace {
            enabled = true
            file = 's3://genexomics-rnaseq/logs/trace.txt'
        }
        
        // S3 optimization
        aws.client {
            maxConnections = 20
            connectionTimeout = '10m'
            uploadMaxThreads = 4
            uploadChunkSize = '100 MB'
            uploadStorageClass = 'INTELLIGENT_TIERING'
            storageEncryption = 'AES256'
        }
    }
}
```

**Key Configuration Features:**
- **Per-process resource allocation:** Right-sized instances for each task
- **S3 work directory:** Centralized storage accessible from all compute nodes
- **Retry logic:** Handles transient spot instance interruptions
- **CloudWatch integration:** Centralized logging and monitoring
- **S3 optimization:** Parallel uploads, intelligent tiering, encryption

### 5. Container Registry Setup (Optional but Recommended)

**Using Amazon ECR for private containers:**

```bash
# Create ECR repository
aws ecr create-repository --repository-name genexomics/rnaseq-pipeline

# Build and push custom containers
docker build -t genexomics/custom-deseq2 .
docker tag genexomics/custom-deseq2:latest \
    123456789012.dkr.ecr.us-east-1.amazonaws.com/genexomics/rnaseq-pipeline:deseq2
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    123456789012.dkr.ecr.us-east-1.amazonaws.com
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/genexomics/rnaseq-pipeline:deseq2
```

**Benefits of ECR:**
- Reduced pull latency (same AWS region)
- Version control for custom containers
- Integration with IAM for access control
- Vulnerability scanning

---
## Execution Approach

### 1. Job Submission

Once the AWS Batch environment is configured, the pipeline is submitted 
directly from the command line using Nextflow's built-in AWS Batch executor:
```bash
nextflow run main.nf \
    -profile awsbatch \
    --input_mode local \
    --samplesheet_local s3://genexomics-rnaseq/data/metadata/samples.csv \
```

When executed, Nextflow:
1. Parses the pipeline DAG from `main.nf`
2. Submits each process as an individual job to AWS Batch
3. AWS Batch queues the jobs, provisions EC2 instances, pulls containers, 
   and executes tasks
4. Results are written directly to S3 as each task completes
5. EC2 instances are automatically terminated when jobs finish

If the pipeline is interrupted for any reason, `-resume` restarts from 
the last successfully completed step without re-running completed tasks.

### 2. Monitoring

**Real-time progress** is visible directly in the terminal via Nextflow:
```
executor >  awsbatch
[0d/6012cb] process > FASTQC_RAW (1)     [100%] 4 of 4 ✔
[b2/ae3d58] process > TRIM_FASTP (2)     [100%] 4 of 4 ✔
[aa/af7c92] process > SALMON_QUANT (1)   [ 50%] 2 of 4
[69/d5b2b5] process > GTF_DOWNLOAD       [100%] 1 of 1 ✔
```

**AWS Batch Console** provides deeper visibility into:
- Job states: SUBMITTED → PENDING → RUNNABLE → RUNNING → SUCCEEDED/FAILED
- Compute environment utilization (vCPUs in use, scaling activity)
- Job history and failure details

**Amazon CloudWatch** captures all logs from every job, enabling 
post-run investigation of any failures:

### 3. Error Handling

Nextflow is configured to automatically retry jobs that fail due to 
infrastructure issues (spot interruptions, transient network errors):
```groovy
process {
    errorStrategy = { task.exitStatus in [137, 143] ? 'retry' : 'terminate' }
    maxRetries = 3
}
```

Exit codes 137 and 143 indicate spot instance interruption. These jobs 
are automatically resubmitted without any manual intervention.

---

## Advantages for GeneXOmics

### 1. Cost Efficiency

**Spot Instance Savings:**

AWS Batch supports EC2 Spot Instances, which use spare AWS compute capacity 
at significantly reduced prices compared to On-Demand instances — typically 
60-80% cheaper. For bioinformatics workloads like RNA-seq, this is ideal 
because:

- Pipeline tasks are fault-tolerant (Nextflow automatically retries interrupted jobs)
- Most jobs complete before spot interruption occurs (~5-10% interruption rate)
- Even accounting for retries, total cost remains far below On-Demand pricing

**Pay-per-use Model:**

Unlike on-premises infrastructure, AWS Batch charges only for what you use:

- **No upfront costs:** No servers to purchase or maintain
- **No idle compute charges:** Compute environment scales to 0 vCPUs when 
  no jobs are running
- **Automatic scaling:** Resources provision on demand and terminate 
  immediately after job completion
- **Storage only when needed:** Only pay for S3 storage of results and 
  reference data

### 2. Scalability

AWS Batch automatically scales compute resources based on workload size. 
The pipeline processes all samples in parallel, meaning runtime stays 
nearly constant regardless of sample count — only the number of 
simultaneously running EC2 instances increases.

**Burst Capacity:**

For urgent analyses, AWS Batch can:
- Provision hundreds of instances in minutes
- Process 100+ samples in parallel
- Complete entire cohort analysis in ~2 hours (vs. days on local infrastructure)

**Use Case Example:**

*Scenario:* GeneXOmics receives urgent request for 200-sample cancer cohort analysis

Traditional HPC approach:
- Queue wait time: Variable, depends on cluster load and job priority
- Limited parallelization: constrained by available cores
- Shared infrastructure: competing with other users for resources

AWS Batch approach:
- Dedicated environment: no competition for resources
- Full parallelization: all samples processed simultaneously
- Linear vCPU scaling: 200 samples × 8 vCPUs = 1,600 vCPUs provisioned 
  automatically
- Result: runtime stays nearly constant regardless of sample count, 
  unlike HPC where runtime scales linearly with queue + compute time

### 3. Integration with AWS Ecosystem

**Seamless Data Flow:**

```
Data Ingestion:
S3 bucket (FASTQ uploads) 
    ↓
    Automatic SNS notification triggers Batch job
    ↓
AWS Batch (pipeline execution)
    ↓
    Results written to S3
    ↓
    SNS notification sent to analysis team
    ↓
QuickSight dashboard (automatic result visualization)
```

**AWS Services Synergy:**

| Service | Use in Pipeline | Benefit |
|---------|-----------------|---------|
| **S3** | Store FASTQ, reference, results | Unlimited storage, 99.999999999% durability |
| **CloudWatch** | Logs, metrics, alarms | Centralized monitoring, automated alerts |
| **SNS** | Pipeline completion notifications | Email/SMS alerts for job status |
| **Lambda** | Trigger pipelines on data upload | Automated, event-driven processing |
| **IAM** | Access control | Fine-grained security, audit trails |
| **Secrets Manager** | Store API keys, credentials | Secure credential management |
| **CloudTrail** | API audit logging | Compliance and security tracking |
| **Cost Explorer** | Track spending | Per-project cost allocation |


**Event-Driven Pipeline:**
1. Researcher uploads `samples.csv` to S3
2. S3 event triggers Lambda function
3. Lambda submits pipeline to AWS Batch
4. Pipeline executes automatically
5. Results appear in S3 output bucket
6. SNS sends completion notification

### 4. Reproducibility and Version Control

**Container-Based Execution:**

Every job runs in a Docker container with exact tool versions specified:
- Identical tool versions and dependencies across every run
- No environment inconsistencies between local and cloud execution
- Container versions are pinned in `nextflow.config`, ensuring 
  analyses are reproducible over time

**Nextflow Work Directory in S3:**
```
s3://genexomics-rnaseq/work/
└── 0d/6012cb.../
    ├── .command.sh       # Exact script executed
    ├── .command.log      # Complete stdout/stderr
    ├── .command.run      # Wrapper script
    └── .exitcode         # Exit status
```

Every task leaves a complete record in S3:
- The exact script that was executed
- Full stdout/stderr output
- Exit status
- Input and output file references

This enables full reproducibility: any historical task can be 
re-examined or re-run with identical inputs and environment.

**Pipeline Versioning:**
```bash
# Tag pipeline versions in Git
git tag -a v1.0.0 -m "Production release for GeneXOmics"
git push origin v1.0.0

# Run a specific pipeline version
nextflow run https://github.com/mcmonsalver/RNA-seq-LOKA-pipeline \
    -r v1.0.0 \
    -profile awsbatch
```

Git versioning ensures:
- Results are traceable to a specific pipeline version
- Historical analyses can be reproduced exactly
- Updates are controlled and documented

### 5. Security and Compliance

**Data Security:**

- **Encryption at rest:** S3 server-side encryption (AES-256 or KMS)
- **Encryption in transit:** TLS for all data transfers
- **Network isolation:** Batch compute runs in private VPC subnets 
  with no direct internet access
- **Private service access:** VPC endpoints for S3, ECR, and 
  CloudWatch keep all traffic within the AWS network

**Access Control:**

IAM policies define exactly what each service can do.

Key principles:
- Least-privilege access (each role has only the permissions it needs)
- MFA required for sensitive operations
- Separate roles for pipeline execution, data access, and administration

**Compliance:**

AWS Batch is eligible for several compliance frameworks:
- **HIPAA:** AWS offers a Business Associate Addendum (BAA)
- **GDPR:** Data residency controls keep data within chosen regions
- **SOC 2:** Compliance reports available through AWS Artifact

**Audit Logging:**

CloudTrail automatically records all API calls:
- Who submitted jobs and when
- What data was accessed
- Changes to Batch environments and compute resources

This provides a complete, tamper-evident audit trail for security 
investigations and regulatory compliance.

### 6. Fault Tolerance

**Nextflow Retry on Spot Interruption:**

When a spot instance is interrupted (exit codes 137 or 143), Nextflow 
automatically resubmits the job. Combined with `-resume`, only the 
interrupted task is restarted - all successfully completed tasks are 
reused from cache.

**Multi-AZ Deployment:**

Configuring the Batch compute environment across multiple Availability 
Zones increases spot instance availability, since AWS can fulfill 
requests from whichever zone has spare capacity at that moment.

---

## Limitations and Challenges

### 1. Spot Instance Interruptions

Spot instances can be reclaimed by AWS with 2-minute notice when capacity 
is needed elsewhere. This adds unpredictability to pipeline runtime.

---

### 2. Cold Start Latency

When the compute environment scales from zero, every pipeline run incurs 
a waiting period before execution actually begins. This delay is 
unavoidable and occurs on every run that starts from an idle environment.

---

### 3. Debugging Complexity

Distributed cloud execution is significantly harder to debug than local 
runs. Logs are spread across CloudWatch, jobs run on ephemeral instances 
that no longer exist after completion, and failures can originate at 
multiple layers simultaneously (Nextflow, Batch, Docker, or EC2).

---

### 4. Learning Curve

AWS Batch requires simultaneous familiarity with IAM, VPC, S3, 
CloudWatch, and Batch-specific concepts. This represents a real upfront 
investment in time and expertise, particularly for teams without prior 
AWS experience.

---

### 5. Cost Unpredictability

While AWS Batch is cost-efficient by design, costs can be difficult to 
predict in advance. Spot pricing fluctuates dynamically, and unexpected 
retries or misconfigured resource allocations can lead to higher-than-expected 
bills without proper monitoring in place.

---
## Performance Considerations

### Expected Execution Time

Exact execution times depend on instance type, read depth, and 
sample size, and should be benchmarked on real data. However, 
the pipeline's structure determines how time scales with sample count.

The critical path through the pipeline is:
```
TRIM_FASTP → SALMON_INDEX → SALMON_QUANT → MERGE_QUANT → DESEQ2
```

The two main time contributors are:
- **SALMON_INDEX:** runs once per pipeline execution (serial, 
  cannot be parallelized across samples)
- **SALMON_QUANT:** runs once per sample but all samples run 
  in parallel simultaneously

**Key implication:** adding more samples does not significantly 
increase total runtime, because SALMON_QUANT jobs for all samples 
run at the same time on separate EC2 instances. Runtime is 
dominated by the longest single task, not by sample count.

**Optimization:** Pre-building the Salmon index once and storing 
it in S3 eliminates the SALMON_INDEX step from every run:
```bash
params.salmon_index = 's3://genexomics-rnaseq/reference/salmon_index/'
```
---

### Scalability

AWS Batch scales horizontally by provisioning one EC2 instance 
per job. For this pipeline:

- Peak vCPU demand = number of samples × vCPUs allocated to 
  SALMON_QUANT (the most resource-intensive parallel step)
- AWS Batch provisions all instances simultaneously, so all 
  samples are quantified in parallel regardless of cohort size

This means the pipeline scales efficiently from a handful of 
samples to large cohorts without any changes to the pipeline code 
— only the number of EC2 instances provisioned changes.

The non-parallelizable steps (SALMON_INDEX, MERGE_QUANT, DESEQ2) 
represent a fixed time cost that does not grow with sample count, 
making AWS Batch increasingly advantageous as cohort size grows.

---

**Document Version:** 1.0  
**Last Updated:** February 2026  
