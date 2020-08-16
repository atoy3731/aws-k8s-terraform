variable "upload_directory" {
  default = "charts/"
}

resource "aws_s3_bucket_object" "website_files" {
  for_each      = fileset(var.upload_directory, "**/*.*")
  bucket        = var.key_s3_bucket_name
  key           = replace(each.value, var.upload_directory, "apps/")
  source        = "${var.upload_directory}${each.value}"
  acl           = "private"
  etag          = filemd5("${var.upload_directory}${each.value}")
}