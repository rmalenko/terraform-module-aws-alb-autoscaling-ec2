
# output "intra_subnets" {
#   value = module.vpc.intra_subnets
# }

# output "private_subnets" {
#   value = module.vpc.private_subnets
# }

# output "public_subnets" {
#   value = module.vpc.public_subnets
# }

# output "vpc_id" {
#   value = module.vpc.vpc_id
# }

# output "random_pet" {
#   value = random_pet.this.id
# }

# output "security_group_id" {
#   value = module.security_group.security_group_id
# }

# output "zone_id_public" {
#   value = module.aws.route53_zone_zone_id_public
# }

# output "acm_certificate_arn" {
#   value = module.acm_certificates.acm_certificate_arn
# }

# output "route53_zone_zone_id_private" {
#   value = module.aws.route53_zone_zone_id_private
# }

# output "route53_ns" {
#   value = module.aws.route53_ns
# }

output "spot_price_current_max" {
  value = module.spot-price.spot_price_current_max
}

output "spot_price_current_max_mod" {
  value = module.spot-price.spot_price_current_max_mod
}

output "spot_price_current_min" {
  value = module.spot-price.spot_price_current_min
}

output "spot_price_current_min_mod" {
  value = module.spot-price.spot_price_current_min_mod
}

output "spot_price_current_optimal" {
  value = module.spot-price.spot_price_current_optimal
}

output "spot_price_current_optimal_mod" {
  value = module.spot-price.spot_price_current_optimal_mod
}


# output "test" {
#   value = module.secrets.example
# #   sensitive = true
# }

