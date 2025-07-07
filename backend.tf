terraform {
  backend "s3" {
    bucket         = "awsanurag99-tfstate"
    key            = "terraform/state"
    region         = "eu-east-1"
    encrypt        = true
  }
}
