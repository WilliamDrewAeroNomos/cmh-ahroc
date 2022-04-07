
resource "aws_s3_bucket" "terraform_state" {
  bucket = "dod-usarmy-tradoc-cmh-arhoc-terraform-state"
  # Enable versioning so we can see the full revision history of our
  # state files

  versioning {
    enabled = true
  }

  force_destroy = true

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

