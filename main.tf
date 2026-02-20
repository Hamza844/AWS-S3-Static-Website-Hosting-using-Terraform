resource "aws_s3_bucket" "static_site" {
  bucket = var.bucket_name
}

# Disable block public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Bucket Policy (IMPORTANT)
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_site.id

  depends_on = [
    aws_s3_bucket_public_access_block.public_access
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = "*"
      Action = "s3:GetObject"
      Resource = "${aws_s3_bucket.static_site.arn}/*"
    }]
  })
}

# Upload index.html
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.static_site.id
  key    = "index.html"
  source = "website/index.html"
  content_type = "text/html"
  etag = filemd5("website/index.html")
}

# Upload error.html
resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.static_site.id
  key    = "error.html"
  source = "website/error.html"
  content_type = "text/html"
  etag = filemd5("website/error.html")
}

# Output website URL
output "website_url" {
  value = aws_s3_bucket_website_configuration.website_config.website_endpoint
}