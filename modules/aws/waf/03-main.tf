resource "aws_wafv2_regex_pattern_set" "http_headers" {
  name        = "HTTP_headers"
  description = "HTTP headers regex pattern set"
  scope       = "REGIONAL"
  tags        = var.tags

  dynamic "regular_expression" {
    for_each = var.http_headers_val_to_block
    content {
      regex_string = regular_expression.value
    }
  }
}

# resource "aws_wafv2_regex_pattern_set" "good_boot" {
#   name        = "Good_boots"
#   description = "Good Boots regex pattern set"
#   scope       = "REGIONAL"

#   regular_expression {
#     regex_string = "google"
#   }

#   tags = var.tags
# }

resource "aws_wafv2_ip_set" "toblock" {
  name               = "IP_set_to_block"
  description        = "Blocks IP set for block"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.ip_to_block
  tags               = merge(var.tags, { type = "block" }, )
}

resource "aws_wafv2_ip_set" "neverblock" {
  name               = "IP_set_allow"
  description        = "Blocks IP set which will never block"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.ip_never_block
  tags               = merge(var.tags, { type = "allow" }, )
}



resource "aws_wafv2_web_acl" "wordpress" {
  name        = var.acl_name
  description = "AWS managed rules set"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # rule {
  #   name     = "rule-1"
  #   priority = 1

  #   override_action {
  #     count {}
  #   }

  #   statement {
  #     managed_rule_group_statement {
  #       name        = "AWSManagedRulesCommonRuleSet"
  #       vendor_name = "AWS"

  #       rule_action_override {
  #         action_to_use {
  #           count {}
  #         }

  #         name = "SizeRestrictions_QUERYSTRING"
  #       }

  #       rule_action_override {
  #         action_to_use {
  #           count {}
  #         }

  #         name = "NoUserAgent_HEADER"
  #       }

  #       scope_down_statement {
  #         geo_match_statement {
  #           country_codes = ["US", "NL"]
  #         }
  #       }
  #     }
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = false
  #     metric_name                = "friendly-rule-metric-name"
  #     sampled_requests_enabled   = false
  #   }
  # }

  rule {
    name     = "Managed_Rules_WordPress_Rule_Set"
    priority = 2

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesWordPressRuleSet"
        vendor_name = "AWS"

      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "Managed-Rules-WordPress-Rule-Set-metric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "Managed_Rules_PHP_Rule_Set"
    priority = 3

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesPHPRuleSet"
        vendor_name = "AWS"

      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "Managed-Rules-PHP-Rule-Set-metric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "Managed_Rules_SQLi_Rule_Set"
    priority = 4

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"

      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "Managed-Rules-SQLi-Rule-Set-metric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "IP_Rate_Based_Rule"
    priority = 7
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = var.ip_rate_limit_reqests_num
        aggregate_key_type = "IP"
        scope_down_statement {
          and_statement {
            statement {
              byte_match_statement {
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "CONTAINS"
                search_string         = var.ip_rate_limit_for_string
                text_transformation {
                  priority = 1
                  type     = "LOWERCASE"
                }
              }
            }
            statement {
              not_statement {
                statement {

                  ip_set_reference_statement {
                    arn = aws_wafv2_ip_set.neverblock.arn
                  }
                }
              }
            }
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "IP-Rate-Based-Rule-metric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "IPs_and_HTTP_Header_Based_Rule"
    priority = 8

    action {
      block {}
    }

    statement {

      or_statement {
        statement {

          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.toblock.arn
          }
        }

        statement {

          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.http_headers.arn

            field_to_match {
              single_header {
                name = var.http_headers_name_to_block
              }
            }

            text_transformation {
              priority = 2
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "IPs-and-HTTP-Header-Based-Rule-metric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "Block_country"
    priority = 9

    action {
      block {}
    }

    statement {

      geo_match_statement {
        country_codes = var.country_codes_block
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "Block-country-name"
      sampled_requests_enabled   = false
    }
  }

  tags = var.tags

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "wp" {
  resource_arn = var.alb_attach
  web_acl_arn  = aws_wafv2_web_acl.wordpress.arn
}

