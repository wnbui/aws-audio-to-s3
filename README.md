# AWS Basic Serverless Application

This is an AWS serverless application that allows a user to record audio and automatically upload to an AWS S3 bucket.

- Next.js
- AWS S3, Lambda, API Gateway
- Terraform
---
### AWS Architecture
![AWS Architecture](assets/image/aws_architecture.png)
## How to run the app

### Clone the repository

```bash 
git clone https://github.com/your-repo/my-audio-app.git
cd my-audio-app
```

### Install dependencies & set up set up environmental variables

```bash
npm install
cp .env.example .env.local
```

### Edit <code>.env.local</code> and set the API Gateway URL:
Update the API Gateway URL with the API Gateway created from the Terraform deployment on AWS.
```bash
NEXT_PUBLIC_API_URL=https://your-api-gateway.amazonaws.com
```

### Install dependencies for lambda function and package lambda function for deployment

Make sure that the system has Python 3.8+ installed. Navigate to <code>/lambda</code> directory.

```bash
pip install -r requirements.txt
./package.sh
```

### Set Up AWS Infrastructure with Terraform

Make sure that you have the AWS CLI configured with your credentials for AWS. Refer to [AWS CLI documentation for guidance](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

Navigate to the <code>/terraform</code> folder.

```bash
cd terraform
```

Initialize, validate, plan, and apply Terraform.

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

<code>output.tf</code> is set to output the API Gateway URL. So update <code>NEXT_PUBLIC_API_URL=https://your-api-gateway.amazonaws.com</code> in <code>.env.local</code>with the output API Gateway URL.

Run the following command to grab the API Gateway URL.

```bash
terraform output api_gateway_url
```

### Next.js

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

### Test audio upload
1️⃣ Go to http://localhost:3000/upload.

2️⃣ Record audio and click "Stop".

3️⃣ Check the console for upload confirmation.

4️⃣ Verify the file in AWS S3:

- Go to AWS Console → S3.
- Open the bucket and check for the audio file.

### Destroy AWS infrastructure with Terraform

Delete the audio file from S3 bucket. Then destroy your AWS resources.
```bash
terraform destroy
```
Verify that the S3, Lambda function, and API Gateway have been destroyed.