terraform {
  backend "s3" {
    bucket         = "awsanurag99-tfstate"
    key            = "terraform/state"
    region         = "us-east-1"
    encrypt        = true
  }
}
