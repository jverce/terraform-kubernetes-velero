data aws_iam_policy_document assume_role {
  statement {
    sid = "serviceaccount"

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/${var.openid_connect_provider_uri}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.openid_connect_provider_uri}:sub"

      values = [
        "system:serviceaccount:${local.namespace}:velero-server",
      ]
    }
  }
}

data aws_iam_policy_document policy {
  statement {
    sid = "ec2"

    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
    ]

    resources = ["*", ]
  }
  statement {
    sid = "s3list"

    actions = [
      "s3:ListBucket",
    ]

    resources = ["arn:aws:s3:::${var.bucket}", ]
  }

  statement {
    sid = "s3backup"

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = ["arn:aws:s3:::${var.bucket}/velero/*", ]
  }
}

resource aws_iam_role this {
  count              = var.iam_deploy ? 1 : 0
  name               = var.iam_role_name == "" ? format("%s-%s", var.cluster_name, var.name) : var.iam_role_name

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = merge(var.tags,
    { Attached = var.name },
    { ServiceAccountName = var.name },
    { ServiceAccountNameSpace = local.namespace },
  )
}

resource aws_iam_role_policy this {
  count  = var.iam_deploy ? 1 : 0
  name   = format("%s-%s", var.cluster_name, var.name)
  role   = element(aws_iam_role.this.*.id, 0)
  policy = data.aws_iam_policy_document.policy.json
}
