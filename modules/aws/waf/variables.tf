variable "alb_attach" {
  type = string
}

variable "http_headers_val_to_block" {
  description = "keywords in a header for blocks"
  type        = list(string)
}

variable "ip_to_block" {
  type = list(string)
}

variable "country_codes_block" {
  type = list(string)
}

variable "ip_never_block" {
  type = list(string)
}

variable "acl_name" {
  type = string
}

variable "ip_rate_limit_for_string" {
  type = string
}

variable "ip_rate_limit_reqests_num" {
  type = string
}

variable "http_headers_name_to_block" {
  type = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "token_domains" {
  type        = list(any)
  description = "(Optional) Specifies the domains that AWS WAF should accept in a web request token. This enables the use of tokens across multiple protected websites. When AWS WAF provides a token, it uses the domain of the AWS resource that the web ACL is protecting. If you don't specify a list of token domains, AWS WAF accepts tokens only for the domain of the protected resource. With a token domain list, AWS WAF accepts the resource's host domain plus all domains in the token domain list, including their prefixed subdomains."
}