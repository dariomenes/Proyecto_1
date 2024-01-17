## Creamos el recurso bucket

resource "aws_s3_bucket" "bucket_testing" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = "bucket_proyecto_1"
    Environment = "Testing"
  }
}
# Creamos una Public ACL con Ownership, bloque de acceso publico y la ACL aplicada al dicho bucket
resource "aws_s3_bucket_ownership_controls" "public_acl_0" {
  bucket = aws_s3_bucket.bucket_testing.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_acl_1" {
  bucket = aws_s3_bucket.bucket_testing.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "public_acl_2" {
  depends_on = [
    aws_s3_bucket_ownership_controls.public_acl_0,
    aws_s3_bucket_public_access_block.public_acl_1,
  ]

  bucket = aws_s3_bucket.bucket_testing.id
  acl    = "public-read"
}


# Modulo de babenko para la carga de archivos en dicho bucket
module "template_files" {
  source = "hashicorp/dir/template"

  base_dir = "${path.module}/web"
}

# Configuracion de las diferentes paginas del sitio dentro del bucket
resource "aws_s3_bucket_website_configuration" "bucket_proyecto_1" {
  bucket = aws_s3_bucket.bucket_testing.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "about.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

# Policy del bucket para permitir el manejo de archivos
resource "aws_s3_bucket_policy" "hosting_bucket_policy" {
  bucket = aws_s3_bucket.bucket_testing.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}

resource "aws_s3_object" "hosting_bucket_files" {
  bucket = aws_s3_bucket.bucket_testing.id

  for_each = module.template_files.files

  key          = each.key
  content_type = each.value.content_type

  source  = each.value.source_path
  content = each.value.content

  etag = each.value.digests.md5

}