# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/placement-groups.html

resource "aws_placement_group" "partition" {
  name            = var.placement_group_name
  strategy        = var.placement_group_strategy
  partition_count = var.placement_partition_count
  tags            = var.tags
}
